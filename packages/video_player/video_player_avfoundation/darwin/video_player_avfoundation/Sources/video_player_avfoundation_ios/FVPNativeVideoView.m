// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "../video_player_avfoundation/include/video_player_avfoundation/FVPNativeVideoView.h"

#import <AVFoundation/AVFoundation.h>

#import "../video_player_avfoundation/include/video_player_avfoundation/FVPVideoPlayer.h"
#import "../video_player_avfoundation/include/video_player_avfoundation/FVPVideoPlayer_Internal.h"

/// How long to wait after entering the background for Picture in Picture to start before falling
/// back to detaching the player from the layer (so that audio keeps playing).
static const NSTimeInterval FVPPictureInPictureStartGracePeriod = 1.0;

@interface FVPPlayerView : UIView
@end

@implementation FVPPlayerView
+ (Class)layerClass {
  return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player {
  [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end

@interface FVPNativeVideoView ()
@property(nonatomic) FVPPlayerView *playerView;
@property(nonatomic, weak) AVPlayer *player;
@property(nonatomic, strong)
    AVPlayer *retainedPlayerForBackground;  // Temporarily retain during background
@property(nonatomic, strong) NSNumber *playerIdentifier;
@property(nonatomic, copy) FVPVideoPlayerProvider playerProvider;
@end

@implementation FVPNativeVideoView

- (instancetype)initWithPlayerIdentifier:(NSNumber *)playerIdentifier
                          playerProvider:(FVPVideoPlayerProvider)playerProvider {
  if (self = [super init]) {
    _playerIdentifier = playerIdentifier;
    _playerProvider = [playerProvider copy];
    _playerView = [[FVPPlayerView alloc] init];

    // Get the initial player from the provider
    FVPVideoPlayer *videoPlayer = playerProvider(playerIdentifier);
    _player = videoPlayer.player;
    [_playerView setPlayer:videoPlayer.player];
    // Hand the layer to the player so that it can drive Picture in Picture.
    videoPlayer.pictureInPictureLayer = self.playerLayer;

    [self registerLifecycleObservers];
    NSLog(@"[VideoPlayer] FVPNativeVideoView initialized with playerIdentifier: %@ and provider",
          playerIdentifier);
  }
  return self;
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
  if (self = [super init]) {
    _playerView = [[FVPPlayerView alloc] init];
    _player = player;
    [_playerView setPlayer:player];

    [self registerLifecycleObservers];
    NSLog(@"[VideoPlayer] FVPNativeVideoView initialized with lifecycle observers (legacy)");
  }
  return self;
}

- (void)registerLifecycleObservers {
  // Register for app lifecycle notifications
  // Use didEnterBackground instead of willResignActive to avoid detaching
  // when notification center or control center is opened
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidEnterBackground:)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(appDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AVPlayerLayer *)playerLayer {
  return (AVPlayerLayer *)[_playerView layer];
}

/// Returns the FVPVideoPlayer for this view's player identifier, if a provider is available.
- (nullable FVPVideoPlayer *)currentVideoPlayer {
  if (_playerProvider && _playerIdentifier) {
    return _playerProvider(_playerIdentifier);
  }
  return nil;
}

- (void)appDidEnterBackground:(NSNotification *)notification {
  // Detach player from layer when entering background
  // This prevents iOS from pausing the AVPlayer
  // Note: Using didEnterBackground instead of willResignActive so that
  // notification center / control center doesn't trigger this
  FVPVideoPlayer *videoPlayer = [self currentVideoPlayer];
  AVPlayer *currentPlayer = videoPlayer.player ?: _player;

  if (!currentPlayer || currentPlayer.rate <= 0) {
    return;
  }

  // Retain the player during background to prevent deallocation
  _retainedPlayerForBackground = currentPlayer;

  if (videoPlayer.keepsPlayerLayerAttachedInBackground) {
    // Picture in Picture is active, starting, or may start automatically: the system needs the
    // player to stay attached to the layer. If Picture in Picture does not actually start within
    // a short grace period, fall back to detaching so that audio keeps playing.
    NSLog(@"[VideoPlayer] FVPNativeVideoView: Keeping player attached for Picture in Picture");
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(FVPPictureInPictureStartGracePeriod * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     [weakSelf detachIfPictureInPictureDidNotStart];
                   });
    return;
  }

  [self.playerLayer setPlayer:nil];
  NSLog(@"[VideoPlayer] FVPNativeVideoView: Detached player from layer (didEnterBackground)");
}

- (void)detachIfPictureInPictureDidNotStart {
  if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
    return;
  }
  FVPVideoPlayer *videoPlayer = [self currentVideoPlayer];
  if (!videoPlayer || videoPlayer.disposed) {
    return;
  }
  if (videoPlayer.isPictureInPictureActive || videoPlayer.isPictureInPictureStarting) {
    return;
  }
  [self.playerLayer setPlayer:nil];
  NSLog(@"[VideoPlayer] FVPNativeVideoView: Picture in Picture did not start, detached player "
        @"from layer");
  // The system may have paused the player while it was attached; re-apply the playing state.
  if (videoPlayer.isPlaying) {
    [videoPlayer updatePlayingState];
  }
}

- (void)appDidBecomeActive:(NSNotification *)notification {
  // If we have a provider, always get the latest player from it
  // This handles the case where player was changed in background
  FVPVideoPlayer *videoPlayer = [self currentVideoPlayer];
  AVPlayer *playerToReattach = videoPlayer.player;
  if (videoPlayer) {
    NSLog(@"[VideoPlayer] FVPNativeVideoView: Got player from provider for id %@: %@",
          _playerIdentifier, playerToReattach ? @"exists" : @"nil");
  }

  // Fallback to retained/stored player if provider didn't return one
  if (!playerToReattach) {
    playerToReattach = _retainedPlayerForBackground ?: _player;
  }

  NSLog(@"[VideoPlayer] FVPNativeVideoView: didBecomeActive - playerToReattach: %@, rate: %f",
        playerToReattach ? @"exists" : @"nil", playerToReattach ? playerToReattach.rate : 0.0);

  if (playerToReattach) {
    // Update our reference to the latest player
    _player = playerToReattach;

    AVPlayerLayer *playerLayer = self.playerLayer;

    if (playerLayer.player != playerToReattach) {
      // Reattach player to layer
      [playerLayer setPlayer:playerToReattach];
      NSLog(@"[VideoPlayer] FVPNativeVideoView: Reattached player to layer (didBecomeActive)");

      // Force layer to redraw
      [playerLayer setNeedsDisplay];
      [_playerView setNeedsLayout];
      [_playerView layoutIfNeeded];
    }
    if (videoPlayer && videoPlayer.pictureInPictureLayer != playerLayer) {
      videoPlayer.pictureInPictureLayer = playerLayer;
    }
  } else {
    NSLog(@"[VideoPlayer] FVPNativeVideoView: WARNING - no player to reattach");
  }

  // Release the retained player
  _retainedPlayerForBackground = nil;
}

- (FVPPlayerView *)view {
  return self.playerView;
}

- (void)detachPlayerFromLayer {
  // Detach player from layer to allow background audio playback
  // iOS automatically pauses AVPlayer when video is being displayed in background
  [self.playerLayer setPlayer:nil];
  NSLog(@"[VideoPlayer] Detached player from layer for background playback");
}

- (void)reattachPlayerToLayer:(AVPlayer *)player {
  // Reattach player to layer when returning to foreground
  _player = player;
  [self.playerLayer setPlayer:player];
  NSLog(@"[VideoPlayer] Reattached player to layer");
}
@end

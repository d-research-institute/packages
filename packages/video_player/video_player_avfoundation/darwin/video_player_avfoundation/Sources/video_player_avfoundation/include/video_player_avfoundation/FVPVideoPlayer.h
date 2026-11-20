// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <AVFoundation/AVFoundation.h>

#import "./messages.g.h"
#import "FVPAVFactory.h"
#import "FVPVideoEventListener.h"
#import "FVPViewProvider.h"

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// FVPVideoPlayer manages video playback using AVPlayer.
/// It provides methods for controlling playback, adjusting volume, and handling seeking.
/// This class contains all functionalities needed to manage video playback in platform views and is
/// typically used alongside FVPNativeVideoViewFactory. If you need to display a video using a
/// texture, use FVPTextureBasedVideoPlayer instead.
@interface FVPVideoPlayer : NSObject <FVPVideoPlayerInstanceApi>
/// The AVPlayer instance used for video playback.
@property(nonatomic, readonly) AVPlayer *player;
/// Indicates whether the video player has been disposed.
@property(nonatomic, readonly) BOOL disposed;
/// Indicates whether the video player is set to loop.
@property(nonatomic) BOOL isLooping;
/// The current playback position of the video, in milliseconds.
@property(nonatomic, readonly) int64_t position;
/// The event listener to report video events to.
@property(nonatomic, nullable) NSObject<FVPVideoEventListener> *eventListener;
/// A block that will be called when dispose is called.
@property(nonatomic, nullable, copy) void (^onDisposed)(void);

/// Initializes a new instance of FVPVideoPlayer with the given AVPlayerItem, AV factory, and view
/// provider.
- (instancetype)initWithPlayerItem:(AVPlayerItem *)item
                         avFactory:(id<FVPAVFactory>)avFactory
                      viewProvider:(NSObject<FVPViewProvider> *)viewProvider;

/// Returns the AVPlayerItem corresponding to the given creation options.
+ (AVPlayerItem *)playerItemWithCreationOptions:(FVPCreationOptions *)options;

#if TARGET_OS_IOS
/// The AVPlayerLayer that currently displays this player's video. It is used to drive Picture in
/// Picture, and is set by FVPNativeVideoView when the platform view is created.
@property(nonatomic, weak, nullable) AVPlayerLayer *pictureInPictureLayer;
/// Whether Picture in Picture is currently active for this player.
@property(nonatomic, readonly) BOOL isPictureInPictureActive;
/// Whether a Picture in Picture start is in progress (requested or animating in).
@property(nonatomic, readonly) BOOL isPictureInPictureStarting;
/// Whether the player must stay attached to its AVPlayerLayer when the app enters the background.
///
/// This is YES while Picture in Picture is active or starting, and while automatic Picture in
/// Picture is enabled, since detaching the layer would prevent the system from presenting the
/// Picture in Picture window.
@property(nonatomic, readonly) BOOL keepsPlayerLayerAttachedInBackground;

/// Sets metadata for the Now Playing Info Center (lock screen / control center).
/// This enables remote control via Bluetooth/headset buttons.
- (void)setNowPlayingMetadataWithTitle:(nullable NSString *)title
                                artist:(nullable NSString *)artist
                                 album:(nullable NSString *)album
                            artworkUrl:(nullable NSString *)artworkUrl
                          isLiveStream:(BOOL)isLiveStream;

/// Clears the Now Playing Info Center and deactivates the audio session.
/// Call this when playback stops to allow other apps to resume control.
- (void)clearNowPlayingMetadata;
#endif

@end

NS_ASSUME_NONNULL_END

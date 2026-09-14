// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <AVFoundation/AVFoundation.h>
#import "FVPAVFactory.h"
#import "FVPVideoEventListener.h"
#import "FVPVideoPlayer.h"
#import "FVPViewProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Interface intended for use by subclasses, but not other callers.
@interface FVPVideoPlayer ()
/// The AVPlayerItemVideoOutput associated with this video player.
@property(nonatomic, readonly) AVPlayerItemVideoOutput *videoOutput;
/// The view provider, to obtain view information from.
@property(nonatomic, readonly, nullable) NSObject<FVPViewProvider> *viewProvider;
/// The preferred transform for the video. It can be used to handle the rotation of the video.
@property(nonatomic) CGAffineTransform preferredTransform;
/// The target playback speed requested by the plugin client.
@property(nonatomic, readonly) NSNumber *targetPlaybackSpeed;
/// Indicates whether the video player is currently playing.
@property(nonatomic, readonly) BOOL isPlaying;
/// Indicates whether an "initialized" message has been sent to the current Flutter event listener.
///
/// The video player sends an "initialized" message to the event listener when its underlying
/// AVPlayerItem is ready to play and the event listener is set to a non-nil value, whichever occurs
/// last.
///
/// This flag is set to YES when the "initialized" message is first sent, and is never set to NO
/// again.
@property(nonatomic, readonly) BOOL isInitialized;

/// Updates the playing state of the video player.
- (void)updatePlayingState;

/// Replaces the current AVPlayerItem with the given item, keeping the AVPlayer instance.
///
/// Observers and the video output are moved to the new item, and a "dataSourceReplaced" event is
/// reported once the new item is ready to play. Subclasses that override this must call super.
- (void)replacePlayerItem:(AVPlayerItem *)item;

#if TARGET_OS_IOS
/// Whether this player can enter Picture in Picture at all. The base implementation checks
/// AVPictureInPictureController support; subclasses that do not render via an on-screen
/// AVPlayerLayer should return NO.
- (BOOL)supportsPictureInPicture;
#endif
@end

NS_ASSUME_NONNULL_END

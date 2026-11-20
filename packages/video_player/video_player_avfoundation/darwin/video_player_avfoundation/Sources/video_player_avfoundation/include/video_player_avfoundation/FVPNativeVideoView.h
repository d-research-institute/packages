// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

@class FVPVideoPlayer;

/// A block type that provides the current FVPVideoPlayer for a given player identifier.
typedef FVPVideoPlayer *_Nullable (^FVPVideoPlayerProvider)(NSNumber *playerIdentifier);

/// A class used to create a native video view that can be embedded in a Flutter app.
/// This class wraps an AVPlayer instance and displays its video content.
#if TARGET_OS_IOS
@interface FVPNativeVideoView : NSObject <FlutterPlatformView>
#else
@interface FVPNativeVideoView : NSView
#endif
/// Initializes a new instance of a native view with a player identifier and provider.
/// The provider is used to get the latest player when returning from background, and to hand the
/// view's AVPlayerLayer to the player for Picture in Picture.
- (instancetype)initWithPlayerIdentifier:(NSNumber *)playerIdentifier
                          playerProvider:(FVPVideoPlayerProvider)playerProvider;

/// Initializes a new instance of a native view (legacy, for compatibility).
/// It creates a video view instance and sets the provided AVPlayer instance to it.
- (instancetype)initWithPlayer:(AVPlayer *)player;

#if TARGET_OS_IOS
/// The AVPlayerLayer that displays the video.
@property(nonatomic, readonly) AVPlayerLayer *playerLayer;

/// Detaches the player from the player layer.
/// This allows audio to continue playing in the background while the app is not rendering video.
- (void)detachPlayerFromLayer;

/// Reattaches the player to the player layer.
/// Call this when returning to the foreground to resume video rendering.
- (void)reattachPlayerToLayer:(AVPlayer *)player;
#endif
@end

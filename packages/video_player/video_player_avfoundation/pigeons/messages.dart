// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    objcHeaderOut:
        'darwin/video_player_avfoundation/Sources/video_player_avfoundation/include/video_player_avfoundation/messages.g.h',
    objcSourceOut:
        'darwin/video_player_avfoundation/Sources/video_player_avfoundation/messages.g.m',
    objcOptions: ObjcOptions(
      prefix: 'FVP',
      headerIncludePath: './include/video_player_avfoundation/messages.g.h',
    ),
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
/// Information passed to the platform view creation.
class PlatformVideoViewCreationParams {
  const PlatformVideoViewCreationParams({required this.playerId});

  final int playerId;
}

class CreationOptions {
  CreationOptions({required this.uri, required this.httpHeaders});

  String uri;
  Map<String, String> httpHeaders;
}

/// Metadata for Now Playing Info (lock screen / control center).
class NowPlayingMetadata {
  NowPlayingMetadata({
    this.title,
    this.artist,
    this.album,
    this.artworkUrl,
    this.isLiveStream = false,
  });

  String? title;
  String? artist;
  String? album;
  String? artworkUrl;
  bool isLiveStream;
}

class TexturePlayerIds {
  TexturePlayerIds({required this.playerId, required this.textureId});

  final int playerId;
  final int textureId;
}

@HostApi()
abstract class AVFoundationVideoPlayerApi {
  @ObjCSelector('initialize')
  void initialize();
  // Creates a new player using a platform view for rendering and returns its
  // ID.
  @ObjCSelector('createPlatformViewPlayerWithOptions:')
  int createForPlatformView(CreationOptions params);
  // Creates a new player using a texture for rendering and returns its IDs.
  @ObjCSelector('createTexturePlayerWithOptions:')
  TexturePlayerIds createForTextureView(CreationOptions creationOptions);
  @ObjCSelector('setMixWithOthers:')
  void setMixWithOthers(bool mixWithOthers);
  @ObjCSelector('fileURLForAssetWithName:package:')
  String? getAssetUrl(String asset, String? package);
}

@HostApi()
abstract class VideoPlayerInstanceApi {
  @ObjCSelector('setLooping:')
  void setLooping(bool looping);
  @ObjCSelector('setVolume:')
  void setVolume(double volume);
  @ObjCSelector('setPlaybackSpeed:')
  void setPlaybackSpeed(double speed);
  void play();
  @ObjCSelector('position')
  int getPosition();
  @async
  @ObjCSelector('seekTo:')
  void seekTo(int position);
  void pause();
  void dispose();
  /// Sets metadata for the Now Playing Info Center (lock screen / control center).
  /// Only available on iOS.
  @ObjCSelector('setNowPlayingMetadata:')
  void setNowPlayingMetadata(NowPlayingMetadata metadata);
  /// Clears the Now Playing Info Center and deactivates the audio session.
  /// Only available on iOS.
  // No @ObjCSelector: the generated selector must stay
  // `clearNowPlayingMetadataWithError:`, which FVPVideoPlayer implements.
  void clearNowPlayingMetadata();

  /// Returns whether Picture in Picture is supported for this player.
  /// Only players rendered with a platform view support it (iOS only).
  @ObjCSelector('isPictureInPictureSupported')
  bool isPictureInPictureSupported();

  /// Sets whether Picture in Picture should start automatically when the app
  /// moves to the background (iOS 14.2+).
  @ObjCSelector('setPictureInPictureAutoEnterEnabled:')
  void setPictureInPictureParams(bool autoEnterEnabled);

  /// Requests to start Picture in Picture. Returns whether the request was
  /// accepted.
  @ObjCSelector('startPictureInPicture')
  bool startPictureInPicture();

  /// Requests to stop Picture in Picture.
  @ObjCSelector('stopPictureInPicture')
  void stopPictureInPicture();

  /// Replaces the current media without recreating the AVPlayer, so that a
  /// Picture in Picture window and the remote command center stay attached.
  @ObjCSelector('replaceDataSourceWithOptions:')
  void replaceDataSource(CreationOptions options);
}

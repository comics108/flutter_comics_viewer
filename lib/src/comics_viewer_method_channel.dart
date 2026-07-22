import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'comics_viewer_platform_interface.dart';

/// An implementation of [ComicsViewerPlatform] that uses method channels.
class MethodChannelComicsViewer extends ComicsViewerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_comics_viewer');

  @override
  Future<void> loadComics(String filePath) async {
    await methodChannel.invokeMethod<void>('loadComics', {'filePath': filePath});
  }

  @override
  Future<void> play() async {
    await methodChannel.invokeMethod<void>('play');
  }

  @override
  Future<void> pause() async {
    await methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> setScrollPosition(double position) async {
    await methodChannel.invokeMethod<void>('setScrollPosition', {'position': position});
  }

  @override
  Future<double> getScrollPosition() async {
    final position = await methodChannel.invokeMethod<double>('getScrollPosition');
    return position ?? 0.0;
  }

  @override
  Future<void> setLanguageIndex(int index) async {
    await methodChannel.invokeMethod<void>('setLanguageIndex', {'index': index});
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    await methodChannel.invokeMethod<void>('setSoundEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setMuted(bool muted) async {
    await methodChannel.invokeMethod<void>('setMuted', {'muted': muted});
  }
}

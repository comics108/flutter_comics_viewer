import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'comics_viewer_method_channel.dart';

/// The interface that implementations of flutter_comics_viewer must implement.
abstract class ComicsViewerPlatform extends PlatformInterface {
  ComicsViewerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ComicsViewerPlatform _instance = MethodChannelComicsViewer();

  /// The default instance of [ComicsViewerPlatform] to use.
  static ComicsViewerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ComicsViewerPlatform] when they register themselves.
  static set instance(ComicsViewerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Load comics from a file path
  Future<void> loadComics(String filePath) {
    throw UnimplementedError('loadComics() has not been implemented.');
  }

  /// Start playing animations and sounds
  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  /// Pause animations and sounds
  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Set scroll position
  Future<void> setScrollPosition(double position) {
    throw UnimplementedError('setScrollPosition() has not been implemented.');
  }

  /// Get current scroll position
  Future<double> getScrollPosition() {
    throw UnimplementedError('getScrollPosition() has not been implemented.');
  }

  /// Set language index
  Future<void> setLanguageIndex(int index) {
    throw UnimplementedError('setLanguageIndex() has not been implemented.');
  }

  /// Enable or disable sound
  Future<void> setSoundEnabled(bool enabled) {
    throw UnimplementedError('setSoundEnabled() has not been implemented.');
  }

  /// Mute or unmute sound
  Future<void> setMuted(bool muted) {
    throw UnimplementedError('setMuted() has not been implemented.');
  }
}

import 'package:flutter/services.dart';
import 'comics_viewer_platform_interface.dart';

/// Controller for managing ComicsViewer state and interactions
class ComicsViewerController {
  final ComicsViewerPlatform _platform = ComicsViewerPlatform.instance;

  /// Callback for scroll position changes
  Function(double position)? onScrollChanged;

  /// Callback when comics are loaded
  Function()? onLoaded;

  /// Callback for errors
  Function(String error)? onError;

  /// Current language index
  int _languageIndex = 0;
  int get languageIndex => _languageIndex;

  /// Whether sound is enabled
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  /// Whether sound is muted
  bool _muted = false;
  bool get muted => _muted;

  /// Load comics from a file path
  Future<void> loadComics(String filePath) async {
    try {
      await _platform.loadComics(filePath);
      onLoaded?.call();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Start playing animations and sounds
  Future<void> play() async {
    try {
      await _platform.play();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Pause animations and sounds
  Future<void> pause() async {
    try {
      await _platform.pause();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Set scroll position (normalized 0.0 to 1.0)
  Future<void> setScrollPosition(double position) async {
    try {
      await _platform.setScrollPosition(position);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Get current scroll position
  Future<double> getScrollPosition() async {
    try {
      return await _platform.getScrollPosition();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Set language index (0-based)
  Future<void> setLanguageIndex(int index) async {
    try {
      _languageIndex = index;
      await _platform.setLanguageIndex(index);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Enable or disable sound playback
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      _soundEnabled = enabled;
      await _platform.setSoundEnabled(enabled);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Mute or unmute sound
  Future<void> setMuted(bool muted) async {
    try {
      _muted = muted;
      await _platform.setMuted(muted);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Toggle preview layers visibility
  Future<void> togglePreview(bool show) async {
    try {
      await _platform.togglePreview(show);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Toggle sound playback
  Future<void> toggleSounds(bool enabled) async {
    try {
      _soundEnabled = enabled;
      await _platform.toggleSounds(enabled);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Set language (0-based index)
  Future<void> setLanguage(int languageIndex) async {
    try {
      _languageIndex = languageIndex;
      await _platform.setLanguage(languageIndex);
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Check if currently playing
  Future<bool> get isPlaying async {
    try {
      return await _platform.isPlaying();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Get total scrollable height/duration
  Future<double> get duration async {
    try {
      return await _platform.getDuration();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Get current position
  Future<double> get currentPosition async {
    try {
      return await _platform.getCurrentPosition();
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}

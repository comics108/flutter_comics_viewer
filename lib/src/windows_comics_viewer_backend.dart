import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'comics_viewer_backend.dart';
import 'comics_viewer_source.dart';

/// Viewer-only bridge to the WPF child HWND hosted by Comics Editor on Windows.
final class WindowsComicsViewerBackend implements ComicsViewerBackend {
  WindowsComicsViewerBackend({MethodChannel? channel})
    : channel = channel ?? const MethodChannel('comics_editor');

  final MethodChannel channel;
  Timer? _positionPoll;
  void Function(double)? _onScrollChanged;
  void Function(bool)? _onPlayingChanged;
  void Function(String)? _onError;
  bool _disposed = false;

  Future<Map<String, dynamic>> invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final raw = await channel.invokeMethod<Object?>(method, arguments);
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) return const <String, dynamic>{};
    final result = decoded.cast<String, dynamic>();
    if (result['error'] != null) {
      throw PlatformException(
        code: result['error'].toString(),
        message: result['message']?.toString(),
      );
    }
    return result;
  }

  Future<void> create({
    required double x,
    required double y,
    required double width,
    required double height,
    required double devicePixelRatio,
  }) async {
    await invoke('create', {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'devicePixelRatio': devicePixelRatio,
    });
    _positionPoll ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      unawaited(_pollPosition());
    });
  }

  Future<void> setBounds({
    required double x,
    required double y,
    required double width,
    required double height,
    required double devicePixelRatio,
  }) => invoke('setBounds', {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'devicePixelRatio': devicePixelRatio,
  });

  Future<void> setVisible(bool visible) =>
      invoke('setVisible', {'visible': visible});

  Future<void> _pollPosition() async {
    if (_disposed) return;
    try {
      final result = await invoke('getPosition');
      final position = result['position'];
      if (position is num) _onScrollChanged?.call(position.toDouble());
    } catch (error) {
      _positionPoll?.cancel();
      _positionPoll = null;
      _onError?.call(error.toString());
    }
  }

  @override
  void setCallbacks({
    required void Function(double position) onScrollChanged,
    required void Function(bool playing) onPlayingChanged,
    required void Function(String message) onError,
  }) {
    _onScrollChanged = onScrollChanged;
    _onPlayingChanged = onPlayingChanged;
    _onError = onError;
  }

  @override
  Future<void> load(ComicsViewerSource source) async {
    if (source is! ComicsViewerPath) {
      throw UnsupportedError('The Windows WPF viewer requires a path source');
    }
    await invoke('load', {'path': source.path});
  }

  @override
  Future<void> play() async {
    await invoke('play');
    _onPlayingChanged?.call(true);
  }

  @override
  Future<void> pause() async {
    await invoke('pause');
    _onPlayingChanged?.call(false);
  }

  @override
  Future<void> setScrollPosition(double position) =>
      invoke('setPosition', {'position': position});

  @override
  Future<void> setLanguageIndex(int index) =>
      invoke('setLanguage', {'index': index});

  @override
  Future<void> setSoundEnabled(bool enabled) =>
      invoke('setSoundEnabled', {'enabled': enabled});

  @override
  Future<void> setMuted(bool muted) =>
      invoke('setSoundEnabled', {'enabled': !muted});

  @override
  Future<void> togglePreview(bool show) => invoke('setPreview', {'show': show});

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _positionPoll?.cancel();
    _positionPoll = null;
    await invoke('dispose');
  }
}

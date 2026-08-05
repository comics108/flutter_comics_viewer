import 'dart:async';

import 'package:flutter/services.dart';

import 'comics_viewer_source.dart';

typedef ComicsViewerBackendFactory = ComicsViewerBackend Function(int viewId);

/// One renderer instance. Backends must never share mutable command channels.
abstract interface class ComicsViewerBackend {
  void setCallbacks({
    required void Function(double position) onScrollChanged,
    required void Function(bool playing) onPlayingChanged,
    required void Function(String message) onError,
  });

  Future<void> load(ComicsViewerSource source);
  Future<void> play();
  Future<void> pause();
  Future<void> setScrollPosition(double position);
  Future<void> setLanguageIndex(int index);
  Future<void> setSoundEnabled(bool enabled);
  Future<void> setMuted(bool muted);
  Future<void> togglePreview(bool show);
  Future<void> dispose();
}

/// Android/iOS backend bound to the channel owned by a concrete PlatformView.
final class MethodChannelComicsViewerBackend implements ComicsViewerBackend {
  MethodChannelComicsViewerBackend(int viewId)
    : channel = MethodChannel('flutter_comics_viewer_$viewId');

  final MethodChannel channel;
  void Function(double)? _onScrollChanged;
  void Function(bool)? _onPlayingChanged;
  void Function(String)? _onError;
  final Map<int, Completer<void>> _pendingLoads = {};
  int _nextRequestId = 0;

  @override
  void setCallbacks({
    required void Function(double position) onScrollChanged,
    required void Function(bool playing) onPlayingChanged,
    required void Function(String message) onError,
  }) {
    _onScrollChanged = onScrollChanged;
    _onPlayingChanged = onPlayingChanged;
    _onError = onError;
    channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<Object?> _handleNativeCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case 'onScrollChanged':
        final value = args is Map ? args['position'] : args;
        if (value is num) _onScrollChanged?.call(value.toDouble());
      case 'onLoaded':
        final requestId = args is Map ? args['requestId'] : null;
        if (requestId is int) _pendingLoads.remove(requestId)?.complete();
      case 'onPlayingChanged':
        final value = args is Map ? args['playing'] : args;
        if (value is bool) _onPlayingChanged?.call(value);
      case 'onError':
        final value = args is Map ? args['error'] ?? args['message'] : args;
        final message = value?.toString() ?? 'Unknown viewer error';
        final requestId = args is Map ? args['requestId'] : null;
        if (requestId is int) {
          _pendingLoads.remove(requestId)?.completeError(StateError(message));
        }
        _onError?.call(message);
    }
    return null;
  }

  @override
  Future<void> load(ComicsViewerSource source) async {
    final requestId = _nextRequestId++;
    final completer = Completer<void>();
    _pendingLoads[requestId] = completer;
    try {
      await switch (source) {
        ComicsViewerPath(:final path) => channel.invokeMethod<void>(
          'loadComics',
          {'filePath': path, 'requestId': requestId},
        ),
        ComicsViewerBytes(:final bytes, :final revisionKey) =>
          channel.invokeMethod<void>('loadComicsBytes', {
            'bytes': bytes,
            'revisionKey': revisionKey.toString(),
            'requestId': requestId,
          }),
      };
      await completer.future;
    } catch (_) {
      _pendingLoads.remove(requestId);
      rethrow;
    }
  }

  @override
  Future<void> play() => channel.invokeMethod<void>('play');

  @override
  Future<void> pause() => channel.invokeMethod<void>('pause');

  @override
  Future<void> setScrollPosition(double position) =>
      channel.invokeMethod<void>('setScrollPosition', {'position': position});

  @override
  Future<void> setLanguageIndex(int index) =>
      channel.invokeMethod<void>('setLanguageIndex', {'index': index});

  @override
  Future<void> setSoundEnabled(bool enabled) =>
      channel.invokeMethod<void>('setSoundEnabled', {'enabled': enabled});

  @override
  Future<void> setMuted(bool muted) =>
      channel.invokeMethod<void>('setMuted', {'muted': muted});

  @override
  Future<void> togglePreview(bool show) =>
      channel.invokeMethod<void>('togglePreview', {'show': show});

  @override
  Future<void> dispose() async {
    channel.setMethodCallHandler(null);
    for (final pending in _pendingLoads.values) {
      pending.completeError(StateError('Viewer backend disposed'));
    }
    _pendingLoads.clear();
  }
}

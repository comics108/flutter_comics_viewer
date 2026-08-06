import 'dart:async';

import 'package:flutter/foundation.dart';

import 'comics_viewer_backend.dart';
import 'comics_viewer_source.dart';
import 'comics_viewer_state.dart';

/// State and commands for exactly one [ComicsViewer] renderer instance.
class ComicsViewerController extends ChangeNotifier {
  ComicsViewerController({ComicsViewerBackendFactory? backendFactory})
    : _backendFactory = backendFactory ?? MethodChannelComicsViewerBackend.new;

  static const double _echoTolerance = 1e-4;
  final ComicsViewerBackendFactory _backendFactory;
  ComicsViewerBackend? _backend;
  ComicsViewerState _state = const ComicsViewerState();
  ComicsViewerSource? _source;
  Object? _loadToken;
  double? _lastSentPosition;
  int _languageIndex = 0;
  bool _soundEnabled = true;
  bool _muted = false;
  bool _preview = false;
  bool _disposed = false;

  ComicsViewerState get state => _state;
  ComicsViewerSource? get source => _source;
  int get languageIndex => _languageIndex;
  bool get soundEnabled => _soundEnabled;
  bool get muted => _muted;
  bool get preview => _preview;
  bool get isAttached => _backend != null;

  /// The instance-owned renderer, exposed for a platform surface to reuse
  /// across temporary widget removal (for example Editor/Viewer switching).
  ComicsViewerBackend? get attachedBackend => _backend;

  /// Called once the concrete PlatformView/backend instance exists.
  Future<void> attachView(int viewId) async {
    if (_disposed) return;
    await attachBackend(_backendFactory(viewId));
  }

  /// Attaches an instance-owned non-PlatformView renderer.
  Future<void> attachBackend(ComicsViewerBackend backend) async {
    if (_disposed) return;
    await _backend?.dispose();
    _backend = backend;
    backend.setCallbacks(
      onScrollChanged: _handleBackendPosition,
      onPlayingChanged: (playing) =>
          _setState(_state.copyWith(playing: playing)),
      onError: _handleBackendError,
    );
    await backend.setLanguageIndex(_languageIndex);
    await backend.setSoundEnabled(_soundEnabled);
    await backend.setMuted(_muted);
    await backend.togglePreview(_preview);
    final pending = _source;
    if (pending != null) await _loadAttached(pending);
  }

  void markUnsupported([String? reason]) {
    _setState(
      ComicsViewerState(
        phase: ComicsViewerPhase.unsupported,
        position: _state.position,
        error: reason,
      ),
    );
  }

  Future<void> load(ComicsViewerSource source) async {
    _source = source;
    final token = Object();
    _loadToken = token;
    _setState(
      _state.copyWith(phase: ComicsViewerPhase.loading, clearError: true),
    );
    if (_backend == null) return;
    await _loadAttached(source, token: token);
  }

  Future<void> _loadAttached(ComicsViewerSource source, {Object? token}) async {
    final currentToken = token ?? Object();
    _loadToken = currentToken;
    try {
      await _backend!.load(source);
      if (_disposed || !identical(_loadToken, currentToken)) return;
      _setState(
        _state.copyWith(phase: ComicsViewerPhase.loaded, clearError: true),
      );
    } catch (error) {
      if (_disposed || !identical(_loadToken, currentToken)) return;
      _handleBackendError(error.toString());
    }
  }

  Future<void> play() async {
    await _requireBackend().play();
    _setState(_state.copyWith(playing: true));
  }

  Future<void> pause() async {
    await _requireBackend().pause();
    _setState(_state.copyWith(playing: false));
  }

  Future<void> setScrollPosition(double position) async {
    if (!position.isFinite) {
      throw ArgumentError.value(position, 'position', 'must be finite');
    }
    final normalized = position.clamp(0.0, 1.0);
    _lastSentPosition = normalized;
    _setState(_state.copyWith(position: normalized));
    await _requireBackend().setScrollPosition(normalized);
  }

  void _handleBackendPosition(double position) {
    if (!position.isFinite) return;
    final normalized = position.clamp(0.0, 1.0);
    final sent = _lastSentPosition;
    if (sent != null && (normalized - sent).abs() <= _echoTolerance) {
      _lastSentPosition = null;
      return;
    }
    _lastSentPosition = null;
    _setState(_state.copyWith(position: normalized));
  }

  Future<void> setLanguageIndex(int index) async {
    if (index < 0) throw ArgumentError.value(index, 'index');
    _languageIndex = index;
    if (_backend case final backend?) await backend.setLanguageIndex(index);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (_backend case final backend?) await backend.setSoundEnabled(enabled);
  }

  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (_backend case final backend?) await backend.setMuted(muted);
  }

  Future<void> togglePreview(bool show) async {
    _preview = show;
    if (_backend case final backend?) await backend.togglePreview(show);
  }

  ComicsViewerBackend _requireBackend() {
    final backend = _backend;
    if (backend == null) throw StateError('ComicsViewer is not attached');
    return backend;
  }

  void _handleBackendError(String message) {
    _setState(
      _state.copyWith(
        phase: ComicsViewerPhase.error,
        error: message,
        playing: false,
      ),
    );
  }

  void _setState(ComicsViewerState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadToken = null;
    unawaited(_backend?.dispose());
    _backend = null;
    super.dispose();
  }
}

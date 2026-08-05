import 'dart:typed_data';

/// Immutable input consumed by a [ComicsViewer] backend.
sealed class ComicsViewerSource {
  const ComicsViewerSource();

  /// Stable identity used to suppress stale asynchronous load completions.
  Object get revisionKey;
}

final class ComicsViewerPath extends ComicsViewerSource {
  // The public parameter name is part of the package API.
  const ComicsViewerPath(this.path, {Object? revisionKey})
    // ignore: prefer_initializing_formals
    : _revisionKey = revisionKey;

  final String path;
  final Object? _revisionKey;

  @override
  Object get revisionKey => _revisionKey ?? path;
}

final class ComicsViewerBytes extends ComicsViewerSource {
  const ComicsViewerBytes(this.bytes, {required this.revisionKey});

  final Uint8List bytes;

  @override
  final Object revisionKey;
}

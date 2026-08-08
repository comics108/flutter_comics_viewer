import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_comics/flutter_comics.dart';

import 'comics_viewer_backend.dart';
import 'comics_viewer_source.dart';
import 'source_bytes.dart';

/// flows/sdd-flutter-comics Plan Task 5.2: real tile pixel bytes for one
/// layer's image slot -- unlike `DartViewerAnim`/`DartViewerLayer` (deleted
/// below, since they duplicated the shared model's `Anim`/`EditorLayer`
/// and `KeyframeInterpolator`'s own math), tile bytes have no shared-model
/// equivalent at all (`EditorLayer.images` only ever holds a `file` path
/// string, never pixel data) -- this stays exactly as it was.
@immutable
class DartViewerTile {
  const DartViewerTile(this.bytes, this.left, this.top);
  final Uint8List bytes;
  final double left;
  final double top;
}

/// flows/sdd-flutter-comics Plan Task 5.2: one renderable layer -- real
/// tile bytes + box size (neither exists on the shared model, per
/// [DartViewerTile]'s own doc comment) plus a direct reference to the
/// shared [EditorLayer] itself, so the surface can call
/// [KeyframeInterpolator] directly on `editorLayer.anims` instead of a
/// second, duplicate interpolation implementation.
@immutable
class RenderedLayer {
  const RenderedLayer({
    required this.editorLayer,
    required this.width,
    required this.height,
    required this.tiles,
  });

  final EditorLayer editorLayer;
  final double width;
  final double height;
  final List<DartViewerTile> tiles;
}

@immutable
class DartComicsDocument {
  const DartComicsDocument({
    required this.width,
    required this.height,
    required this.layers,
  });
  final double width;
  final double height;
  final List<RenderedLayer> layers;
}

/// Archive renderer used by macOS/Linux and by Web for byte sources.
///
/// flows/sdd-flutter-comics Plan Task 5.2: `_rebuild` now sources every
/// layer's structure (images/anims/preview/kind/etc.) from a real, shared
/// [ComicsDoc] (via [ComicsArchiveReader.readBytes] -- the same portable
/// reader `apps/comics-editor` doesn't even need, since it goes through
/// the native core, but this package always lacked entirely) instead of
/// this file's own, now-deleted `DartViewerAnimType`/`DartViewerAnim`/
/// `DartViewerLayer`/`_parseAnimation` -- those silently dropped every
/// schema field added since this file was last touched (`solidColor`/
/// `mask`/`kind`/`style`/`parentId`/`groupId`/`scrollType`/
/// `preferredOrientation`/`preferredViewportWidth`/`Height`/`Anim.basis`),
/// the exact real drift this whole flow exists to fix. `EditorLayer`/
/// `LayerImage` don't carry per-image pixel `width`/`height` (a
/// pre-existing, disclosed gap in the shared model itself, not something
/// this flow's scope covers) -- retained via [_raw], the same lightweight
/// local JSON peek this file already needed for real ZIP/tile access, now
/// narrowed to just that one field.
final class DartComicsViewerBackend extends ChangeNotifier
    implements ComicsViewerBackend {
  void Function(double)? _onScrollChanged;
  void Function(bool)? _onPlayingChanged;
  void Function(String)? _onError;
  Archive? _archive;
  Map<String, dynamic>? _raw;
  ComicsDoc? _comicsDoc;
  Timer? _timer;
  int _languageIndex = 0;
  bool _showPreview = false;
  double _position = 0;
  bool _disposed = false;

  DartComicsDocument? document;
  double get position => _position;

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
    try {
      final bytes = switch (source) {
        ComicsViewerPath(:final path) => await readViewerPath(path),
        ComicsViewerBytes(:final bytes) => bytes,
      };
      final archive = ZipDecoder().decodeBytes(bytes);
      final data = archive.findFile('data.json');
      if (data == null) throw const FormatException('Archive has no data.json');
      final jsonBytes = _contentBytes(data);
      var text = utf8.decode(jsonBytes);
      if (text.startsWith('﻿')) text = text.substring(1);
      final raw = jsonDecode(text);
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('data.json must contain an object');
      }
      // The shared, schema-complete model -- real per-field parsing
      // (solidColor/mask/kind/groupId/textRegion/Anim.basis/etc.), not
      // this file's own deleted duplicate. Re-decodes [bytes] a second
      // time (ComicsArchiveReader has no "already-decoded" entry point,
      // and this package's Specifications didn't call for adding one) --
      // a one-time load, not a hot path, so the redundant unzip is a
      // deliberate, disclosed, low-risk simplicity trade-off.
      final comicsDoc = await ComicsArchiveReader.readBytes(bytes);
      _archive = archive;
      _raw = raw;
      _comicsDoc = comicsDoc;
      _rebuild();
    } catch (error) {
      _onError?.call(error.toString());
      rethrow;
    }
  }

  void _rebuild() {
    final archive = _archive!;
    final comicsDoc = _comicsDoc!;
    final rawLayersJson = (_raw!['layers'] as List? ?? const []);
    final layers = <RenderedLayer>[];
    for (var i = 0; i < comicsDoc.layers.length; i++) {
      final editorLayer = comicsDoc.layers[i];
      if (editorLayer.preview && !_showPreview) continue;

      final images = editorLayer.images;
      LayerImage? image = _languageIndex < images.length ? images[_languageIndex] : null;
      if (image == null || image.file.isEmpty) {
        image = images.isNotEmpty ? images.first : null;
      }
      final file = image?.file ?? '';
      if (file.isEmpty) continue;

      // EditorLayer/LayerImage carry no pixel width/height (disclosed gap,
      // see this class's own doc comment) -- read from the parallel raw
      // JSON layer at the same index (guaranteed to correspond 1:1: both
      // this list and ComicsArchiveReader's own iterate raw['layers'] in
      // original order, unfiltered).
      final rawLayer = i < rawLayersJson.length ? rawLayersJson[i] as Map : const {};
      final rawImages = rawLayer['images'] as List? ?? const [];
      Map<String, dynamic>? rawImage =
          _languageIndex < rawImages.length && rawImages[_languageIndex] is Map
              ? Map<String, dynamic>.from(rawImages[_languageIndex] as Map)
              : null;
      if (rawImage == null || (rawImage['file'] as String? ?? '').isEmpty) {
        if (rawImages.isNotEmpty && rawImages.first is Map) {
          rawImage = Map<String, dynamic>.from(rawImages.first as Map);
        }
      }
      final width = (rawImage?['width'] as num?)?.toDouble() ?? 0;
      final height = (rawImage?['height'] as num?)?.toDouble() ?? 0;

      final tiles = <DartViewerTile>[];
      if (file.contains('{0}') && width > 0 && height > 0) {
        final columns = (width / 512).ceil();
        final rows = (height / 512).ceil();
        for (var row = 0; row < rows; row++) {
          for (var column = 0; column < columns; column++) {
            final name = file
                .replaceFirst('{0}', '1000')
                .replaceFirst('{1}', '$column')
                .replaceFirst('{2}', '$row');
            final tile = archive.findFile('layers/$name');
            if (tile != null) {
              tiles.add(DartViewerTile(_contentBytes(tile), column * 512, row * 512));
            }
          }
        }
      } else {
        final entry = archive.findFile('layers/$file');
        if (entry != null) {
          tiles.add(DartViewerTile(_contentBytes(entry), 0, 0));
        }
      }
      if (tiles.isEmpty) continue;

      layers.add(RenderedLayer(editorLayer: editorLayer, width: width, height: height, tiles: tiles));
    }
    document = DartComicsDocument(
      width: comicsDoc.width.toDouble(),
      height: comicsDoc.height.toDouble(),
      layers: layers,
    );
    notifyListeners();
  }

  Uint8List _contentBytes(ArchiveFile file) => file.content;

  @override
  Future<void> play() async {
    if (_timer != null) return;
    _onPlayingChanged?.call(true);
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final next = (_position + .0025).clamp(0.0, 1.0);
      _position = next;
      _onScrollChanged?.call(next);
      notifyListeners();
      if (next >= 1) pause();
    });
  }

  @override
  Future<void> pause() async {
    _timer?.cancel();
    _timer = null;
    _onPlayingChanged?.call(false);
  }

  @override
  Future<void> setScrollPosition(double position) async {
    _position = position.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  Future<void> setLanguageIndex(int index) async {
    if (_languageIndex == index) return;
    _languageIndex = index;
    if (_archive != null) _rebuild();
  }

  @override
  Future<void> setSoundEnabled(bool enabled) async {}

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> togglePreview(bool show) async {
    if (_showPreview == show) return;
    _showPreview = show;
    if (_archive != null) _rebuild();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

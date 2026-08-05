import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'comics_viewer_backend.dart';
import 'comics_viewer_source.dart';
import 'source_bytes.dart';

enum DartViewerAnimType { translate, rotate, scale, alpha, sound }

@immutable
class DartViewerAnim {
  const DartViewerAnim({
    required this.type,
    required this.start,
    required this.end,
    this.x = 0,
    this.y = 0,
    this.angle = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.pivotX = .5,
    this.pivotY = .5,
    this.alpha = 1,
  });

  final DartViewerAnimType type;
  final double start;
  final double end;
  final double x;
  final double y;
  final double angle;
  final double scaleX;
  final double scaleY;
  final double pivotX;
  final double pivotY;
  final double alpha;
}

@immutable
class DartViewerTile {
  const DartViewerTile(this.bytes, this.left, this.top);
  final Uint8List bytes;
  final double left;
  final double top;
}

@immutable
class DartViewerLayer {
  const DartViewerLayer({
    required this.width,
    required this.height,
    required this.tiles,
    required this.animations,
    required this.preview,
  });

  final double width;
  final double height;
  final List<DartViewerTile> tiles;
  final List<DartViewerAnim> animations;
  final bool preview;

  ({double x, double y}) translateAt(double time) {
    final pair = _nearest(DartViewerAnimType.translate, time);
    if (pair.$1 == null && pair.$2 == null) return (x: 0, y: 0);
    final previous = pair.$1;
    final current = pair.$2;
    final px = previous?.x ?? 0;
    final py = previous?.y ?? 0;
    if (current == null) return (x: px, y: py);
    final factor = _factor(current, time);
    return (
      x: px + (current.x - px) * factor,
      y: py + (current.y - py) * factor,
    );
  }

  ({double x, double y, double pivotX, double pivotY}) scaleAt(double time) {
    final pair = _nearest(DartViewerAnimType.scale, time);
    final previous = pair.$1;
    final current = pair.$2;
    final px = previous?.scaleX ?? 1;
    final py = previous?.scaleY ?? 1;
    if (current == null) {
      return (
        x: px,
        y: py,
        pivotX: previous?.pivotX ?? .5,
        pivotY: previous?.pivotY ?? .5,
      );
    }
    final factor = _factor(current, time);
    return (
      x: px + (current.scaleX - px) * factor,
      y: py + (current.scaleY - py) * factor,
      pivotX: current.pivotX,
      pivotY: current.pivotY,
    );
  }

  ({double angle, double pivotX, double pivotY}) rotateAt(double time) {
    final pair = _nearest(DartViewerAnimType.rotate, time);
    final previous = pair.$1;
    final current = pair.$2;
    final angle = previous?.angle ?? 0;
    if (current == null) {
      return (
        angle: angle,
        pivotX: previous?.pivotX ?? .5,
        pivotY: previous?.pivotY ?? .5,
      );
    }
    return (
      angle: angle + (current.angle - angle) * _factor(current, time),
      pivotX: current.pivotX,
      pivotY: current.pivotY,
    );
  }

  double alphaAt(double time) {
    final pair = _nearest(DartViewerAnimType.alpha, time);
    final previous = pair.$1;
    final current = pair.$2;
    final alpha = previous?.alpha ?? 1;
    if (current == null) return alpha;
    return alpha + (current.alpha - alpha) * _factor(current, time);
  }

  (DartViewerAnim?, DartViewerAnim?) _nearest(
    DartViewerAnimType type,
    double time,
  ) {
    final values =
        <(int, DartViewerAnim)>[
          for (var i = 0; i < animations.length; i++)
            if (animations[i].type == type) (i, animations[i]),
        ]..sort((a, b) {
          final byStart = a.$2.start.compareTo(b.$2.start);
          return byStart == 0 ? a.$1.compareTo(b.$1) : byStart;
        });
    DartViewerAnim? previous;
    DartViewerAnim? current;
    for (final entry in values) {
      final animation = entry.$2;
      if (animation.end <= time) {
        previous = animation;
      } else {
        if (animation.start < time) current = animation;
        break;
      }
    }
    return (previous, current);
  }

  double _factor(DartViewerAnim animation, double time) {
    if (animation.end == animation.start) return 1;
    final t = (time - animation.start) / (animation.end - animation.start);
    return math.pow(t - 1, 3).toDouble() + 1;
  }
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
  final List<DartViewerLayer> layers;
}

/// Archive renderer used by macOS/Linux and by Web for byte sources.
final class DartComicsViewerBackend extends ChangeNotifier
    implements ComicsViewerBackend {
  void Function(double)? _onScrollChanged;
  void Function(bool)? _onPlayingChanged;
  void Function(String)? _onError;
  Archive? _archive;
  Map<String, dynamic>? _raw;
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
      if (text.startsWith('\ufeff')) text = text.substring(1);
      final raw = jsonDecode(text);
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('data.json must contain an object');
      }
      _archive = archive;
      _raw = raw;
      _rebuild();
    } catch (error) {
      _onError?.call(error.toString());
      rethrow;
    }
  }

  void _rebuild() {
    final archive = _archive!;
    final raw = _raw!;
    final layers = <DartViewerLayer>[];
    for (final value in (raw['layers'] as List? ?? const [])) {
      final layer = Map<String, dynamic>.from(value as Map);
      final preview = layer['preview'] == true;
      if (preview && !_showPreview) continue;
      final images = layer['images'] as List? ?? const [];
      Map<String, dynamic>? image;
      if (_languageIndex < images.length && images[_languageIndex] is Map) {
        image = Map<String, dynamic>.from(images[_languageIndex] as Map);
      }
      if (image == null || (image['file'] as String? ?? '').isEmpty) {
        if (images.isNotEmpty && images.first is Map) {
          image = Map<String, dynamic>.from(images.first as Map);
        }
      }
      final file = image?['file'] as String? ?? '';
      if (file.isEmpty) continue;
      final width = (image?['width'] as num?)?.toDouble() ?? 0;
      final height = (image?['height'] as num?)?.toDouble() ?? 0;
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
              tiles.add(
                DartViewerTile(_contentBytes(tile), column * 512, row * 512),
              );
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
      layers.add(
        DartViewerLayer(
          width: width,
          height: height,
          tiles: tiles,
          animations: [
            for (final animation in (layer['animations'] as List? ?? const []))
              _parseAnimation(Map<String, dynamic>.from(animation as Map)),
          ],
          preview: preview,
        ),
      );
    }
    document = DartComicsDocument(
      width: (raw['width'] as num?)?.toDouble() ?? 1080,
      height: (raw['height'] as num?)?.toDouble() ?? 1920,
      layers: layers,
    );
    notifyListeners();
  }

  DartViewerAnim _parseAnimation(Map<String, dynamic> raw) {
    final typeName = raw[r'$type']?.toString() ?? '';
    final type = typeName.contains('Rotate')
        ? DartViewerAnimType.rotate
        : typeName.contains('Scale')
        ? DartViewerAnimType.scale
        : typeName.contains('Alpha')
        ? DartViewerAnimType.alpha
        : typeName.contains('Sound')
        ? DartViewerAnimType.sound
        : DartViewerAnimType.translate;
    double number(String key, [double fallback = 0]) =>
        (raw[key] as num?)?.toDouble() ?? fallback;
    return DartViewerAnim(
      type: type,
      start: number('start'),
      end: number('end'),
      x: number('x'),
      y: number('y'),
      angle: number('angle'),
      scaleX: number('scaleX', 1),
      scaleY: number('scaleY', 1),
      pivotX: number('pivotX', .5),
      pivotY: number('pivotY', .5),
      alpha: number('alpha', 1),
    );
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

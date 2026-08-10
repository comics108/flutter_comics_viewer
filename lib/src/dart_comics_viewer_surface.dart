import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_comics/flutter_comics.dart';

import 'dart_comics_viewer_backend.dart';

class DartComicsViewerSurface extends StatelessWidget {
  const DartComicsViewerSurface({super.key, required this.backend});

  final DartComicsViewerBackend backend;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: backend,
      builder: (context, _) {
        final document = backend.document;
        if (document == null) return const SizedBox.expand();
        return ColoredBox(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / document.width;
              final contentHeight = document.height * scale;
              final viewportHeightDoc = constraints.maxHeight / scale;
              final scrollTravelDoc = math.max(
                0.0,
                document.height - viewportHeightDoc,
              );
              backend.updateDocumentScrollTravel(scrollTravelDoc);
              final documentScrollOffset = backend.documentScrollOffsetFor(
                backend.position,
              );
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(0, -documentScrollOffset * scale),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: contentHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final layer in document.layers)
                          _DartLayer(
                            layer: layer,
                            scale: scale,
                            documentScrollOffset: documentScrollOffset,
                            cameraPath: document.sourceDocument?.cameraPath,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DartLayer extends StatelessWidget {
  const _DartLayer({
    required this.layer,
    required this.scale,
    required this.documentScrollOffset,
    required this.cameraPath,
  });

  final RenderedLayer layer;
  final double scale;
  final double documentScrollOffset;
  final CameraPath? cameraPath;

  @override
  Widget build(BuildContext context) {
    // flows/sdd-flutter-comics Plan Task 5.3: real interpolation now comes
    // from the shared KeyframeInterpolator, operating directly on
    // layer.editorLayer.anims -- not this package's own second copy of
    // the same cubic-ease-out math (deleted alongside DartViewerLayer).
    final anims = layer.editorLayer.anims;
    final authoredTranslation = KeyframeInterpolator.translateAt(
      anims,
      documentScrollOffset,
      layer.editorLayer.translate,
    );
    final parallax = CameraPathEvaluator.parallaxAdjustment(
      cameraPath,
      documentScrollOffset,
      layer.editorLayer.zDepth,
    );
    final translation = authoredTranslation + parallax;
    final layerScale = KeyframeInterpolator.scaleAt(
      anims,
      documentScrollOffset,
    );
    final rotation = KeyframeInterpolator.rotateAt(anims, documentScrollOffset);
    final alpha = KeyframeInterpolator.alphaAt(
      anims,
      documentScrollOffset,
    ).clamp(0.0, 1.0);
    // Positional record access ($2/$3/etc.) rather than the named fields
    // KeyframeInterpolator declares (angle/pivotX/pivotY/scaleX/scaleY) --
    // the analyzer didn't resolve the named getters across this
    // package's `path:` dependency on `flutter_comics` (positional access
    // is equally type-safe and always resolves, per the record's own
    // declared shape).
    final pivotX = rotation.$2;
    final pivotY = rotation.$3;
    Widget image = SizedBox(
      width: layer.width * scale,
      height: layer.height * scale,
      child: Stack(
        children: [
          for (final tile in layer.tiles)
            Positioned(
              left: tile.left * scale,
              top: tile.top * scale,
              child: Image.memory(
                tile.bytes,
                scale: 1 / scale,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
        ],
      ),
    );
    image = Transform(
      alignment: Alignment(pivotX * 2 - 1, pivotY * 2 - 1),
      transform: Matrix4.identity()
        ..rotateZ(rotation.$1 * math.pi / 180)
        ..scaleByDouble(layerScale.$1, layerScale.$2, 1, 1),
      child: image,
    );
    return Positioned(
      left: translation.dx * scale,
      top: translation.dy * scale,
      child: Opacity(opacity: alpha, child: image),
    );
  }
}

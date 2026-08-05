import 'dart:math' as math;

import 'package:flutter/material.dart';

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
              final travel = math.max(
                0.0,
                contentHeight - constraints.maxHeight,
              );
              final time = backend.position * document.height;
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(0, -travel * backend.position),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: contentHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final layer in document.layers)
                          _DartLayer(layer: layer, scale: scale, time: time),
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
    required this.time,
  });

  final DartViewerLayer layer;
  final double scale;
  final double time;

  @override
  Widget build(BuildContext context) {
    final translation = layer.translateAt(time);
    final layerScale = layer.scaleAt(time);
    final rotation = layer.rotateAt(time);
    final alpha = layer.alphaAt(time).clamp(0.0, 1.0);
    final pivotX = rotation.pivotX;
    final pivotY = rotation.pivotY;
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
        ..rotateZ(rotation.angle * math.pi / 180)
        ..scaleByDouble(layerScale.x, layerScale.y, 1, 1),
      child: image,
    );
    return Positioned(
      left: translation.x * scale,
      top: translation.y * scale,
      child: Opacity(opacity: alpha, child: image),
    );
  }
}

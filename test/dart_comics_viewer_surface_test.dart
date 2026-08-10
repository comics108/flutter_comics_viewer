import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_comics/flutter_comics.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

const _transparentPixel = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

RenderedLayer _layer(double zDepth) {
  final editorLayer = EditorLayer('z=$zDepth', at: const Offset(10, 20))
    ..zDepth = zDepth;
  editorLayer.anims.single.x = 10;
  return RenderedLayer(
    editorLayer: editorLayer,
    width: 1,
    height: 1,
    tiles: [DartViewerTile(Uint8List.fromList(_transparentPixel), 0, 0)],
  );
}

List<Positioned> _layerPositions(WidgetTester tester) => tester
    .widgetList<Positioned>(find.byType(Positioned))
    .where((positioned) => positioned.child is Opacity)
    .toList();

Future<void> _pumpSurface(
  WidgetTester tester, {
  required DartComicsViewerBackend backend,
  required Size size,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: DartComicsViewerSurface(backend: backend),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('camera depth is applied once after authored translation', (
    tester,
  ) async {
    final source =
        ComicsDoc(
            name: 'camera',
            type: DocType.comics,
            width: 100,
            height: 1000,
          )
          ..cameraPath = CameraPath([
            CameraKeyframe(position: 0, x: 0, y: 0),
            CameraKeyframe(position: 800, x: 80, y: 40),
          ]);
    final backend = DartComicsViewerBackend()
      ..document = DartComicsDocument(
        width: 100,
        height: 1000,
        layers: [_layer(0), _layer(1), _layer(-0.5)],
        sourceDocument: source,
      );
    await backend.setScrollPosition(0.5);

    await _pumpSurface(tester, backend: backend, size: const Size(200, 400));

    expect(backend.documentScrollOffsetFor(backend.position), 400);
    final positions = _layerPositions(tester);
    expect(positions, hasLength(3));

    // At document offset 400, cubic ease-out samples camera (70, 35).
    // z=0: authored (10,20), no camera adjustment, then scale 2.
    expect(positions[0].left, closeTo(20, 1e-9));
    expect(positions[0].top, closeTo(40, 1e-9));
    // z=1: response .5 => adjustment (-35,-17.5), then scale 2.
    expect(positions[1].left, closeTo(-50, 1e-9));
    expect(positions[1].top, closeTo(5, 1e-9));
    // z=-.5: response 2 => adjustment (70,35), then scale 2.
    expect(positions[2].left, closeTo(160, 1e-9));
    expect(positions[2].top, closeTo(110, 1e-9));

    final strip = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(ClipRect),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(strip.transform.storage[13], closeTo(-800, 1e-9));
    await backend.dispose();
  });

  testWidgets(
    'same document viewport at another scale does not drift camera sampling',
    (tester) async {
      final source =
          ComicsDoc(
              name: 'resize',
              type: DocType.comics,
              width: 100,
              height: 1000,
            )
            ..cameraPath = CameraPath([
              CameraKeyframe(position: 0, x: 0, y: 0),
              CameraKeyframe(position: 800, x: 80, y: 40),
            ]);
      final backend = DartComicsViewerBackend()
        ..document = DartComicsDocument(
          width: 100,
          height: 1000,
          layers: [_layer(1)],
          sourceDocument: source,
        );
      await backend.setScrollPosition(0.5);

      await _pumpSurface(tester, backend: backend, size: const Size(200, 400));
      final atScale2 = _layerPositions(tester).single;
      expect(backend.documentScrollOffsetFor(backend.position), 400);

      await _pumpSurface(tester, backend: backend, size: const Size(300, 600));
      final atScale3 = _layerPositions(tester).single;
      expect(backend.documentScrollOffsetFor(backend.position), 400);
      expect(atScale3.left, closeTo(atScale2.left! * 1.5, 1e-9));
      expect(atScale3.top, closeTo(atScale2.top! * 1.5, 1e-9));
      await backend.dispose();
    },
  );

  testWidgets('short content and an inert path stay at the authored origin', (
    tester,
  ) async {
    final source = ComicsDoc(
      name: 'short',
      type: DocType.comics,
      width: 100,
      height: 100,
    )..cameraPath = CameraPath([CameraKeyframe(position: 0, x: 100, y: 100)]);
    final backend = DartComicsViewerBackend()
      ..document = DartComicsDocument(
        width: 100,
        height: 100,
        layers: [_layer(1)],
        sourceDocument: source,
      );
    await backend.setScrollPosition(1);

    await _pumpSurface(tester, backend: backend, size: const Size(200, 400));
    expect(backend.documentScrollOffsetFor(1), 0);
    final position = _layerPositions(tester).single;
    expect(position.left, 20);
    expect(position.top, 40);
    await backend.dispose();
  });
}

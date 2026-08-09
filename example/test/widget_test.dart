import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viewer_example/main.dart';

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

Uint8List _renderableArchive() {
  final data = utf8.encode(
    jsonEncode({
      'width': 720,
      'height': 1600,
      'layers': [
        {
          'images': [
            {'file': 'sample_{0}_{1}_{2}.png', 'width': 1, 'height': 1},
          ],
          'animations': [
            {
              r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
              'start': 0,
              'end': 0,
              'x': 20,
              'y': 40,
            },
          ],
        },
      ],
    }),
  );
  final archive = Archive()
    ..addFile(ArchiveFile('data.json', data.length, data))
    ..addFile(
      ArchiveFile(
        'layers/sample_1000_0_0.png',
        _transparentPixel.length,
        _transparentPixel,
      ),
    );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'macOS example renders a real comics archive through the Dart surface',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await tester.pumpWidget(
        MyApp(
          source: ComicsViewerBytes(
            _renderableArchive(),
            revisionKey: 'widget-test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(viewerKey), findsOneWidget);
      expect(find.byType(DartComicsViewerSurface), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('Rendered sample.comics'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('macOS controls update the rendered scroll position', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(
      MyApp(
        source: ComicsViewerBytes(
          _renderableArchive(),
          revisionKey: 'controls-test',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byKey(viewerPositionKey));
    slider.onChanged!(0.5);
    await tester.pump();

    expect(find.text('Rendered sample.comics — 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}

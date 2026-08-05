import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _archiveBytes(Map<String, Object?> data) {
  final json = utf8.encode(jsonEncode(data));
  final archive = Archive()
    ..addFile(ArchiveFile('data.json', json.length, json))
    ..addFile(ArchiveFile('layers/en_1000_0_0.png', 3, [1, 2, 3]))
    ..addFile(ArchiveFile('layers/ru_1000_0_0.png', 3, [4, 5, 6]));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  test(
    'parses tiled bytes, languages, preview filtering and dimensions',
    () async {
      final backend = DartComicsViewerBackend()
        ..setCallbacks(
          onScrollChanged: (_) {},
          onPlayingChanged: (_) {},
          onError: (_) {},
        );
      final bytes = _archiveBytes({
        'width': 1080,
        'height': 4000,
        'layers': [
          {
            'images': [
              {'file': 'en_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
              {'file': 'ru_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
            ],
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
                'y': 100,
              },
            ],
          },
          {
            'preview': true,
            'images': [
              {'file': 'en_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
            ],
          },
        ],
      });

      await backend.load(ComicsViewerBytes(bytes, revisionKey: 1));
      expect(backend.document!.width, 1080);
      expect(backend.document!.height, 4000);
      expect(backend.document!.layers, hasLength(1));
      expect(backend.document!.layers.single.tiles.single.bytes, [1, 2, 3]);

      await backend.setLanguageIndex(1);
      expect(backend.document!.layers.single.tiles.single.bytes, [4, 5, 6]);
      await backend.togglePreview(true);
      expect(backend.document!.layers, hasLength(2));
      await backend.dispose();
    },
  );

  test(
    'uses legacy cubic interpolation and clamps only transport position',
    () async {
      const layer = DartViewerLayer(
        width: 1,
        height: 1,
        tiles: [],
        preview: false,
        animations: [
          DartViewerAnim(
            type: DartViewerAnimType.translate,
            start: 0,
            end: 0,
            y: 100,
          ),
          DartViewerAnim(
            type: DartViewerAnimType.translate,
            start: 100,
            end: 200,
            x: 80,
            y: 200,
          ),
          DartViewerAnim(
            type: DartViewerAnimType.alpha,
            start: 0,
            end: 0,
            alpha: 1.4,
          ),
        ],
      );
      final value = layer.translateAt(150);
      expect(value.x, closeTo(70, 1e-9));
      expect(value.y, closeTo(187.5, 1e-9));
      expect(layer.alphaAt(500), 1.4);
    },
  );
}

// flows/sdd-flutter-comics Plan Task 5.4: rewritten (not moved -- this test
// exercises this package's own backend/surface wiring, a real
// flutter_comics_viewer concern, not a portable format concern that
// belongs in libs/flutter_comics) to assert against the full shared
// ComicsDoc/EditorLayer model instead of the deleted minimal
// DartViewerAnim/DartViewerLayer types, and extended to cover fields the
// old minimal parser silently dropped (solidColor/mask/kind/groupId/
// Anim.basis) -- the concrete, testable proof this flow fixed the real
// drift found during Requirements' analysis.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_comics/flutter_comics.dart';
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
    'a layer with solidColor/mask/kind/groupId/parentId/Anim.basis survives parsing '
    '-- the real fields the old minimal DartViewerAnim/DartViewerLayer parser silently '
    'dropped, confirmed fixed by this flow',
    () async {
      final backend = DartComicsViewerBackend()
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      final bytes = _archiveBytes({
        'width': 720,
        'height': 1600,
        'scrollType': 'horizontal',
        'preferredOrientation': 'landscape',
        'layers': [
          {
            'id': 'layer-1',
            'parentId': 'layer-0',
            'kind': 'balloon',
            'groupId': 'group-a',
            'solidColor': '#00ff00',
            'mask': {
              'shape': 'rect',
              'rect': {'x': 0.0, 'y': 0.0, 'w': 5.0, 'h': 5.0},
            },
            'images': [
              {'file': 'en_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
            ],
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
                'y': 50,
                'basis': 'time',
                'loop': false,
              },
            ],
          },
        ],
      });

      await backend.load(ComicsViewerBytes(bytes, revisionKey: 1));
      final editorLayer = backend.document!.layers.single.editorLayer;
      expect(editorLayer.id, 'layer-1');
      expect(editorLayer.parentId, 'layer-0');
      expect(editorLayer.kind, 'balloon');
      expect(editorLayer.groupId, 'group-a');
      expect(editorLayer.solidColor, '#00ff00');
      expect(editorLayer.mask!.shape, 'rect');
      expect(editorLayer.anims.single.basis, AnimBasis.time);
      expect(editorLayer.anims.single.loop, isFalse);
      await backend.dispose();
    },
  );

  test(
    'RenderedLayer.editorLayer.anims feeds the real shared KeyframeInterpolator directly '
    '-- no second, duplicate interpolation implementation',
    () async {
      final backend = DartComicsViewerBackend()
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      final bytes = _archiveBytes({
        'width': 1,
        'height': 1,
        'layers': [
          {
            'images': [
              {'file': 'en_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
            ],
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
                'start': 0,
                'end': 0,
                'y': 100,
              },
              {
                r'$type': 'Comics.Editor.Models.TranslateAnim, Comics.Editor',
                'start': 100,
                'end': 200,
                'x': 80,
                'y': 200,
              },
              {
                r'$type': 'Comics.Editor.Models.AlphaAnim, Comics.Editor',
                'start': 0,
                'end': 0,
                'alpha': 1.4,
              },
            ],
          },
        ],
      });

      await backend.load(ComicsViewerBytes(bytes, revisionKey: 1));
      final anims = backend.document!.layers.single.editorLayer.anims;
      final translation = KeyframeInterpolator.translateAt(anims, 150, Offset.zero);
      expect(translation.dx, closeTo(70, 1e-9));
      expect(translation.dy, closeTo(187.5, 1e-9));
      expect(KeyframeInterpolator.alphaAt(anims, 500), 1.4);
      await backend.dispose();
    },
  );
}

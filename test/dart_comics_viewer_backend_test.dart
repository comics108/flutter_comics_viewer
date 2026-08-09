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

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_comics/flutter_comics.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _archiveBytes(Map<String, Object?> data, {List<ArchiveFile>? extraFiles}) {
  final json = utf8.encode(jsonEncode(data));
  final archive = Archive()
    ..addFile(ArchiveFile('data.json', json.length, json))
    ..addFile(ArchiveFile('layers/en_1000_0_0.png', 3, [1, 2, 3]))
    ..addFile(ArchiveFile('layers/ru_1000_0_0.png', 3, [4, 5, 6]));
  for (final file in extraFiles ?? const <ArchiveFile>[]) {
    archive.addFile(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// flows/comics-viewer/sdd-flutter-comics-viewer-dart Plan Task 3.3: without
/// this, `SoundPlaybackTrack`'s underlying `AudioPlayer` construction throws
/// an uncaught `MissingPluginException` on the `xyz.luan/audioplayers.global`
/// channel (confirmed directly while building `sound_playback_test.dart`) --
/// unrelated to what these tests assert, but real and uncaught without a
/// mock. Real play/pause/etc. calls still won't complete without a per-player
/// EventChannel this mock doesn't provide either -- bounded by
/// `DartComicsViewerBackend.soundCallTimeout`, set short below, same
/// resolution as `sound_playback_test.dart`'s own.
void _mockAudioplayersChannel() {
  final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
    binding.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('sound playback (Plan Task 3)', () {
    setUp(_mockAudioplayersChannel);

    Uint8List soundArchive({required int start, required int end}) => _archiveBytes(
      {
        'width': 1,
        'height': 1000,
        'layers': [
          {
            'images': [
              {'file': 'en_{0}_{1}_{2}.png', 'width': 12, 'height': 10},
            ],
          },
        ],
        'sounds': [
          {
            'file': 'ambient.mp3',
            'animations': [
              {
                r'$type': 'Comics.Editor.Models.SoundAnim, Comics.Editor',
                'start': start,
                'end': end,
              },
            ],
          },
        ],
      },
      extraFiles: [ArchiveFile('sounds/ambient.mp3', 3, [9, 9, 9])],
    );

    test('one-shot sound (start == end) plays once when crossed downward', () async {
      final backend = DartComicsViewerBackend(soundCallTimeout: const Duration(milliseconds: 50))
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      await backend.load(ComicsViewerBytes(soundArchive(start: 300, end: 300), revisionKey: 1));
      final track = backend.soundTracksForTesting.values.single;
      expect(track.mimeType, 'audio/mpeg');

      // document.height == 1000, so time = position * 1000. Before the
      // point (position 0.1 -> time 100): not yet triggered.
      await backend.setScrollPosition(0.1);
      expect(track.isPlaying, isFalse);

      // Crossing downward through time 300 (position 0.1 -> 0.35): plays once.
      await backend.setScrollPosition(0.35);
      expect(track.isPlaying, isTrue);

      await backend.dispose();
    });

    test('one-shot sound does not replay when scrolled back up past it', () async {
      final backend = DartComicsViewerBackend(soundCallTimeout: const Duration(milliseconds: 50))
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      await backend.load(ComicsViewerBytes(soundArchive(start: 300, end: 300), revisionKey: 1));
      final track = backend.soundTracksForTesting.values.single;

      await backend.setScrollPosition(0.35); // crosses downward, plays once
      expect(track.isPlaying, isTrue);

      // SoundGating.decide's own already-tested rule: once playing,
      // "already playing" -> none, so isPlaying stays true (not re-triggered,
      // not stopped) as long as the position is still at/after the point.
      await backend.setScrollPosition(0.1); // scroll back up past the point
      // The real Anim (start==end==300) is no longer "in range" once
      // currentTime < start, so SoundGating.decide's currentlyPlaying=true
      // branch returns `stop` here -- confirms scrolling away stops a
      // one-shot sound rather than leaving it playing forever.
      expect(track.isPlaying, isFalse);

      await backend.dispose();
    });

    test('range sound starts looping on entry, stops on exit', () async {
      final backend = DartComicsViewerBackend(soundCallTimeout: const Duration(milliseconds: 50))
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      await backend.load(ComicsViewerBytes(soundArchive(start: 200, end: 400), revisionKey: 1));
      final track = backend.soundTracksForTesting.values.single;

      await backend.setScrollPosition(0.1); // time 100, before the range
      expect(track.isPlaying, isFalse);

      await backend.setScrollPosition(0.3); // time 300, inside [200, 400]
      expect(track.isPlaying, isTrue);

      await backend.setScrollPosition(0.5); // time 500, past the range
      expect(track.isPlaying, isFalse);

      await backend.dispose();
    });

    test('setSoundEnabled(false) mutes without losing isPlaying; re-enabling resumes', () async {
      final backend = DartComicsViewerBackend(soundCallTimeout: const Duration(milliseconds: 50))
        ..setCallbacks(onScrollChanged: (_) {}, onPlayingChanged: (_) {}, onError: (_) {});
      await backend.load(ComicsViewerBytes(soundArchive(start: 200, end: 400), revisionKey: 1));
      final track = backend.soundTracksForTesting.values.single;

      await backend.setScrollPosition(0.3); // inside the range, playing
      expect(track.isPlaying, isTrue);

      await backend.setSoundEnabled(false);
      expect(track.isPlaying, isTrue); // paused, not stopped

      await backend.setSoundEnabled(true);
      expect(track.isPlaying, isTrue); // resumed, not spuriously re-triggered

      await backend.dispose();
    });
  });
}

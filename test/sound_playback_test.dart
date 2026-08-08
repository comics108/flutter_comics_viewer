// flows/comics-viewer/sdd-flutter-comics-viewer-dart Plan Task 2.3.
//
// `audioplayers` has no real platform plugin under plain `flutter test` (no
// device/simulator). `_mockAudioplayersChannel()` stubs the method channels
// every AudioPlayer operation funnels through (`xyz.luan/audioplayers` and
// its `.global` init channel, confirmed directly in the installed
// `audioplayers_platform_interface` source) so `create`/`pause`/`resume`/
// `stop` resolve instantly instead of throwing uncaught. `play()` still
// can't complete without a real "prepared" event on a per-player
// EventChannel this mock doesn't provide (traced directly:
// AudioPlayer.preparationTimeout, 30s, is exactly the hang this test suite
// hit before `sound_playback.dart` gained its own much shorter
// `callTimeout` -- see that file's own doc comment) -- these tests pass a
// short override so that bounded, expected timeout doesn't slow the suite.
// SoundPlaybackTrack's own bookkeeping (`isPlaying`, set synchronously
// before each `await`) is what's actually under test here, not real audio
// output.
import 'package:flutter/services.dart';
import 'package:flutter_comics/flutter_comics.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void _mockAudioplayersChannel() {
  final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // The per-player channel every AudioPlayer operation funnels through, plus
  // the separate "global" channel AudioPlayer.global.ensureInitialized()
  // (called once per player creation) uses for its own `init` call -- both
  // confirmed directly in the installed audioplayers_platform_interface
  // source. Without mocking the second one too, the player constructor's
  // own internal init sequence throws uncaught (a real MissingPluginException,
  // not swallowed by this class's own `_guarded()`, since it's audioplayers'
  // own unguarded fire-and-forget constructor logic, not a call this class
  // makes directly).
  for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
    binding.setMockMethodCallHandler(MethodChannel(name), (call) async => null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_mockAudioplayersChannel);
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('playOnce marks the track playing, not looping', () async {
    final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
    expect(track.isPlaying, isFalse);
    await track.apply(SoundAction.playOnce);
    expect(track.isPlaying, isTrue);
    await track.dispose();
  });

  test('startLooping marks the track playing', () async {
    final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
    await track.apply(SoundAction.startLooping);
    expect(track.isPlaying, isTrue);
    await track.dispose();
  });

  test('stop clears isPlaying', () async {
    final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
    await track.apply(SoundAction.startLooping);
    expect(track.isPlaying, isTrue);
    await track.apply(SoundAction.stop);
    expect(track.isPlaying, isFalse);
    await track.dispose();
  });

  test('none is a no-op', () async {
    final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
    await track.apply(SoundAction.none);
    expect(track.isPlaying, isFalse);
    await track.dispose();
  });

  group('setMuted', () {
    test('muting a playing track keeps isPlaying true (pause, not stop)', () async {
      final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
      await track.apply(SoundAction.startLooping);
      await track.setMuted(true);
      expect(track.isPlaying, isTrue);
      await track.dispose();
    });

    test('muting a track that is not playing is a harmless no-op', () async {
      final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
      await track.setMuted(true);
      expect(track.isPlaying, isFalse);
      await track.dispose();
    });

    test('unmuting after a mute-while-playing does not clear isPlaying', () async {
      final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
      await track.apply(SoundAction.startLooping);
      await track.setMuted(true);
      await track.setMuted(false);
      expect(track.isPlaying, isTrue);
      await track.dispose();
    });

    test('stop after a mute-while-playing clears both playing and muted state', () async {
      final track = SoundPlaybackTrack(bytes, callTimeout: const Duration(milliseconds: 50));
      await track.apply(SoundAction.startLooping);
      await track.setMuted(true);
      await track.apply(SoundAction.stop);
      expect(track.isPlaying, isFalse);
      // A subsequent unmute must not spuriously resume a track SoundGating
      // already told to stop.
      await track.setMuted(false);
      expect(track.isPlaying, isFalse);
      await track.dispose();
    });
  });
}

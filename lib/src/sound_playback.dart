import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_comics/flutter_comics.dart';

/// Viewer-side counterpart to `apps/comics-editor`'s `SoundPlayer`
/// (`lib/src/ui/audio/sound_player.dart`), gated by the same shared
/// [SoundGating]. Plays via [BytesSource] instead of `DeviceFileSource` --
/// this package only ever has a sound file's raw bytes, read directly out of
/// the in-memory `.comics` ZIP archive (unlike the editor, which plays real
/// files the native core has already extracted to a temp folder).
///
/// flows/comics-viewer/sdd-flutter-comics-viewer-dart Plan Task 2.2.
class SoundPlaybackTrack {
  /// [callTimeout] bounds every real [AudioPlayer] operation -- a real,
  /// disclosed risk this class must guard against regardless of testing:
  /// `_evaluateSounds` (the caller) runs on every scroll-position change, so
  /// an unresponsive audio backend (a real possibility on any platform, not
  /// just a test artifact) must not stall that loop for platform-default
  /// timeouts as long as `AudioPlayer.preparationTimeout`'s 30 seconds.
  /// Defaults to a real, production-sensible bound; tests pass a much
  /// shorter one so a genuinely-unresponsive mock doesn't slow the suite.
  SoundPlaybackTrack(this.bytes, {this.callTimeout = const Duration(seconds: 5)}) {
    _player.onPlayerComplete.listen((_) {
      // Matches SoundPlayer's Player_MediaEnded handling: if scroll still
      // wants this looping, restart; otherwise settle into stopped. A
      // playOnce track's own single playthrough also lands here.
      if (_looping) {
        _player.resume();
      } else {
        _playing = false;
      }
    });
  }

  final Uint8List bytes;
  final Duration callTimeout;
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _looping = false;

  /// This class's own bookkeeping -- deliberately not re-derived from the
  /// real [AudioPlayer]'s state every tick, so [SoundGating.decide]'s
  /// `currentlyPlaying` input stays correct even while [setMuted] has
  /// paused real playback (see that method's own doc comment).
  bool get isPlaying => _playing;

  /// True while a currently-playing track is paused specifically because
  /// [setMuted]/mute made it so -- distinguishes "paused because muted,
  /// resume on unmute" from "stopped because SoundGating said stop".
  bool _mutedWhilePlaying = false;

  /// Per Specifications' Error Handling table: a real [AudioPlayer] call
  /// rejecting (missing codec, Web autoplay block, no platform plugin
  /// registered, etc.) must not propagate out and crash the caller's
  /// scroll-position evaluation loop over the *other* tracks -- this
  /// class's own bookkeeping (set synchronously, before the `await`) still
  /// reflects the intended state regardless of whether the underlying
  /// platform call actually succeeded.
  Future<void> apply(SoundAction action) async {
    switch (action) {
      case SoundAction.none:
        return;
      case SoundAction.playOnce:
        _playing = true;
        _looping = false;
        await _guarded(() => _player.play(BytesSource(bytes)));
      case SoundAction.startLooping:
        _playing = true;
        _looping = true;
        await _guarded(() async {
          await _player.setReleaseMode(ReleaseMode.loop);
          await _player.play(BytesSource(bytes));
        });
      case SoundAction.stop:
        _playing = false;
        _looping = false;
        _mutedWhilePlaying = false;
        await _guarded(_player.stop);
    }
  }

  /// Pauses (not stops) a currently-playing track without losing [isPlaying]
  /// -- matches Swift's per-player `isMuted` toggle (`ImageScrollView.swift`'s
  /// `playSound`), so unmuting resumes rather than spuriously re-triggering a
  /// one-shot sound that already played. Muting a track that isn't currently
  /// playing is a no-op (nothing to pause; [isPlaying] stays false, and the
  /// next real [SoundAction] from [SoundGating] still starts it normally).
  Future<void> setMuted(bool muted) async {
    if (muted) {
      if (_playing && !_mutedWhilePlaying) {
        _mutedWhilePlaying = true;
        await _guarded(_player.pause);
      }
    } else if (_mutedWhilePlaying) {
      _mutedWhilePlaying = false;
      await _guarded(_player.resume);
    }
  }

  Future<void> _guarded(Future<void> Function() call) async {
    try {
      await call().timeout(callTimeout);
    } catch (error) {
      debugPrint('SoundPlaybackTrack: playback call failed, ignoring: $error');
    }
  }

  Future<void> dispose() => _player.dispose();
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBackend implements ComicsViewerBackend {
  void Function(double)? onPosition;
  void Function(bool)? onPlaying;
  void Function(String)? onError;
  final List<ComicsViewerSource> loads = [];
  final List<double> positions = [];
  final Map<Object, Completer<void>> pendingLoads = {};
  int language = -1;
  bool sound = false;
  bool muted = false;
  bool preview = false;
  bool disposed = false;

  @override
  void setCallbacks({
    required void Function(double position) onScrollChanged,
    required void Function(bool playing) onPlayingChanged,
    required void Function(String message) onError,
  }) {
    onPosition = onScrollChanged;
    onPlaying = onPlayingChanged;
    this.onError = onError;
  }

  @override
  Future<void> load(ComicsViewerSource source) {
    loads.add(source);
    final pending = pendingLoads[source.revisionKey];
    return pending?.future ?? Future.value();
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> setScrollPosition(double position) async {
    positions.add(position);
  }

  @override
  Future<void> setLanguageIndex(int index) async => language = index;

  @override
  Future<void> setSoundEnabled(bool enabled) async => sound = enabled;

  @override
  Future<void> setMuted(bool muted) async => this.muted = muted;

  @override
  Future<void> togglePreview(bool show) async => preview = show;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  test('path and bytes sources retain stable revision identity', () {
    const path = ComicsViewerPath('/tmp/a.comics', revisionKey: 7);
    final bytes = ComicsViewerBytes(
      Uint8List.fromList([1, 2]),
      revisionKey: 'b',
    );

    expect(path.path, '/tmp/a.comics');
    expect(path.revisionKey, 7);
    expect(bytes.bytes, [1, 2]);
    expect(bytes.revisionKey, 'b');
  });

  test('two controllers command only their attached backend', () async {
    final backends = <int, FakeBackend>{};
    ComicsViewerBackend factory(int id) =>
        backends.putIfAbsent(id, FakeBackend.new);
    final first = ComicsViewerController(backendFactory: factory);
    final second = ComicsViewerController(backendFactory: factory);

    await first.attachView(11);
    await second.attachView(22);
    await first.setScrollPosition(.25);
    await second.setScrollPosition(.75);

    expect(backends[11]!.positions, [.25]);
    expect(backends[22]!.positions, [.75]);
    first.dispose();
    second.dispose();
  });

  test('load state ignores completion from a superseded revision', () async {
    final backend = FakeBackend();
    backend.pendingLoads['a'] = Completer<void>();
    backend.pendingLoads['b'] = Completer<void>();
    final controller = ComicsViewerController(backendFactory: (_) => backend);
    await controller.attachView(1);

    final first = controller.load(
      const ComicsViewerPath('/tmp/a.comics', revisionKey: 'a'),
    );
    final second = controller.load(
      const ComicsViewerPath('/tmp/b.comics', revisionKey: 'b'),
    );
    backend.pendingLoads['b']!.complete();
    await second;
    expect(controller.state.phase, ComicsViewerPhase.loaded);
    expect(controller.source!.revisionKey, 'b');

    backend.pendingLoads['a']!.complete();
    await first;
    expect(controller.state.phase, ComicsViewerPhase.loaded);
    expect(controller.source!.revisionKey, 'b');
    controller.dispose();
  });

  test('position clamps at transport and suppresses native echo', () async {
    final backend = FakeBackend();
    final controller = ComicsViewerController(backendFactory: (_) => backend);
    await controller.attachView(1);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setScrollPosition(2);
    expect(controller.state.position, 1);
    expect(backend.positions, [1]);
    final afterSend = notifications;
    backend.onPosition!(1.00001);
    expect(notifications, afterSend);

    backend.onPosition!(.4);
    expect(controller.state.position, .4);
    expect(notifications, afterSend + 1);
    controller.dispose();
  });

  test(
    'invalid position is rejected and backend errors are typed state',
    () async {
      final backend = FakeBackend();
      final controller = ComicsViewerController(backendFactory: (_) => backend);
      await controller.attachView(1);

      expect(
        () => controller.setScrollPosition(double.nan),
        throwsArgumentError,
      );
      backend.onError!('missing asset');
      expect(controller.state.phase, ComicsViewerPhase.error);
      expect(controller.state.error, 'missing asset');
      controller.dispose();
    },
  );

  test('settings queue before attach and dispose is idempotent', () async {
    final backend = FakeBackend();
    final controller = ComicsViewerController(backendFactory: (_) => backend);
    await controller.setLanguageIndex(4);
    await controller.setSoundEnabled(false);
    await controller.setMuted(true);
    await controller.togglePreview(true);
    await controller.load(const ComicsViewerPath('/tmp/a.comics'));

    await controller.attachView(1);
    expect(backend.language, 4);
    expect(backend.sound, isFalse);
    expect(backend.muted, isTrue);
    expect(backend.preview, isTrue);
    expect(backend.loads.single.revisionKey, '/tmp/a.comics');

    controller.dispose();
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(backend.disposed, isTrue);
  });
}

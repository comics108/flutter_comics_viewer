import 'package:flutter/services.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> sendNative(String channel, MethodCall call) {
    return messenger.handlePlatformMessage(
      channel,
      codec.encodeMethodCall(call),
      (_) {},
    );
  }

  test('two platform views use isolated channels and load callbacks', () async {
    final firstCalls = <MethodCall>[];
    final secondCalls = <MethodCall>[];
    const firstChannel = MethodChannel('flutter_comics_viewer_11');
    const secondChannel = MethodChannel('flutter_comics_viewer_22');
    messenger.setMockMethodCallHandler(firstChannel, (call) async {
      firstCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(secondChannel, (call) async {
      secondCalls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(firstChannel, null);
      messenger.setMockMethodCallHandler(secondChannel, null);
    });

    final first = MethodChannelComicsViewerBackend(11);
    final second = MethodChannelComicsViewerBackend(22);
    final firstPositions = <double>[];
    final secondPositions = <double>[];
    void attach(ComicsViewerBackend backend, List<double> positions) {
      backend.setCallbacks(
        onScrollChanged: positions.add,
        onPlayingChanged: (_) {},
        onError: (_) {},
      );
    }

    attach(first, firstPositions);
    attach(second, secondPositions);
    final firstLoad = first.load(const ComicsViewerPath('/tmp/first.comics'));
    final secondLoad = second.load(
      const ComicsViewerPath('/tmp/second.comics'),
    );
    await Future<void>.delayed(Duration.zero);

    final firstRequest =
        (firstCalls.single.arguments as Map<Object?, Object?>)['requestId'];
    final secondRequest =
        (secondCalls.single.arguments as Map<Object?, Object?>)['requestId'];
    await sendNative(
      'flutter_comics_viewer_22',
      MethodCall('onLoaded', {'requestId': secondRequest}),
    );
    await secondLoad;
    var firstCompleted = false;
    firstLoad.whenComplete(() => firstCompleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(firstCompleted, isFalse);

    await sendNative(
      'flutter_comics_viewer_11',
      MethodCall('onScrollChanged', {'position': .3}),
    );
    expect(firstPositions, [.3]);
    expect(secondPositions, isEmpty);
    await sendNative(
      'flutter_comics_viewer_11',
      MethodCall('onLoaded', {'requestId': firstRequest}),
    );
    await firstLoad;
    await first.dispose();
    await second.dispose();
  });

  test('settings use the native contract method names', () async {
    final methods = <String>[];
    const channel = MethodChannel('flutter_comics_viewer_7');
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final backend = MethodChannelComicsViewerBackend(7)
      ..setCallbacks(
        onScrollChanged: (_) {},
        onPlayingChanged: (_) {},
        onError: (_) {},
      );

    await backend.setLanguageIndex(2);
    await backend.setSoundEnabled(false);
    await backend.setMuted(true);
    await backend.togglePreview(true);

    expect(methods, [
      'setLanguageIndex',
      'setSoundEnabled',
      'setMuted',
      'togglePreview',
    ]);
    await backend.dispose();
  });

  test('Windows backend uses the viewer-only WPF host contract', () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('test_windows_viewer');
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'getPosition'
          ? '{"success":true,"position":0.25}'
          : '{"success":true}';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final backend = WindowsComicsViewerBackend(channel: channel)
      ..setCallbacks(
        onScrollChanged: (_) {},
        onPlayingChanged: (_) {},
        onError: (_) {},
      );

    await backend.create(
      x: 10,
      y: 20,
      width: 640,
      height: 480,
      devicePixelRatio: 1.5,
    );
    await backend.load(const ComicsViewerPath(r'C:\preview.comics'));
    await backend.setScrollPosition(.4);
    await backend.setLanguageIndex(2);
    await backend.setSoundEnabled(false);
    await backend.togglePreview(true);
    await backend.setVisible(false);
    await backend.dispose();

    expect(
      calls.map((call) => call.method),
      containsAllInOrder([
        'create',
        'load',
        'setPosition',
        'setLanguage',
        'setSoundEnabled',
        'setPreview',
        'setVisible',
        'dispose',
      ]),
    );
    expect(calls.first.arguments, containsPair('devicePixelRatio', 1.5));
  });
}

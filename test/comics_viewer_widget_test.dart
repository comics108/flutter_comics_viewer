import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('a source added after first build does not notify during build', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final data = utf8.encode('{"width":720,"height":1600,"layers":[]}');
    final archive = Archive()
      ..addFile(ArchiveFile('data.json', data.length, data));
    final source = ComicsViewerBytes(
      Uint8List.fromList(ZipEncoder().encode(archive)),
      revisionKey: 'delayed-source',
    );

    await tester.pumpWidget(
      MaterialApp(home: _DelayedSourceHost(source: source)),
    );
    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();

    expect(find.text(ComicsViewerPhase.loaded.name), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('unsupported backend is typed state without diagnostic text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final controller = ComicsViewerController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ComicsViewer(controller: controller)),
      ),
    );
    await tester.pump();

    expect(controller.state.phase, ComicsViewerPhase.unsupported);
    expect(find.textContaining('not supported'), findsNothing);
    controller.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Windows surface reuses its WPF host across workspace switches', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    const channel = MethodChannel('comics_editor');
    final methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          return call.method == 'getPosition'
              ? '{"success":true,"position":0.0}'
              : '{"success":true}';
        });
    final controller = ComicsViewerController();

    await tester.pumpWidget(
      MaterialApp(home: ComicsViewer(controller: controller)),
    );
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(methods, contains('setVisible'));
    expect(methods.where((method) => method == 'dispose'), isEmpty);

    await tester.pumpWidget(
      MaterialApp(home: ComicsViewer(controller: controller)),
    );
    await tester.pump();
    expect(methods.where((method) => method == 'create').length, 2);
    expect(methods.where((method) => method == 'dispose'), isEmpty);

    controller.dispose();
    await tester.pump();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _DelayedSourceHost extends StatefulWidget {
  const _DelayedSourceHost({required this.source});

  final ComicsViewerSource source;

  @override
  State<_DelayedSourceHost> createState() => _DelayedSourceHostState();
}

class _DelayedSourceHostState extends State<_DelayedSourceHost> {
  final controller = ComicsViewerController();
  ComicsViewerSource? source;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ComicsViewer(controller: controller, source: source),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Text(controller.state.phase.name),
        ),
        TextButton(
          onPressed: () => setState(() => source = widget.source),
          child: const Text('Load'),
        ),
      ],
    );
  }
}

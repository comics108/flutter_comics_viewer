import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
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

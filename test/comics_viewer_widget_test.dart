import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unsupported backend is typed state without diagnostic text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
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
}

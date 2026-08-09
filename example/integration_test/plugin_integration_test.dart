import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:viewer_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled sample.comics renders in the macOS example', (
    tester,
  ) async {
    expect(defaultTargetPlatform, TargetPlatform.macOS);
    app.main();

    await _pumpUntil(
      tester,
      () => find.textContaining('Rendered sample.comics').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 30),
    );

    expect(find.byKey(app.viewerKey), findsOneWidget);
    expect(find.byType(DartComicsViewerSurface), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.textContaining('Viewer error:'), findsNothing);

    final slider = tester.widget<Slider>(find.byKey(app.viewerPositionKey));
    slider.onChanged!(0.5);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Rendered sample.comics — 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for the real .comics archive to render.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

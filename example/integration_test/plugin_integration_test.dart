import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_comics_viewer/flutter_comics_viewer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:viewer_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'both bundled v2026 and v2012 archives render in the macOS example',
    (tester) async {
      expect(defaultTargetPlatform, TargetPlatform.macOS);
      app.main();

      await _pumpUntil(
        tester,
        () => find
            .textContaining('Rendered sample_v2026.comics')
            .evaluate()
            .isNotEmpty,
        timeout: const Duration(seconds: 30),
      );

      expect(find.byKey(app.viewerKey), findsOneWidget);
      expect(find.byType(DartComicsViewerSurface), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(find.textContaining('Viewer error:'), findsNothing);

      final slider = tester.widget<Slider>(find.byKey(app.viewerPositionKey));
      slider.onChanged!(0.5);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Rendered sample_v2026.comics — 50%'), findsOneWidget);

      await tester.tap(find.text('v2012'));
      await _pumpUntil(
        tester,
        () => find
            .text('Rendered sample_v2012.comics — 0%')
            .evaluate()
            .isNotEmpty,
        timeout: const Duration(seconds: 30),
      );
      expect(find.byType(Image), findsWidgets);
      expect(find.textContaining('Viewer error:'), findsNothing);

      final v2012Slider = tester.widget<Slider>(
        find.byKey(app.viewerPositionKey),
      );
      v2012Slider.onChanged!(0.5);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Rendered sample_v2012.comics — 50%'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Real fixture sounds can leave audioplayers' position updater active
      // until asynchronous backend disposal finishes. Pause the tracks and
      // explicitly drain disposal before the integration binding tears down.
      await tester.tap(find.byTooltip('Mute'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
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

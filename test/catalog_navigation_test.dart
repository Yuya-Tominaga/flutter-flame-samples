import 'package:flutter_flame_samples/app/app.dart';
import 'package:flutter_flame_samples/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('catalog navigates to the basic movement sample and back', (
    tester,
  ) async {
    final router = createRouter();
    await tester.pumpWidget(FlameSamplesApp(router: router));
    await tester.pump();

    expect(find.text('Flutter Flame Samples'), findsOneWidget);
    expect(find.text('Basic Movement'), findsOneWidget);

    await tester.tap(find.text('Basic Movement'));
    // FlameGame keeps producing frames, so pumpAndSettle never completes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Basic Movement'), findsWidgets);
    expect(find.textContaining('Move the circle'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to catalog'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Flutter Flame Samples'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
      home: const Scaffold(body: UpdateStatusDialog()),
    );
  }

  testWidgets('UpdateStatusDialog emoji suffix has tooltip and click cursor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final tooltipFinder = find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == 'Add status emoji',
    );
    expect(tooltipFinder, findsOneWidget);

    final clickRegionFinder = find.byWidgetPredicate(
      (widget) =>
          widget is MouseRegion && widget.cursor == SystemMouseCursors.click,
    );
    expect(clickRegionFinder, findsOneWidget);

    final iconFinder = find.descendant(
      of: clickRegionFinder,
      matching: find.byIcon(Icons.emoji_emotions_outlined),
    );
    expect(iconFinder, findsOneWidget);
  });
}

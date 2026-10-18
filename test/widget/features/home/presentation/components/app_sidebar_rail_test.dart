import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

Color _iconBackground(WidgetTester tester, IconData icon) {
  final iconContainer = find
      .ancestor(
        of: find.byIcon(icon),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container || widget.decoration is! BoxDecoration) {
            return false;
          }
          final decoration = widget.decoration! as BoxDecoration;
          return decoration.borderRadius == BorderRadius.circular(7);
        }),
      )
      .first;
  final decoration =
      tester.widget<Container>(iconContainer).decoration! as BoxDecoration;
  return decoration.color ?? Colors.transparent;
}

void main() {
  testWidgets(
    'rail icons highlight on hover without clearing the active icon',
    (tester) async {
      await tester.pumpWidget(
        buildTestMaterialApp(
          ProviderScope(
            child: const Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: AppSidebarRail.width,
                  height: 600,
                  child: AppSidebarRail(activeType: HomeSidebarType.home),
                ),
              ),
            ),
          ),
        ),
      );

      final activeColor = AppPalette.light.primary.withValues(alpha: 0.95);
      const railIcons = [
        Icons.home_filled,
        Icons.chat_bubble_outline,
        Icons.people_outline,
        Icons.folder_open_outlined,
        Icons.phone_outlined,
        Icons.notifications_none_outlined,
        Icons.settings_outlined,
      ];

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(200, 500));
      addTearDown(gesture.removePointer);
      await tester.pump();

      for (final icon in railIcons) {
        await gesture.moveTo(tester.getCenter(find.byIcon(icon)));
        await tester.pump();

        expect(_iconBackground(tester, icon), activeColor);

        await gesture.moveTo(const Offset(200, 500));
        await tester.pump();

        expect(
          _iconBackground(tester, icon),
          icon == Icons.home_filled ? activeColor : Colors.transparent,
        );
        expect(_iconBackground(tester, Icons.home_filled), activeColor);
      }
    },
  );
}

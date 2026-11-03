import 'package:flutter/rendering.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

Future<void> pumpSection(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: buildTestMaterialApp(
        Scaffold(
          body: SingleChildScrollView(
            child: NotificationsSection(
              preferences: NotificationPreferences.empty(),
              isSaving: false,
              onSave: (_) async {},
              onRevert: (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('NotificationsSection time pickers', () {
    testWidgets('show the whole selected time without overflowing', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(tester.takeException(), isNull);
      final pickers = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      final timePickers = pickers.where(
        (p) => p.icon is Icon && (p.icon! as Icon).icon == Icons.access_time,
      );
      expect(timePickers, isNotEmpty);
      for (final picker in timePickers) {
        expect(picker.isExpanded, isTrue);
      }

      // The default quiet hours are shown in full, not clipped or ellipsized.
      for (final time in ['12:00 AM', '11:00 PM']) {
        final paragraphs = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(DropdownButton<String>),
                matching: find.text(time),
              ),
            )
            .where((p) => p.hasSize);
        expect(paragraphs, isNotEmpty, reason: time);
        for (final paragraph in paragraphs) {
          expect(paragraph.didExceedMaxLines, isFalse, reason: time);
        }
      }
    });
  });
}

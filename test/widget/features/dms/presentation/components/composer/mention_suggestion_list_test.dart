import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/presentation/components/composer/composer.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

const _longEmail = 'engineering-lead-notifications@my-organization.internal';
const _longName = 'engineering_lead_notifications_bot_account_name';

Future<void> pumpList(
  WidgetTester tester,
  List<DmParticipant> people, {
  double width = 320,
}) async {
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Builder(
              builder: (context) => MentionSuggestionList(
                suggestions: people,
                query: '',
                colors: context.colors,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MentionSuggestionList', () {
    testWidgets('long username and email fit the row without overflowing', (
      tester,
    ) async {
      await pumpList(tester, [
        DmParticipant(userId: 'u-1', username: _longName, email: _longEmail),
      ]);

      expect(tester.takeException(), isNull);
      for (final value in [_longName, _longEmail]) {
        final text = tester.widget<Text>(find.text(value));
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('short names still render in full', (tester) async {
      await pumpList(tester, [
        DmParticipant(userId: 'u-2', username: 'ada', email: 'ada@zedu.test'),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.text('ada'), findsOneWidget);
      expect(find.text('ada@zedu.test'), findsOneWidget);
    });
  });
}

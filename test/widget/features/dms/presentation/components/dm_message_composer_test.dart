import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  testWidgets(
    'DM message input has a max line limit so long drafts scroll instead of growing',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DmMessageComposer(
                recipientName: 'Ada',
                channelId: 'ch-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            widget.decoration is InputDecoration &&
            (widget.decoration as InputDecoration).hintText ==
                'Message Ada'),
      );

      expect(textField.maxLines, 6);
    },
  );
}

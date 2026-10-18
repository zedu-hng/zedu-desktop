import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  group('DmProfileCard', () {
    testWidgets('shows participant profile and closes the dialog', (
      tester,
    ) async {
      const name = 'Alex Morgan';
      const email = 'alex@example.com';
      final conversation = _conversation(username: name, email: email);

      await tester.pumpWidget(_buildProfileCard(conversation));
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text(name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text(email)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('A')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Close')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('hides participant email when it is null', (tester) async {
      final conversation = _conversation(username: 'Alex Morgan');

      await tester.pumpWidget(_buildProfileCard(conversation));
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.byType(SelectableText)),
        findsNothing,
      );
    });

    testWidgets('shows Unknown and U when username is empty', (tester) async {
      final conversation = _conversation(username: '', email: null);

      await tester.pumpWidget(_buildProfileCard(conversation));
      await tester.tap(find.text('View Profile'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Unknown')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('U')),
        findsOneWidget,
      );
    });
  });
}

DmConversation _conversation({required String username, String? email}) {
  return DmConversation(
    channelId: 'channel-1',
    username: username,
    participantId: 'participant-1',
    participantEmail: email,
    previewMessage: '',
    unreadCount: 0,
  );
}

Widget _buildProfileCard(DmConversation conversation) {
  return buildTestMaterialApp(
    Scaffold(
      body: SingleChildScrollView(
        child: DmProfileCard(conversation: conversation),
      ),
    ),
  );
}

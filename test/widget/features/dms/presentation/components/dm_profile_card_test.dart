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

  group('DmProfileCard compact layout', () {
    final introText = find.textContaining(
      'This conversation is just between you and',
      findRichText: true,
    );
    final viewProfile = find.widgetWithText(OutlinedButton, 'View Profile');

    Future<void> pumpCard(WidgetTester tester, {required double width}) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: DmProfileCard(
                conversation: _conversation(username: 'Ada Lovelace'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows avatar, name, intro text and View Profile', (
      tester,
    ) async {
      await pumpCard(tester, width: 1000);

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(tester.getSize(find.byType(CircleAvatar)), const Size(40, 40));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(
        find.textContaining('@Ada_Lovelace', findRichText: true),
        findsOneWidget,
      );
      expect(viewProfile, findsOneWidget);
      expect(tester.widget<OutlinedButton>(viewProfile).onPressed, isNotNull);
    });

    testWidgets('lays out as a compact row on wide panes', (tester) async {
      await pumpCard(tester, width: 1000);

      final buttonRect = tester.getRect(viewProfile);
      final introRect = tester.getRect(introText);

      expect(buttonRect.left, greaterThan(introRect.right));
      expect(buttonRect.top, lessThan(introRect.bottom));
      expect(tester.getSize(find.byType(DmProfileCard)).height, lessThan(100));
    });

    testWidgets('moves View Profile below the text on narrow panes', (
      tester,
    ) async {
      await pumpCard(tester, width: 320);

      final buttonRect = tester.getRect(viewProfile);
      final introRect = tester.getRect(introText);

      expect(buttonRect.top, greaterThanOrEqualTo(introRect.bottom));
      expect(tester.takeException(), isNull);
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

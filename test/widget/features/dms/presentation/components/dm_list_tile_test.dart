import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  DmConversation conversationWithPreview(String preview) => DmConversation(
    channelId: 'channel-1',
    username: 'test200hundred',
    participantId: 'user-2',
    previewMessage: preview,
    unreadCount: 0,
  );

  Future<void> pumpTile(WidgetTester tester, String preview) {
    return tester.pumpWidget(
      ProviderScope(
        child: buildTestMaterialApp(
          Scaffold(
            body: DmListTile(conversation: conversationWithPreview(preview)),
          ),
        ),
      ),
    );
  }

  testWidgets('shows an HTML preview as plain text', (tester) async {
    await pumpTile(tester, '<p>Tom &amp; <strong>Jerry</strong></p>');

    expect(find.text('Tom & Jerry'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
  });

  testWidgets('shows a plain-text preview unchanged', (tester) async {
    await pumpTile(tester, 'see you tomorrow');

    expect(find.text('see you tomorrow'), findsOneWidget);
  });
}

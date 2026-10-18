import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  DmConversation buildConversation() => DmConversation(
    channelId: 'channel-1',
    username: 'Ada Lovelace',
    participantId: 'user-1',
    previewMessage: '',
    unreadCount: 0,
  );

  Future<void> pumpCard(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: DmProfileCard(conversation: buildConversation()),
          ),
        ),
      ),
    );
  }

  final introText = find.textContaining(
    'This conversation is just between you and',
    findRichText: true,
  );
  final viewProfile = find.widgetWithText(OutlinedButton, 'View Profile');

  group('DmProfileCard', () {
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

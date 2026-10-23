import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

const _palette = AppPalette.light;

class FakeSelectedDmNotifier extends SelectedDmNotifier {
  FakeSelectedDmNotifier(this._initial);

  final DmConversation? _initial;

  @override
  DmConversation? build() => _initial;
}

DmConversation buildConversation({
  String channelId = 'channel-1',
  String username = 'Ada Okafor',
  String previewMessage = 'See you at standup',
  int unreadCount = 0,
}) {
  return DmConversation(
    channelId: channelId,
    username: username,
    participantId: 'user-$channelId',
    previewMessage: previewMessage,
    unreadCount: unreadCount,
  );
}

Widget buildTileUnderTest(
  DmConversation conversation, {
  DmConversation? selected,
}) {
  return ProviderScope(
    overrides: [
      selectedDmProvider.overrideWith(() => FakeSelectedDmNotifier(selected)),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        backgroundColor: _palette.sidebar,
        body: Column(children: [DmListTile(conversation: conversation)]),
      ),
    ),
  );
}

void main() {
  testWidgets('shows an HTML preview as plain text', (tester) async {
    await tester.pumpWidget(
      buildTileUnderTest(
        buildConversation(
          previewMessage: '<p>Tom &amp; <strong>Jerry</strong></p>',
        ),
      ),
    );

    expect(find.text('Tom & Jerry'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
  });

  testWidgets('shows a plain-text preview unchanged', (tester) async {
    await tester.pumpWidget(
      buildTileUnderTest(buildConversation(previewMessage: 'see you tomorrow')),
    );

    expect(find.text('see you tomorrow'), findsOneWidget);
  });
}

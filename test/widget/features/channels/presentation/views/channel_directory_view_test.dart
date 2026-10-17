import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeChannelNotifier extends ChannelNotifier {
  FakeChannelNotifier(this.initialState);

  final ChannelState initialState;

  @override
  ChannelState build() => initialState;
}

Widget buildTestWidget({ChannelState? channelState}) {
  final channels =
      channelState ??
      ChannelState(
        channels: [
          Channel(
            id: '1',
            name: 'general',
            description: 'General channel for workspace discussions',
            organisationId: 'org1',
            ownerId: 'u1',
            membersCount: 1,
            isJoined: true,
          ),
        ],
      );

  return ProviderScope(
    overrides: [
      channelProvider.overrideWith(() => FakeChannelNotifier(channels)),
      activeChatProvider.overrideWith(ActiveChatNotifier.new),
    ],
    child: buildTestMaterialApp(const ChannelDirectoryView()),
  );
}

void main() {
  group('ChannelDirectoryView', () {
    testWidgets('renders Directories header, tabs, search, and channel list', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Directories'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Channels'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('# general'), findsOneWidget);
      expect(find.text('Joined'), findsOneWidget);
      expect(find.text('1 members'), findsOneWidget);
    });

    testWidgets(
      'falls back to active #general channel when channels are empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(channelState: const ChannelState()),
        );
        await tester.pump();

        expect(find.text('# general'), findsOneWidget);
        expect(find.text('Joined'), findsOneWidget);
      },
    );

    testWidgets('filters channel list when search text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'general');
      await tester.pump();

      expect(find.text('# general'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      expect(find.text('# general'), findsNothing);
      expect(find.text('No channels found.'), findsOneWidget);
    });

    testWidgets('tapping channel selects it via activeChatProvider', (
      tester,
    ) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelProvider.overrideWith(
              () => FakeChannelNotifier(
                ChannelState(
                  channels: [
                    Channel(
                      id: '1',
                      name: 'general',
                      description: 'General channel',
                      organisationId: 'org1',
                      ownerId: 'u1',
                      membersCount: 1,
                      isJoined: true,
                    ),
                  ],
                ),
              ),
            ),
            activeChatProvider.overrideWith(ActiveChatNotifier.new),
          ],
          child: buildTestMaterialApp(
            Builder(
              builder: (context) {
                capturedContext = context;
                return const ChannelDirectoryView();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(capturedContext);
      container.read(activeChatProvider.notifier).selectChannelDirectory();

      expect(
        container.read(activeChatProvider).type,
        ActiveChatType.channelDirectory,
      );

      await tester.tap(find.text('# general'));
      await tester.pump();

      expect(container.read(activeChatProvider).type, ActiveChatType.channel);
      expect(container.read(activeChatProvider).id, 'general');
    });
  });
}

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
            name: 'advanced',
            description: 'Advanced track',
            organisationId: 'org1',
            ownerId: 'u1',
            membersCount: 312,
            isJoined: true,
          ),
          Channel(
            id: '2',
            name: 'all-teams',
            description: 'All teams discussion',
            organisationId: 'org1',
            ownerId: 'u2',
            membersCount: 7,
            isJoined: false,
          ),
          Channel(
            id: '3',
            name: 'announcement',
            description: 'Announcements',
            organisationId: 'org1',
            ownerId: 'u3',
            membersCount: 1903,
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
      expect(find.text('# advanced'), findsOneWidget);
      expect(find.text('# all-teams'), findsOneWidget);
      expect(find.text('# announcement'), findsOneWidget);
      expect(find.text('Joined'), findsNWidgets(2));
      expect(find.text('312 members'), findsOneWidget);
      expect(find.text('7 members'), findsOneWidget);
    });

    testWidgets('filters channel list when search text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'advanced');
      await tester.pump();

      expect(find.text('# advanced'), findsOneWidget);
      expect(find.text('# all-teams'), findsNothing);
      expect(find.text('# announcement'), findsNothing);
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
                      name: 'advanced',
                      description: 'Advanced track',
                      organisationId: 'org1',
                      ownerId: 'u1',
                      membersCount: 312,
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

      await tester.tap(find.text('# advanced'));
      await tester.pump();

      expect(container.read(activeChatProvider).type, ActiveChatType.channel);
      expect(container.read(activeChatProvider).id, 'advanced');
    });
  });
}

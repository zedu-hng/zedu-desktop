import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org1', name: 'Workspace', avatar: ''),
  );
}

class FakeChannelNotifier extends ChannelNotifier {
  FakeChannelNotifier(this.channels);

  final List<Channel> channels;

  @override
  Future<List<Channel>> build() async => channels;
}

Widget buildTestWidget({List<Channel>? channels}) {
  final channelList =
      channels ??
      [
        Channel(
          id: '1',
          name: 'general',
          description: 'General channel for workspace discussions',
          organisationId: 'org1',
          ownerId: 'u1',
          membersCount: 1,
          isJoined: true,
        ),
      ];

  return ProviderScope(
    overrides: [
      channelProvider.overrideWith(() => FakeChannelNotifier(channelList)),
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

    testWidgets('shows the empty state when the workspace has no channels', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(channels: const []));
      await tester.pump();

      expect(find.text('No channels found.'), findsOneWidget);
    });

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
              () => FakeChannelNotifier([
                Channel(
                  id: '1',
                  name: 'general',
                  description: 'General channel',
                  organisationId: 'org1',
                  ownerId: 'u1',
                  membersCount: 1,
                  isJoined: true,
                ),
              ]),
            ),
            activeChatProvider.overrideWith(ActiveChatNotifier.new),
            workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
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

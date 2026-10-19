import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class FakeCreditsNotifier extends CreditsNotifier {
  @override
  CreditsState build() => const CreditsState();

  @override
  Future<void> load({String? orgId}) async {}
}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org1', name: 'Workspace', avatar: ''),
  );
}

class FakeDmListNotifier extends DmListNotifier {
  @override
  Future<List<DmConversation>> build() async => [];
}

class FakeChannelNotifier extends ChannelNotifier {
  FakeChannelNotifier(this.channels);

  final List<Channel> channels;

  @override
  Future<List<Channel>> build() async => channels;
}

Widget buildHomeViewUnderTest() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(FakeAuthNotifier.new),
      creditsNotifierProvider.overrideWith(FakeCreditsNotifier.new),
      workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
      dmListProvider.overrideWith(FakeDmListNotifier.new),
      channelProvider.overrideWith(
        () => FakeChannelNotifier([
          Channel(
            id: '1',
            name: 'random',
            description: 'Random talk',
            organisationId: 'org1',
            ownerId: 'u1',
            membersCount: 15,
            isJoined: true,
          ),
        ]),
      ),
    ],
    child: buildTestMaterialApp(const HomeView()),
  );
}

void main() {
  group('HomeView View all channels navigation', () {
    testWidgets(
      'clicking View all channels in sidebar opens channel directory and selecting channel switches back',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildHomeViewUnderTest());
        await tester.pumpAndSettle();

        // Initially on general chat area
        expect(find.text('View all channels'), findsOneWidget);
        expect(find.text('# general'), findsWidgets);

        // Click "View all channels" in sidebar
        await tester.tap(find.text('View all channels'));
        await tester.pumpAndSettle();

        // Directories screen is shown
        expect(find.text('Directories'), findsOneWidget);
        expect(find.text('People'), findsWidgets);
        expect(find.text('Channels'), findsWidgets);
        expect(find.text('# random'), findsOneWidget);

        // Tap the channel item in the directory
        await tester.tap(find.text('# random'));
        await tester.pumpAndSettle();

        // Navigates back cleanly to chat area
        expect(find.text('Directories'), findsNothing);
      },
    );

    Future<ProviderContainer> openDirectory(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeViewUnderTest());
      await tester.pumpAndSettle();
      await tester.tap(find.text('View all channels'));
      await tester.pumpAndSettle();
      expect(find.text('Directories'), findsOneWidget);

      return ProviderScope.containerOf(tester.element(find.byType(HomeView)));
    }

    testWidgets('switching to the DMs tab leaves the directory', (
      tester,
    ) async {
      final container = await openDirectory(tester);

      container.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
      await tester.pumpAndSettle();

      expect(find.text('Directories'), findsNothing);
      expect(find.byType(ChannelDirectoryView), findsNothing);
      expect(find.byType(DmEmptyState), findsOneWidget);
    });

    testWidgets('picking a conversation leaves the directory', (tester) async {
      final container = await openDirectory(tester);

      container
          .read(selectedDmProvider.notifier)
          .select(
            DmConversation(
              channelId: 'dm-1',
              username: 'Ada',
              participantId: 'user-2',
              previewMessage: '',
              unreadCount: 0,
            ),
          );
      await tester.pump();

      expect(
        container.read(activeChatProvider).type,
        isNot(ActiveChatType.channelDirectory),
      );
      expect(find.byType(ChannelDirectoryView), findsNothing);
    });
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._user);

  final User _user;

  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, user: _user);
}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Workspace A', avatar: ''),
  );
}

class _FakeDmListNotifier extends DmListNotifier {
  _FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

User _user({bool online = true}) => User(
  id: 'me',
  firstName: 'Jennifer',
  lastName: 'Amanze',
  email: 'jenie@z.com',
  phone: '',
  username: 'Jenie',
  isVerified: true,
  isOnboarded: true,
  createdAt: DateTime(2026, 1, 1),
  currentOrg: 'org-1',
  currentOrganisationSlug: 'hng',
  avatarUrl: '',
  defaultAvatarUrl: '',
  status: UserStatus(online: online),
);

DmConversation _dm(String name, {required String participantId}) =>
    DmConversation(
      channelId: 'channel-$name',
      username: name,
      participantId: participantId,
      previewMessage: 'Hello',
      unreadCount: 0,
    );

final _withOwnSpace = [
  _dm('Song Martins', participantId: 'u-song'),
  _dm('Benjamin', participantId: 'u-ben'),
  _dm('Jenie', participantId: 'me'),
];

final _withoutOwnSpace = [
  _dm('Song Martins', participantId: 'u-song'),
  _dm('Benjamin', participantId: 'u-ben'),
];

void main() {
  group('SidebarDmList', () {
    late ProviderContainer container;

    Future<void> pumpList(
      WidgetTester tester, {
      required List<DmConversation> conversations,
      bool online = true,
    }) async {
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(_user(online: online)),
          ),
          workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          dmListProvider.overrideWith(() => _FakeDmListNotifier(conversations)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestMaterialApp(const Scaffold(body: SidebarDmList())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists every conversation', (tester) async {
      await pumpList(tester, conversations: _withOwnSpace);

      expect(find.text('Song Martins'), findsOneWidget);
      expect(find.text('Benjamin'), findsOneWidget);
      expect(find.text('Jenie (you)'), findsOneWidget);
    });

    testWidgets('shows your own space first, even when it is oldest', (
      tester,
    ) async {
      await pumpList(tester, conversations: _withOwnSpace);

      final ownTop = tester.getTopLeft(find.text('Jenie (you)')).dy;
      final songTop = tester.getTopLeft(find.text('Song Martins')).dy;
      final benTop = tester.getTopLeft(find.text('Benjamin')).dy;

      expect(ownTop, lessThan(songTop));
      expect(songTop, lessThan(benTop));
    });

    testWidgets('shows the online dot on your own space when online', (
      tester,
    ) async {
      await pumpList(tester, conversations: _withOwnSpace);

      expect(
        find.byKey(const ValueKey('own-space-online-dot')),
        findsOneWidget,
      );
    });

    testWidgets('hides the online dot when you are away', (tester) async {
      await pumpList(tester, conversations: _withOwnSpace, online: false);

      expect(find.byKey(const ValueKey('own-space-online-dot')), findsNothing);
    });

    testWidgets('shows no "(you)" row without an own space', (tester) async {
      await pumpList(tester, conversations: _withoutOwnSpace);

      expect(find.textContaining('(you)'), findsNothing);
      expect(find.text('Song Martins'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows nothing and does not break with no DMs', (tester) async {
      await pumpList(tester, conversations: const []);

      expect(find.byType(InkWell), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a row opens that conversation', (tester) async {
      await pumpList(tester, conversations: _withOwnSpace);

      await tester.tap(find.text('Benjamin'));
      await tester.pump();

      expect(container.read(selectedDmProvider)?.channelId, 'channel-Benjamin');
      expect(
        container.read(activeChatProvider),
        const ActiveChatState(
          type: ActiveChatType.directMessage,
          id: 'channel-Benjamin',
        ),
      );
    });

    testWidgets('tapping your own space opens it', (tester) async {
      await pumpList(tester, conversations: _withOwnSpace);

      await tester.tap(find.text('Jenie (you)'));
      await tester.pump();

      expect(container.read(selectedDmProvider)?.channelId, 'channel-Jenie');
    });
  });
}

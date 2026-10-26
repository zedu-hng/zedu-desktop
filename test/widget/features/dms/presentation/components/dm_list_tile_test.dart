import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

const _palette = AppPalette.light;

class FakeSecureStorageService extends Fake implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<String?> readData(String key) async => _values[key];

  @override
  Future<void> writeData(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> deleteValue(String key) async => _values.remove(key);
}

final _me = User(
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
);

/// Signs in [_me], so widgets that check for your own space can render.
class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, user: _me);
}

class FakeSelectedDmNotifier extends SelectedDmNotifier {
  FakeSelectedDmNotifier(this._initial);

  final DmConversation? _initial;

  @override
  DmConversation? build() => _initial;
}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class FakeDmListNotifier extends DmListNotifier {
  FakeDmListNotifier(this._conversations);

  final List<DmConversation> _conversations;

  @override
  Future<List<DmConversation>> build() async => _conversations;
}

DmConversation buildConversation({
  String channelId = 'channel-1',
  String username = 'Ada Okafor',
  String? participantId,
  String previewMessage = 'See you at standup',
  int unreadCount = 0,
}) {
  return DmConversation(
    channelId: channelId,
    username: username,
    participantId: participantId ?? 'user-$channelId',
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
      authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      dmDraftStoreProvider.overrideWith(
        (ref) => DmDraftStore(
          FakeSecureStorageService(),
          userId: 'user-1',
          orgId: 'org-1',
        ),
      ),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        backgroundColor: _palette.sidebar,
        body: Column(children: [DmListTile(conversation: conversation)]),
      ),
    ),
  );
}

TextStyle textStyleOf(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style!;
}

void main() {
  final selectedFill = _palette.onPrimary.withValues(alpha: 0.16);
  final hoverFill = _palette.onPrimary.withValues(alpha: 0.06);

  testWidgets('read and unread rows have distinct emphasis', (tester) async {
    await tester.pumpWidget(buildTileUnderTest(buildConversation()));
    expect(textStyleOf(tester, 'Ada Okafor').fontWeight, FontWeight.w500);
    expect(
      textStyleOf(tester, 'See you at standup').color,
      _palette.onPrimary.withValues(alpha: 0.72),
    );
    expect(find.text('0'), findsNothing);

    await tester.pumpWidget(
      buildTileUnderTest(buildConversation(unreadCount: 3)),
    );
    expect(textStyleOf(tester, 'Ada Okafor').fontWeight, FontWeight.w700);
    expect(
      textStyleOf(tester, 'See you at standup').fontWeight,
      FontWeight.w700,
    );
    expect(textStyleOf(tester, '3').color, _palette.textPrimary);
    final badge = tester.widget<Container>(
      find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
    );
    expect((badge.decoration! as BoxDecoration).color, _palette.accent);
  });

  testWidgets('tapping a row selects and highlights it', (tester) async {
    final conversation = buildConversation();
    await tester.pumpWidget(buildTileUnderTest(conversation));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DmListTile)),
    );

    await tester.tap(find.byType(DmListTile));
    await tester.pumpAndSettle();

    expect(container.read(selectedDmProvider), same(conversation));
    final ink = tester.widget<Ink>(find.byType(Ink));
    expect((ink.decoration! as BoxDecoration).color, selectedFill);
    final marker = find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          (w.decoration as BoxDecoration).color == _palette.accent,
    );
    expect(marker, findsOneWidget);
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).borderRadius,
      BorderRadius.circular(6),
    );
  });

  testWidgets('hover uses the subtle highlight and click cursor', (
    tester,
  ) async {
    await tester.pumpWidget(buildTileUnderTest(buildConversation()));
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.hoverColor, hoverFill);
    expect(inkWell.mouseCursor, SystemMouseCursors.click);
  });

  testWidgets('sidebar keeps row ink on a transparent Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(
              FakeSecureStorageService(),
              userId: 'user-1',
              orgId: 'org-1',
            ),
          ),
          dmListProvider.overrideWith(
            () => FakeDmListNotifier([buildConversation()]),
          ),
        ],
        child: buildTestMaterialApp(const Scaffold(body: DmSidebarList())),
      ),
    );
    await tester.pumpAndSettle();
    final material = find
        .ancestor(of: find.byType(DmListTile), matching: find.byType(Material))
        .first;
    expect(tester.widget<Material>(material).type, MaterialType.transparency);
    final sidebar = find.byWidgetPredicate(
      (w) => w is Container && w.color == _palette.sidebar,
    );
    expect(find.descendant(of: sidebar, matching: material), findsOneWidget);
  });

  group('DmListTile own space', () {
    testWidgets('labels your own space "(you)" with "Your notes and drafts"', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTileUnderTest(
          buildConversation(username: 'Jenie', participantId: 'me'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jenie (you)'), findsOneWidget);
      expect(find.text('Your notes and drafts'), findsOneWidget);
      expect(find.text('See you at standup'), findsNothing);
    });

    testWidgets('shows other DMs as before', (tester) async {
      await tester.pumpWidget(
        buildTileUnderTest(
          buildConversation(username: 'Song Martins', participantId: 'u-song'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Song Martins'), findsOneWidget);
      expect(find.text('See you at standup'), findsOneWidget);
      expect(find.textContaining('(you)'), findsNothing);
    });
  });
}

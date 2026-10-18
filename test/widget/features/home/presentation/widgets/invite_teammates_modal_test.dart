import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async => [];
}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  FakeWorkspaceNotifier({this.name = 'Acme Corp'});
  final String name;

  @override
  WorkspaceState build() => WorkspaceState(
    workspaces: [Workspace(id: '1', name: name, avatar: '', membersCount: 5)],
    selectedWorkspace: Workspace(
      id: '1',
      name: name,
      avatar: '',
      membersCount: 5,
    ),
  );
}

Widget buildInviteModalUnderTest({
  String? channelName,
  String? workspaceName,
  String selectedWorkspaceName = 'Acme Corp',
}) {
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(FakeUserProfileNotifier.new),
      workspaceProvider.overrideWith(
        () => FakeWorkspaceNotifier(name: selectedWorkspaceName),
      ),
    ],
    child: buildTestMaterialApp(
      Scaffold(
        body: InviteTeammatesModal(
          channelName: channelName,
          workspaceName: workspaceName,
        ),
      ),
    ),
  );
}

void main() {
  group('InviteTeammatesModal', () {
    Future<void> pumpModal(WidgetTester tester, Widget widget) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(widget);
      await tester.pump();
    }

    testWidgets(
      'displays channel name and channel subtitle when channelName is provided',
      (tester) async {
        await pumpModal(
          tester,
          buildInviteModalUnderTest(channelName: 'announcements'),
        );

        expect(find.text('Add people to #announcements'), findsOneWidget);
        expect(
          find.text(
            'Search for people in your organisation and add them to #announcements.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('normalizes channelName that already includes leading #', (
      tester,
    ) async {
      await pumpModal(
        tester,
        buildInviteModalUnderTest(channelName: '#random'),
      );

      expect(find.text('Add people to #random'), findsOneWidget);
      expect(
        find.text(
          'Search for people in your organisation and add them to #random.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'displays explicit workspaceName and generic subtitle when workspaceName is provided',
      (tester) async {
        await pumpModal(
          tester,
          buildInviteModalUnderTest(workspaceName: 'Engineering Team'),
        );

        expect(find.text('Add people to Engineering Team'), findsOneWidget);
        expect(
          find.text('Search for people in your organisation to invite them.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'falls back to selectedWorkspace from state when no channelName or workspaceName is passed',
      (tester) async {
        await pumpModal(
          tester,
          buildInviteModalUnderTest(selectedWorkspaceName: 'Team Vader'),
        );

        expect(find.text('Add people to Team Vader'), findsOneWidget);
        expect(
          find.text('Search for people in your organisation to invite them.'),
          findsOneWidget,
        );
      },
    );
  });
}

import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

const _members = [
  TeamMember(
    id: 'ada',
    name: 'Ada Lovelace',
    email: 'eng@x.dev',
    role: 'Manager',
    dateJoined: 'Oct 1',
    status: TeamMemberStatus.active,
  ),
  TeamMember(
    id: 'grace',
    name: 'Grace Hopper',
    email: 'code@x.dev',
    role: 'User',
    dateJoined: 'Oct 1',
    status: TeamMemberStatus.active,
  ),
  TeamMember(
    id: 'unnamed',
    email: 'help@x.dev',
    role: 'User',
    dateJoined: 'Oct 1',
    status: TeamMemberStatus.active,
  ),
];

Future<void> _pumpSection(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: DataTableTheme(
          // Leave room for the test font within the section's fixed table width.
          data: const DataTableThemeData(columnSpacing: 16),
          child: SingleChildScrollView(
            child: UserManagementSection(
              members: _members,
              isSaving: false,
              onInvite: ({required email, required role}) async {},
              onUpdate: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('finds a member by name regardless of case or query whitespace', (
    tester,
  ) async {
    await _pumpSection(tester);

    await tester.enterText(find.byType(TextField), '  aDA LoVE  ');
    await tester.pump();

    expect(find.text('eng@x.dev'), findsOneWidget);
    expect(find.text('code@x.dev'), findsNothing);
    expect(find.text('help@x.dev'), findsNothing);
  });

  testWidgets('email search supports members without a name', (tester) async {
    await _pumpSection(tester);

    await tester.enterText(find.byType(TextField), '  HELP@  ');
    await tester.pump();

    expect(find.text('help@x.dev'), findsOneWidget);
    expect(find.text('eng@x.dev'), findsNothing);
    expect(find.text('code@x.dev'), findsNothing);
  });

  testWidgets('name matches still respect the selected role filter', (
    tester,
  ) async {
    await _pumpSection(tester);

    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('User').last);
    await tester.pumpAndSettle();

    expect(find.text('eng@x.dev'), findsNothing);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manager').last);
    await tester.pumpAndSettle();

    expect(find.text('eng@x.dev'), findsOneWidget);
    expect(find.text('code@x.dev'), findsNothing);
  });

  testWidgets('clearing search restores all members', (tester) async {
    await _pumpSection(tester);

    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    for (final member in _members) {
      expect(find.text(member.email), findsOneWidget);
    }
  });
}

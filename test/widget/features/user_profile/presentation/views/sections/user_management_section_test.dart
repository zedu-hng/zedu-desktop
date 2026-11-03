import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

const _ada = TeamMember(
  id: 'u-1',
  email: 'a.l@zedu.test',
  role: 'Administrator',
  dateJoined: '2026-01-01',
  status: TeamMemberStatus.active,
  name: 'Ada Lovelace',
);

const _grace = TeamMember(
  id: 'u-2',
  email: 'g.h@zedu.test',
  role: 'User',
  dateJoined: '2026-01-02',
  status: TeamMemberStatus.active,
  name: 'Grace Hopper',
);

const _noName = TeamMember(
  id: 'u-3',
  email: 'pending@zedu.test',
  role: 'User',
  dateJoined: '2026-01-03',
  status: TeamMemberStatus.pending,
);

Future<void> pumpSection(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // The table's fixed-width column headers only overflow with the wide Ahem
  // test font; ignore that layout warning, keep every other error.
  final onError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    onError?.call(details);
  };
  addTearDown(() => FlutterError.onError = onError);
  await tester.pumpWidget(
    buildTestMaterialApp(
      Scaffold(
        body: SingleChildScrollView(
          child: UserManagementSection(
            members: const [_ada, _grace, _noName],
            isSaving: false,
            onInvite: ({required email, required role}) async {},
            onUpdate: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    ),
  );
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Search by name or email'),
    query,
  );
  await tester.pump();
}

void main() {
  group('UserManagementSection search', () {
    testWidgets('matches a member by name', (tester) async {
      await pumpSection(tester);

      await search(tester, 'lovelace');

      expect(find.text('a.l@zedu.test'), findsOneWidget);
      expect(find.text('g.h@zedu.test'), findsNothing);
      expect(find.text('pending@zedu.test'), findsNothing);
    });

    testWidgets('still matches a member by email', (tester) async {
      await pumpSection(tester);

      await search(tester, 'PENDING@');

      expect(find.text('pending@zedu.test'), findsOneWidget);
      expect(find.text('a.l@zedu.test'), findsNothing);
    });

    testWidgets('shows nobody when neither name nor email matches', (
      tester,
    ) async {
      await pumpSection(tester);

      await search(tester, 'turing');

      expect(find.text('a.l@zedu.test'), findsNothing);
      expect(find.text('g.h@zedu.test'), findsNothing);
      expect(find.text('pending@zedu.test'), findsNothing);
    });
  });
}

import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

TeamMember member({String? name, required String email, String id = 'u-1'}) {
  return TeamMember(
    id: id,
    email: email,
    role: 'Member',
    dateJoined: '2026-01-01',
    status: TeamMemberStatus.active,
    name: name,
  );
}

Widget panel(GroupDM group) {
  return buildTestMaterialApp(
    Scaffold(
      body: Align(
        alignment: Alignment.centerRight,
        child: GroupDetailsPanel(
          group: group,
          onClose: () {},
          onRename: (_) {},
          onLeave: () {},
        ),
      ),
    ),
  );
}

String avatarInitial(WidgetTester tester, int index) {
  final avatar = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar));
  return (avatar.elementAt(index).child! as Text).data!;
}

void main() {
  group('GroupDetailsPanel', () {
    testWidgets('falls back to the email when a member name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        panel(
          GroupDM(
            id: 'g-1',
            name: 'Design',
            members: [member(name: '', email: 'ada@zedu.test')],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(avatarInitial(tester, 0), 'A');
      expect(find.text('ada@zedu.test'), findsOneWidget);
    });

    testWidgets('shows ? when both name and email are empty', (tester) async {
      await tester.pumpWidget(
        panel(
          GroupDM(
            id: 'g-1',
            name: 'Design',
            members: [member(name: '  ', email: '')],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(avatarInitial(tester, 0), '?');
    });

    testWidgets('uses the whole first character of an emoji name', (
      tester,
    ) async {
      await tester.pumpWidget(
        panel(
          GroupDM(
            id: 'g-1',
            name: 'Design',
            members: [member(name: '😀 Sam', email: 'sam@zedu.test')],
          ),
        ),
      );

      expect(avatarInitial(tester, 0), '😀');
    });

    testWidgets('rename field follows a new group passed to the panel', (
      tester,
    ) async {
      final members = [member(name: 'Ada', email: 'ada@zedu.test')];
      await tester.pumpWidget(
        panel(GroupDM(id: 'g-1', name: 'Design', members: members)),
      );
      await tester.pumpWidget(
        panel(GroupDM(id: 'g-2', name: 'Marketing', members: members)),
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Marketing',
      );
    });

    testWidgets('does not overwrite a rename the user is typing', (
      tester,
    ) async {
      final members = [member(name: 'Ada', email: 'ada@zedu.test')];
      await tester.pumpWidget(
        panel(GroupDM(id: 'g-1', name: 'Design', members: members)),
      );
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Design team');

      await tester.pumpWidget(
        panel(GroupDM(id: 'g-1', name: 'Design v2', members: members)),
      );

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Design team',
      );
    });
  });
}

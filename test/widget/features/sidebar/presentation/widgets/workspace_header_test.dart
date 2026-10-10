import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  static const _workspace = Workspace(
    id: '1',
    name: 'commabuster',
    avatar: '',
    membersCount: 12,
  );

  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [_workspace],
    selectedWorkspace: _workspace,
  );
}

Widget buildHeaderUnderTest() {
  return ProviderScope(
    overrides: [workspaceProvider.overrideWith(FakeWorkspaceNotifier.new)],
    child: MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.only(left: 100, top: 40),
              child: Container(
                color: Colors.indigo,
                child: const WorkspaceSwitcherHeader(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Tests render text in a very wide placeholder font, which overflows the
// menu footer. A smaller text scale keeps the layout checks meaningful.
Future<void> useTestWindow(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1024));
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

void main() {
  group('WorkspaceSwitcherHeader', () {
    testWidgets('opens the menu under the name and flips the arrow', (
      tester,
    ) async {
      await useTestWindow(tester);

      await tester.pumpWidget(buildHeaderUnderTest());
      await tester.pump();

      final headerRect = tester.getRect(find.byType(WorkspaceSwitcherHeader));
      final nameRect = tester.getRect(find.text('commabuster'));
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0,
      );

      await tester.tap(find.text('commabuster'));
      await tester.pumpAndSettle();

      final menuRect = tester.getRect(find.byType(WorkspaceSwitcherList));
      expect(find.text('Switch Workspaces'), findsOneWidget);
      expect(menuRect.left, nameRect.left - 8);
      expect(menuRect.top, headerRect.bottom + 10);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.5,
      );
    });

    testWidgets('closes when tapping outside and flips the arrow back', (
      tester,
    ) async {
      await useTestWindow(tester);

      await tester.pumpWidget(buildHeaderUnderTest());
      await tester.pump();

      await tester.tap(find.text('commabuster'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceSwitcherList), findsOneWidget);

      await tester.tapAt(const Offset(1300, 900));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceSwitcherList), findsNothing);
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0,
      );
    });
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [Workspace(id: '1', name: 'Acme', avatar: 'A')],
    selectedWorkspace: Workspace(id: '1', name: 'Acme', avatar: 'A'),
  );
}

Widget buildSwitcherUnderTest() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Align(
                  alignment: Alignment.topLeft,
                  child: WorkspaceSwitcherList(),
                ),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRouter.profile,
        builder: (context, state) => const Scaffold(body: Text('Profile page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [workspaceProvider.overrideWith(FakeWorkspaceNotifier.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('WorkspaceSwitcherList', () {
    testWidgets('footer shows "Add a new organization" tooltip', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildSwitcherUnderTest());
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Add a new organization'), findsOneWidget);
    });

    testWidgets('workspace list item shows its name as tooltip', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildSwitcherUnderTest());
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Acme'), findsWidgets);
    });
  });
}

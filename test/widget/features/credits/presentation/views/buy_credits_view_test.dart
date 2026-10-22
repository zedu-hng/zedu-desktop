import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockCreditsRepository extends Mock implements CreditsRepository {}

void main() {
  late MockCreditsRepository repository;

  setUp(() {
    repository = MockCreditsRepository();
  });

  void stubAllCreditCalls() {
    when(() => repository.getPackages()).thenAnswer(
      (_) async => const Success<List<CreditPackage>>([]),
    );
    when(() => repository.getUsage(any())).thenAnswer(
      (_) async => const Success<CreditUsage>(CreditUsage.empty),
    );
    when(() => repository.getUsageReport(any())).thenAnswer(
      (_) async => const Success<CreditUsageReport>(CreditUsageReport.empty),
    );
    when(() => repository.getTransactions(any())).thenAnswer(
      (_) async => const Success<List<CreditTransaction>>([]),
    );
  }

  testWidgets(
    'loads credits for the selected workspace, not the login organisation',
    (tester) async {
      stubAllCreditCalls();

      final workspaceState = WorkspaceState(
        workspaces: [
          const Workspace(id: 'workspace-123', name: 'Workspace A', avatar: ''),
          const Workspace(id: 'workspace-456', name: 'Workspace B', avatar: ''),
        ],
        selectedWorkspace: const Workspace(
          id: 'workspace-123',
          name: 'Workspace A',
          avatar: '',
        ),
        isLoading: false,
      );

      final authUser = User(
        id: 'user-1',
        firstName: 'Test',
        lastName: 'User',
        email: 'user@example.com',
        phone: '',
        username: 'testuser',
        isVerified: false,
        isOnboarded: false,
        createdAt: DateTime(2026),
        currentOrg: 'login-org-999',
        currentOrganisationSlug: 'login-org',
        avatarUrl: '',
        defaultAvatarUrl: '',
        creditBalance: 0,
        subscriptionPlanId: '',
      );

      final testContainer = ProviderContainer(
        overrides: [
          creditsRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWithValue(workspaceState),
          authNotifierProvider.overrideWithValue(
            AuthState(status: AuthStatus.authenticated, user: authUser),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      await tester.pumpWidget(
        ProviderScope(
          container: testContainer,
          child: const MaterialApp(home: BuyCreditsView()),
        ),
      );
      await tester.pumpAndSettle();

      // Credits should have been loaded for workspace-123, not login-org-999.
      verify(() => repository.getUsage('workspace-123')).called(1);
      verify(() => repository.getUsage('login-org-999')).called(0);
    },
  );

  testWidgets(
    'reloads credits when the selected workspace changes',
    (tester) async {
      stubAllCreditCalls();

      final initialState = WorkspaceState(
        workspaces: [
          const Workspace(id: 'workspace-123', name: 'Workspace A', avatar: ''),
        ],
        selectedWorkspace: const Workspace(
          id: 'workspace-123',
          name: 'Workspace A',
          avatar: '',
        ),
        isLoading: false,
      );

      final testContainer = ProviderContainer(
        overrides: [
          creditsRepositoryProvider.overrideWithValue(repository),
          workspaceProvider.overrideWithValue(initialState),
        ],
      );
      addTearDown(testContainer.dispose);

      await tester.pumpWidget(
        ProviderScope(
          container: testContainer,
          child: const MaterialApp(home: BuyCreditsView()),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => repository.getUsage('workspace-123')).called(1);
      verifyNever(() => repository.getUsage('workspace-456'));

      // Switch to workspace-456.
      await testContainer
          .read(workspaceProvider.notifier)
          .switchWorkspace(const Workspace(
            id: 'workspace-456',
            name: 'Workspace B',
            avatar: '',
          ));
      await tester.pumpAndSettle();

      // Credits should reload for workspace-456.
      verify(() => repository.getUsage('workspace-456')).called(1);
    },
  );
}

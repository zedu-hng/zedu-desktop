import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-increase-chima',
      firstName: 'Increase',
      lastName: 'Chima',
      email: 'increasechima@example.com',
      phone: '0000000000',
      username: 'increasechima',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'increase-workspace',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

Widget buildUserMenuDialogUnderTest() {
  final router = GoRouter(
    initialLocation: AppRouter.profile,
    routes: [
      GoRoute(
        path: AppRouter.profile,
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const UserMenuDialog(),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRouter.home,
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('Home route'),
              if (AppRouter.shouldOpenProfilePanel(state))
                const Text('Profile panel requested'),
            ],
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(FakeAuthNotifier.new),
      orgCreditBalanceProvider.overrideWithValue(0),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('UserMenuDialog', () {
    testWidgets('opens the profile panel from a non-home route', (
      tester,
    ) async {
      await tester.pumpWidget(buildUserMenuDialogUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile…'));
      await tester.pumpAndSettle();

      expect(find.text('Home route'), findsOneWidget);
      expect(find.text('Profile panel requested'), findsOneWidget);
    });
  });
}

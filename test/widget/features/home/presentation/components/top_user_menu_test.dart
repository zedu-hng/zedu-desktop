import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

User increaseChimaProfile() {
  return User(
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
  );
}

Widget buildTopUserMenuUnderTest() {
  final profile = increaseChimaProfile();
  final router = GoRouter(
    initialLocation: AppRouter.profile,
    routes: [
      GoRoute(
        path: AppRouter.profile,
        builder: (context, state) => Scaffold(
          body: Center(child: TopUserMenu(userName: profile.fullname)),
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
    overrides: [orgCreditBalanceProvider.overrideWithValue(0)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('TopUserMenu', () {
    testWidgets('opens the profile panel from a non-home route', (
      tester,
    ) async {
      await tester.pumpWidget(buildTopUserMenuUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Increase Chima'), findsOneWidget);
      expect(find.text('Home route'), findsNothing);
      expect(find.text('Profile panel visible'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Home route'), findsOneWidget);
      expect(find.text('Profile panel requested'), findsOneWidget);
    });
  });
}

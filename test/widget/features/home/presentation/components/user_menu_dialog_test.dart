import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({AuthState initial = const AuthState()})
    : _initial = initial;

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

User _testUser() => User(
  id: 'u-1',
  firstName: 'Reneilwe',
  lastName: 'Taunyane',
  email: 'r@z.com',
  phone: '',
  username: 'reneilwe',
  isVerified: true,
  isOnboarded: true,
  createdAt: DateTime(2024, 1, 1),
  currentOrg: 'org',
  currentOrganisationSlug: 'z',
  avatarUrl: '',
  defaultAvatarUrl: '',
  status: const UserStatus(online: true),
);

Widget _homeWithDialog() => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(
      () => FakeAuthNotifier(
        initial: AuthState(status: AuthStatus.authenticated, user: _testUser()),
      ),
    ),
    orgCreditBalanceProvider.overrideWith((ref) => 100),
    personalProfilePanelProvider.overrideWith((ref) => false),
  ],
  child: MaterialApp(
    home: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {
          Navigator.push<void>(
            context,
            DialogRoute<void>(
              context: context,
              builder: (context) => const UserMenuDialog(),
            ),
          );
        },
      ),
    ),
  ),
);

Widget _homeWithDialogInContainer(ProviderContainer container) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push<void>(
                context,
                DialogRoute<void>(
                  context: context,
                  builder: (context) => const UserMenuDialog(),
                ),
              );
            },
          ),
        ),
      ),
    );

void main() {
  group('UserMenuDialog', () {
    testWidgets(
      'shows "Pause notifications" with crossed-out bell when DND is inactive',
      (tester) async {
        await tester.pumpWidget(_homeWithDialog());
        await tester.tap(find.byType(IconButton));
        await tester.pumpAndSettle();

        expect(find.text('Pause notifications'), findsOneWidget);
        expect(find.text('Resume notifications'), findsNothing);
        expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
        expect(find.byIcon(Icons.notifications), findsNothing);
      },
    );

    testWidgets('tapping "Pause notifications" pauses notifications', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(
              initial: AuthState(
                status: AuthStatus.authenticated,
                user: _testUser(),
              ),
            ),
          ),
          orgCreditBalanceProvider.overrideWith((ref) => 100),
          personalProfilePanelProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_homeWithDialogInContainer(container));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pause notifications'));
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider).isDndActive, isTrue);
    });

    testWidgets('shows "Resume notifications" with normal bell after pausing', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(
              initial: AuthState(
                status: AuthStatus.authenticated,
                user: _testUser(),
              ),
            ),
          ),
          orgCreditBalanceProvider.overrideWith((ref) => 100),
          personalProfilePanelProvider.overrideWith((ref) => false),
          notificationSettingsProvider.overrideWith(() => _FakeDndNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_homeWithDialogInContainer(container));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Resume notifications'), findsOneWidget);
      expect(find.text('Pause notifications'), findsNothing);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });

    testWidgets('tapping "Resume notifications" clears DND', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => FakeAuthNotifier(
              initial: AuthState(
                status: AuthStatus.authenticated,
                user: _testUser(),
              ),
            ),
          ),
          orgCreditBalanceProvider.overrideWith((ref) => 100),
          personalProfilePanelProvider.overrideWith((ref) => false),
          notificationSettingsProvider.overrideWith(() => _FakeDndNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_homeWithDialogInContainer(container));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resume notifications'));
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider).isDndActive, isFalse);
    });
  });
}

class _FakeDndNotifier extends NotificationSettingsNotifier {
  @override
  NotificationSettings build() =>
      NotificationSettings(dndUntil: DateTime(2099, 1, 1));
}

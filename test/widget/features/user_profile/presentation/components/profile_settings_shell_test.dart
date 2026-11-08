import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  group('ProfileSettingsShell', () {
    testWidgets('renders Scaffold and navigation with theme tokens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(
              _FakeUserProfileNotifier.new,
            ),
            authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
            orgCreditBalanceProvider.overrideWithValue(0),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: ProfileSettingsShell(
              selectedSection: UserProfileSection.account,
              onSectionSelected: (_) {},
              child: const Text('Settings Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ProfileSettingsShell), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppPalette.light.background);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Settings Content'), findsOneWidget);
    });
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

void main() {
  testWidgets('pressing Escape dismisses the settings modal', (tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileNotifierProvider.overrideWith(
            () => FakeUserProfileNotifier(),
          ),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
          orgCreditBalanceProvider.overrideWithValue(0),
        ],
        child: buildTestMaterialApp(
          ProfileSettingsShell(
            selectedSection: UserProfileSection.account,
            onSectionSelected: (_) {},
            child: const Text('Settings content'),
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings content'), findsOneWidget);
    expect(dismissed, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}

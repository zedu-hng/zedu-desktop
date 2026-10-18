import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({this.onForgotPassword});

  final void Function(String email)? onForgotPassword;

  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<bool> forgotPassword({required String email}) async {
    onForgotPassword?.call(email);
    return false;
  }
}

Widget buildForgotPasswordViewUnderTest({FakeAuthNotifier? notifier}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier ?? FakeAuthNotifier()),
    ],
    child: const MaterialApp(home: ForgotPasswordView()),
  );
}

void main() {
  group('ForgotPasswordView', () {
    testWidgets('submits the email when Enter is pressed', (tester) async {
      String? submittedEmail;

      await tester.pumpWidget(
        buildForgotPasswordViewUnderTest(
          notifier: FakeAuthNotifier(
            onForgotPassword: (email) => submittedEmail = email,
          ),
        ),
      );
      await tester.pump();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'user@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedEmail, 'user@example.com');
    });

    testWidgets('validates the email before submitting with Enter', (
      tester,
    ) async {
      var submissionCount = 0;

      await tester.pumpWidget(
        buildForgotPasswordViewUnderTest(
          notifier: FakeAuthNotifier(
            onForgotPassword: (_) => submissionCount++,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(TextFormField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(submissionCount, 0);
    });
  });
}

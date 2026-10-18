import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    this.initial = const AuthState(status: AuthStatus.authenticated),
  });

  final AuthState initial;

  @override
  AuthState build() => initial;
}

Widget buildSetStatusDialogUnderTest({AuthState? authState}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(
        () => FakeAuthNotifier(
          initial:
              authState ?? const AuthState(status: AuthStatus.authenticated),
        ),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: SetStatusDialog())),
  );
}

Finder findClearIcon() => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon == Icons.close && widget.size == 16,
);

User testUserWithStatus(UserStatus status) {
  return User(
    id: 'user-1',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    phone: '0000000000',
    username: 'testuser',
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2024),
    currentOrg: 'org-1',
    currentOrganisationSlug: 'hng',
    avatarUrl: '',
    defaultAvatarUrl: '',
    status: status,
  );
}

void main() {
  group('SetStatusDialog', () {
    testWidgets('shows the clear button once status text is typed', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSetStatusDialogUnderTest());
      await tester.pump();

      expect(findClearIcon(), findsNothing);

      await tester.enterText(find.byType(TextField), 'In a meeting');
      await tester.pump();

      expect(findClearIcon(), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'In a meeting',
      );
    });

    testWidgets('tapping clear empties the field and hides the button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSetStatusDialogUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'In a meeting');
      await tester.pump();

      await tester.tap(findClearIcon());
      await tester.pump();

      expect(findClearIcon(), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('pre-filled status shows the clear button and clears both', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authState = AuthState(
        status: AuthStatus.authenticated,
        user: testUserWithStatus(
          const UserStatus(emoji: '🎯', text: 'Heads down'),
        ),
      );

      await tester.pumpWidget(
        buildSetStatusDialogUnderTest(authState: authState),
      );
      await tester.pump();

      expect(find.text('🎯'), findsOneWidget);
      expect(findClearIcon(), findsOneWidget);

      await tester.tap(findClearIcon());
      await tester.pump();

      expect(findClearIcon(), findsNothing);
      expect(find.text('🎯'), findsNothing);
      expect(find.text('Heads down'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets(
      'picking a suggested preset fills the field and shows the button',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1440, 1024));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildSetStatusDialogUnderTest());
        await tester.pump();

        await tester.tap(find.text('In a meeting'));
        await tester.pump();

        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'In a meeting',
        );
        expect(findClearIcon(), findsOneWidget);
      },
    );
  });
}

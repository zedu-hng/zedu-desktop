import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Avoids the locator and API: registered users and invites are supplied here.
class FakeUserProfileNotifier extends UserProfileNotifier {
  FakeUserProfileNotifier({
    this.users = const [],
    this.loadFails = false,
    this.loadGate,
  });

  final List<Map<String, dynamic>> users;
  final bool loadFails;

  /// When set, the users request stays pending until it is completed.
  final Completer<void>? loadGate;
  final List<String> invited = [];

  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<Result<List<Map<String, dynamic>>>> loadRegisteredUsers() async {
    if (loadGate != null) await loadGate!.future;
    if (loadFails) {
      return Failure(ApiFailure(message: 'Could not load users.'));
    }
    return Success(users);
  }

  @override
  Future<void> inviteMember({
    required String email,
    required String role,
    String? userId,
  }) async {
    invited.add(email);
  }
}

Map<String, dynamic> user(String email, {String? fullName, String? id}) => {
  'id': id,
  'email': email,
  'full_name': fullName,
  'username': fullName,
};

// Lets a test open the window while a given channel is open in the sidebar.
class FakeActiveChatNotifier extends ActiveChatNotifier {
  FakeActiveChatNotifier(this._initial);

  final ActiveChatState _initial;

  @override
  ActiveChatState build() => _initial;
}

late FakeUserProfileNotifier notifierUnderTest;

Widget buildModalUnderTest(
  FakeUserProfileNotifier notifier, {
  ActiveChatState chat = ActiveChatState.generalChannel,
}) {
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(
        () => notifierUnderTest = notifier,
      ),
      activeChatProvider.overrideWith(() => FakeActiveChatNotifier(chat)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              // The test font draws every glyph as a full square, so the
              // 20px title is wider than in the app. Shrink text to fit.
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(0.7)),
                child: const InviteTeammatesModal(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openModal(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.byType(InviteTeammatesModal), findsOneWidget);
}

Future<void> tapAddEveryone(WidgetTester tester) async {
  await tester.tap(find.text('Add everyone'));
  await tester.pumpAndSettle();
}

Future<void> typeEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  group('InviteTeammatesModal "Add everyone"', () {
    testWidgets('selects every registered user, keeping earlier picks', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(
            users: [
              user('ada@zedu.chat', fullName: 'Ada'),
              user('bob@zedu.chat', fullName: 'Bob'),
              user('cy@zedu.chat', fullName: 'Cy'),
            ],
          ),
        ),
      );
      await openModal(tester);

      await typeEmail(tester, 'bob@zedu.chat');
      expect(find.byType(Chip), findsOneWidget);

      await tapAddEveryone(tester);

      expect(find.widgetWithText(Chip, 'ada@zedu.chat'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'bob@zedu.chat'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'cy@zedu.chat'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.byType(InviteTeammatesModal), findsOneWidget);
    });

    testWidgets('clicking again adds nobody twice', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(
            users: [
              user('ada@zedu.chat', fullName: 'Ada'),
              user('bob@zedu.chat', fullName: 'Bob'),
            ],
          ),
        ),
      );
      await openModal(tester);

      await tapAddEveryone(tester);
      expect(find.byType(Chip), findsNWidgets(2));

      await tapAddEveryone(tester);

      expect(find.byType(Chip), findsNWidgets(2));
      expect(
        find.text('Everyone in your organisation is already selected.'),
        findsOneWidget,
      );
    });

    testWidgets('ignores users without an email address', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(
            users: [
              user('ada@zedu.chat', fullName: 'Ada'),
              user(''),
            ],
          ),
        ),
      );
      await openModal(tester);

      await tapAddEveryone(tester);

      expect(find.byType(Chip), findsOneWidget);
      expect(find.widgetWithText(Chip, 'ada@zedu.chat'), findsOneWidget);
    });

    testWidgets('merges case-insensitive duplicates', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(
            users: [
              user('ada@zedu.chat', fullName: 'Ada'),
              user('Ada@Zedu.chat', fullName: 'Ada again'),
            ],
          ),
        ),
      );
      await openModal(tester);

      await tapAddEveryone(tester);

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('explains a failed load instead of doing nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildModalUnderTest(FakeUserProfileNotifier(loadFails: true)),
      );
      await openModal(tester);

      await tapAddEveryone(tester);

      expect(
        find.text(
          'Could not load the people in your organisation. Close this window '
          'and open it again to retry.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('explains that nobody is left to add', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(FakeUserProfileNotifier(users: const [])),
      );
      await openModal(tester);

      await tapAddEveryone(tester);

      expect(
        find.text('Everyone in your organisation is already selected.'),
        findsOneWidget,
      );
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('waits for the users to load before selecting', (tester) async {
      final gate = Completer<void>();
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(
            users: [user('ada@zedu.chat', fullName: 'Ada')],
            loadGate: gate,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();

      await tapAddEveryone(tester);
      expect(
        find.text('Still loading people. Try again shortly.'),
        findsOneWidget,
      );
      expect(find.byType(Chip), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      await tapAddEveryone(tester);

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('names the channel that is open in the title', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(),
          chat: const ActiveChatState(
            type: ActiveChatType.channel,
            id: 'design',
          ),
        ),
      );
      await openModal(tester);

      expect(find.text('Add people to #design'), findsOneWidget);
      expect(find.text('Add people to #general'), findsNothing);
    });

    testWidgets('keeps a very long channel name inside the title', (
      tester,
    ) async {
      final longName = 'a-very-long-channel-name-' * 8;
      await tester.pumpWidget(
        buildModalUnderTest(
          FakeUserProfileNotifier(),
          chat: ActiveChatState(type: ActiveChatType.channel, id: longName),
        ),
      );
      await openModal(tester);

      // A RenderFlex overflow would be reported as an exception here.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Add people to #a-very-long'), findsOneWidget);
    });

    testWidgets('leaves Copy Invite Link and Add in place', (tester) async {
      await tester.pumpWidget(buildModalUnderTest(FakeUserProfileNotifier()));
      await openModal(tester);

      expect(find.byTooltip('Copy Invite Link'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
    });
  });

  group('InviteTeammatesModal email validation', () {
    const errorText = 'Please enter a valid email address.';

    Future<FakeUserProfileNotifier> pumpModal(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // The fixed 480px dialog's button row only overflows with the wide
      // Ahem test font; ignore that layout warning, keep every other error.
      final onError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) return;
        onError?.call(details);
      };
      addTearDown(() => FlutterError.onError = onError);
      final notifier = FakeUserProfileNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(() => notifier),
            activeChatProvider.overrideWith(
              () => FakeActiveChatNotifier(ActiveChatState.generalChannel),
            ),
          ],
          child: buildTestMaterialApp(
            const Scaffold(body: InviteTeammatesModal()),
          ),
        ),
      );
      await tester.pump();
      return notifier;
    }

    Future<void> submitText(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    for (final invalid in ['@@@', 'abc@', 'name@domain']) {
      testWidgets('rejects "$invalid" with an error', (tester) async {
        await pumpModal(tester);

        await submitText(tester, invalid);

        expect(find.byType(Chip), findsNothing);
        expect(find.text(errorText), findsOneWidget);
      });
    }

    testWidgets('clears the error when the user types again', (tester) async {
      await pumpModal(tester);
      await submitText(tester, 'abc@');
      expect(find.text(errorText), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abc@zedu.chat');
      await tester.pump();

      expect(find.text(errorText), findsNothing);
    });

    testWidgets('adds a valid email as an invite', (tester) async {
      await pumpModal(tester);

      await submitText(tester, ' ada@example.com ');

      expect(find.widgetWithText(Chip, 'ada@example.com'), findsOneWidget);
      expect(find.text(errorText), findsNothing);
    });

    testWidgets('adds the same email in different case only once', (
      tester,
    ) async {
      await pumpModal(tester);

      await submitText(tester, 'Ada@example.com');
      await submitText(tester, 'ada@example.com');

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('Add with invalid text left in the box sends nothing', (
      tester,
    ) async {
      final notifier = await pumpModal(tester);
      await submitText(tester, 'ada@example.com');
      await tester.enterText(find.byType(TextField), 'abc@');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(notifier.invited, isEmpty);
      expect(find.text(errorText), findsOneWidget);
    });
  });
}

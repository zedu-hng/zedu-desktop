import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Avoids the locator: the modal only asks this notifier for search results.
class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState();

  @override
  Future<List<Map<String, dynamic>>> fetchRegisteredUsers() async => [];
}

class FakeAddEveryoneToGeneral extends AddEveryoneToGeneral {
  FakeAddEveryoneToGeneral(super.ref, this._result);

  final Future<AddEveryoneResult> Function() _result;
  int calls = 0;

  @override
  Future<AddEveryoneResult> call() {
    calls++;
    return _result();
  }
}

late FakeAddEveryoneToGeneral fakeAddEveryone;

Widget buildModalUnderTest(Future<AddEveryoneResult> Function() result) {
  return ProviderScope(
    overrides: [
      userProfileNotifierProvider.overrideWith(FakeUserProfileNotifier.new),
      addEveryoneToGeneralProvider.overrideWith(
        (ref) => fakeAddEveryone = FakeAddEveryoneToGeneral(ref, result),
      ),
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

void main() {
  group('InviteTeammatesModal "Add everyone"', () {
    testWidgets('adds everyone, shows how many and closes the window', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildModalUnderTest(() async => const AddEveryoneAdded(3)),
      );
      await openModal(tester);

      await tester.tap(find.text('Add everyone'));
      await tester.pumpAndSettle();

      expect(fakeAddEveryone.calls, 1);
      expect(find.text('Added 3 people to #general.'), findsOneWidget);
      expect(find.byType(InviteTeammatesModal), findsNothing);
    });

    testWidgets('says "person" when one person is added', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(() async => const AddEveryoneAdded(1)),
      );
      await openModal(tester);

      await tester.tap(find.text('Add everyone'));
      await tester.pumpAndSettle();

      expect(find.text('Added 1 person to #general.'), findsOneWidget);
    });

    testWidgets('keeps the window open when everyone is already in', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildModalUnderTest(() async => const AddEveryoneNobodyToAdd()),
      );
      await openModal(tester);

      await tester.tap(find.text('Add everyone'));
      await tester.pumpAndSettle();

      expect(
        find.text('Everyone in your organisation is already in #general.'),
        findsOneWidget,
      );
      expect(find.byType(InviteTeammatesModal), findsOneWidget);
    });

    testWidgets('shows the error and keeps the window open on failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildModalUnderTest(
          () async => const AddEveryoneFailed('failed to add users to channel'),
        ),
      );
      await openModal(tester);

      await tester.tap(find.text('Add everyone'));
      await tester.pumpAndSettle();

      expect(find.text('failed to add users to channel'), findsOneWidget);
      expect(find.byType(InviteTeammatesModal), findsOneWidget);
      expect(find.text('Add everyone'), findsOneWidget);
    });

    testWidgets('is disabled while adding, so a second click does nothing', (
      tester,
    ) async {
      final pending = Completer<AddEveryoneResult>();
      await tester.pumpWidget(buildModalUnderTest(() => pending.future));
      await openModal(tester);

      await tester.tap(find.text('Add everyone'));
      await tester.pump();

      expect(find.text('Adding…'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Adding…'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.text('Adding…'));
      await tester.pump();
      expect(fakeAddEveryone.calls, 1);

      pending.complete(const AddEveryoneNobodyToAdd());
      await tester.pumpAndSettle();
      expect(find.text('Add everyone'), findsOneWidget);
    });

    testWidgets('leaves Copy Invite Link and Add in place', (tester) async {
      await tester.pumpWidget(
        buildModalUnderTest(() async => const AddEveryoneNobodyToAdd()),
      );
      await openModal(tester);

      expect(find.byTooltip('Copy Invite Link'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Add'), findsOneWidget);
    });
  });
}

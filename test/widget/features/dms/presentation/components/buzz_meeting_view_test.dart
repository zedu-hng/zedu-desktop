import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeActiveCallNotifier extends ActiveCallNotifier {
  FakeActiveCallNotifier(
    super.ref, {
    required bool isFullPage,
    bool isMiniWindow = false,
  }) : _fakeState = ActiveCallState(
         status: CallStatus.active,
         remoteUserName: 'Ruby',
         isFullPage: isFullPage,
         isMiniWindow: isMiniWindow,
       );

  final ActiveCallState _fakeState;

  @override
  ActiveCallState get state => _fakeState;
}

Widget buildBuzzMeetingViewUnderTest({
  required bool isFullPage,
  bool isMiniWindow = false,
}) {
  return ProviderScope(
    overrides: [
      activeCallProvider.overrideWith(
        (ref) => FakeActiveCallNotifier(
          ref,
          isFullPage: isFullPage,
          isMiniWindow: isMiniWindow,
        ),
      ),
    ],
    // The compact view is a Positioned, so it needs a Stack ancestor.
    child: MaterialApp(
      home: Scaffold(body: Stack(children: const [BuzzMeetingView()])),
    ),
  );
}

void main() {
  group('BuzzMeetingView participant label', () {
    testWidgets('compact view shows "2 participants"', (tester) async {
      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: false));
      await tester.pump();

      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('2 participant'), findsNothing);
    });

    testWidgets('full-page view shows "2 participants"', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('2 participant'), findsNothing);
    });
  });

  group('BuzzMeetingView mini window controls', () {
    testWidgets('compact view offers keep-on-top, mute and leave controls', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBuzzMeetingViewUnderTest(isFullPage: false, isMiniWindow: true),
      );
      await tester.pump();

      expect(
        find.byTooltip('Stop keeping the mini window on top'),
        findsOneWidget,
      );
      expect(find.byTooltip('Mute'), findsOneWidget);
      expect(find.byTooltip('Leave call'), findsOneWidget);
    });

    testWidgets('full-page view can switch to the mini window', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      expect(find.byTooltip('Open mini window'), findsOneWidget);
    });
  });

  group('BuzzMeetingView share screen button', () {
    testWidgets('tells the user screen sharing is not available yet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildBuzzMeetingViewUnderTest(isFullPage: true));
      await tester.pump();

      const message = 'Screen sharing is not available yet.';
      expect(find.text(message), findsNothing);

      await tester.tap(find.byIcon(Icons.screen_share_outlined));
      await tester.pump();

      expect(find.text(message), findsOneWidget);

      // Let the toast's auto-dismiss timer finish.
      await tester.pump(const Duration(seconds: 10));
    });
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _MockChatHistory extends Mock implements ChatHistoryNotifier {}

class _MockXFile extends Mock implements XFile {}

const _historyKey = Key('conversation-history');

String _longDraft(int lines) => List.generate(
  lines,
  (index) => 'Line ${index + 1}: sample message text',
).join('\n');

Future<void> _pumpComposer(
  WidgetTester tester, {
  Size size = const Size(1100, 700),
  _MockChatHistory? history,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (history != null)
          chatHistoryProvider('test-channel').overrideWith((ref) => history),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: Column(
            children: [
              SizedBox(height: 56, child: Text('Conversation')),
              Expanded(
                child: SizedBox(
                  key: _historyKey,
                  width: double.infinity,
                  child: Text('Earlier messages'),
                ),
              ),
              DmMessageComposer(
                recipientName: '@teammate',
                channelId: 'test-channel',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(1100, 700), const Size(800, 480)]) {
    testWidgets('long drafts preserve conversation space at $size', (
      tester,
    ) async {
      await _pumpComposer(tester, size: size);
      final field = find.byType(TextField);
      await tester.enterText(field, 'Short message');
      await tester.pumpAndSettle();
      final shortHeight = tester.getSize(field).height;

      await tester.enterText(field, _longDraft(40));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final longHeight = tester.getSize(field).height;
      expect(longHeight, greaterThan(shortHeight));
      expect(tester.getSize(find.byKey(_historyKey)).height, greaterThan(100));
      expect(find.byIcon(Icons.send_rounded).hitTestable(), findsOneWidget);

      await tester.enterText(field, _longDraft(60));
      await tester.pumpAndSettle();
      expect(tester.getSize(field).height, longHeight);
      expect(tester.takeException(), isNull);

      await tester.enterText(field, 'Short again');
      await tester.pumpAndSettle();
      expect(tester.getSize(field).height, shortHeight);
    });
  }

  testWidgets('long draft scrolls inside the editor without losing text', (
    tester,
  ) async {
    await _pumpComposer(tester);
    final field = find.byType(TextField);
    final draft = _longDraft(60);
    await tester.enterText(field, draft);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: field, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    scrollable.position.jumpTo(0);
    await tester.pump();
    await tester.drag(field, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.widget<TextField>(field).controller!.text, draft);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sends the entire multiline draft and returns to compact height',
    (tester) async {
      final history = _MockChatHistory();
      when(
        () => history.sendMessage(any(), media: any(named: 'media')),
      ).thenAnswer((_) async {});
      await _pumpComposer(tester, history: history);
      final field = find.byType(TextField);
      final emptyHeight = tester.getSize(field).height;
      final draft = _longDraft(60);
      await tester.enterText(field, draft);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verify(
        () => history.sendMessage(draft, media: any(named: 'media')),
      ).called(1);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(tester.getSize(field).height, emptyHeight);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long draft keeps attachment preview and formatting usable', (
    tester,
  ) async {
    await _pumpComposer(tester, size: const Size(800, 480));
    final field = find.byType(TextField);
    final draft = _longDraft(60);
    await tester.enterText(field, draft);
    final composer = tester.state<DmMessageComposerState>(
      find.byType(DmMessageComposer),
    );
    final file = _MockXFile();
    when(() => file.name).thenReturn('sample.txt');
    when(file.length).thenAnswer((_) async => 1);
    await composer.addFiles([file]);
    await tester.pumpAndSettle();

    final controller = tester.widget<TextField>(field).controller!;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();
    await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
    await tester.pumpAndSettle();
    expect(controller.text, '**Line**${draft.substring(4)}');
    expect(find.text('sample.txt'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded).hitTestable(), findsOneWidget);
    expect(tester.getSize(find.byKey(_historyKey)).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class MockChatHistoryNotifier extends Mock implements ChatHistoryNotifier {}

const combinedFixtures = [
  (
    name: 'triple markers',
    draft: 'before ***test*** after',
    visible: 'before test after',
  ),
  (
    name: 'italic inside bold',
    draft: '**before *test* after**',
    visible: 'before test after',
  ),
  (
    name: 'bold inside italic',
    draft: '*before **test** after*',
    visible: 'before test after',
  ),
  (
    name: 'italic at the end of bold',
    draft: '**before *test***',
    visible: 'before test',
  ),
  (
    name: 'bold at the end of italic',
    draft: '*before **test***',
    visible: 'before test',
  ),
  (
    name: 'italic at the start of bold',
    draft: '***test* after**',
    visible: 'test after',
  ),
  (
    name: 'bold at the start of italic',
    draft: '***test** after*',
    visible: 'test after',
  ),
  (
    name: 'repeated bold markers',
    draft: 'before *****test***** after',
    visible: 'before test after',
  ),
];

Iterable<({String text, TextStyle style})> visibleTextRuns(
  InlineSpan span, [
  TextStyle inheritedStyle = const TextStyle(),
]) sync* {
  if (span is! TextSpan) return;
  final style = inheritedStyle.merge(span.style);
  if (span.text case final String text when text.isNotEmpty) {
    if (style.color != Colors.transparent) {
      yield (text: text, style: style);
    }
  }
  for (final child in span.children ?? <InlineSpan>[]) {
    yield* visibleTextRuns(child, style);
  }
}

Future<TextEditingController> pumpComposer(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: buildTestMaterialApp(
        const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: DmMessageComposer(
              recipientName: '@test',
              channelId: 'formatting-test',
            ),
          ),
        ),
      ),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField)).controller!;
}

InlineSpan composerPreview(WidgetTester tester) => tester
    .state<EditableTextState>(find.byType(EditableText))
    .renderEditable
    .text!;

void main() {
  group('DM composer combined formatting', () {
    for (final fixture in combinedFixtures) {
      testWidgets('renders ${fixture.name} and preserves editing offsets', (
        tester,
      ) async {
        final controller = await pumpComposer(tester);
        await tester.enterText(find.byType(TextField), fixture.draft);
        await tester.pump();

        final preview = composerPreview(tester);
        final runs = visibleTextRuns(preview).toList();
        expect(runs.map((run) => run.text).join(), fixture.visible);
        final word = runs.singleWhere((run) => run.text == 'test');
        expect(word.style.fontWeight, FontWeight.bold);
        expect(word.style.fontStyle, FontStyle.italic);
        expect(preview.toPlainText(), fixture.draft);
        expect(controller.selection.baseOffset, fixture.draft.length);
      });
    }

    testWidgets(
      'preserves literal stars in inline code and unmatched delimiters',
      (tester) async {
        await pumpComposer(tester);
        const draft = '`***literal***` and **unfinished';
        await tester.enterText(find.byType(TextField), draft);
        await tester.pump();
        final preview = composerPreview(tester);
        final runs = visibleTextRuns(preview).toList();
        expect(
          runs.map((run) => run.text).join(),
          '***literal*** and **unfinished',
        );
        expect(runs.first.style.fontFamily, 'monospace');
        expect(preview.toPlainText(), draft);
      },
    );

    testWidgets('renders italic selection inside a longer bold phrase', (
      tester,
    ) async {
      final controller = await pumpComposer(tester);
      await tester.enterText(find.byType(TextField), 'before test after');
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 17,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
      await tester.pump();
      controller.selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 13,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Italic (Ctrl+I)'));
      await tester.pump();

      final runs = visibleTextRuns(composerPreview(tester)).toList();
      expect(runs.map((run) => run.text).join(), 'before test after');
      final word = runs.singleWhere((run) => run.text == 'test');
      expect(word.style.fontWeight, FontWeight.bold);
      expect(word.style.fontStyle, FontStyle.italic);
      expect(controller.text, '**before *test* after**');
    });

    testWidgets('renders bold selection inside a longer italic phrase', (
      tester,
    ) async {
      final controller = await pumpComposer(tester);
      await tester.enterText(find.byType(TextField), 'before test after');
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 17,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Italic (Ctrl+I)'));
      await tester.pump();
      controller.selection = const TextSelection(
        baseOffset: 8,
        extentOffset: 12,
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
      await tester.pump();

      final runs = visibleTextRuns(composerPreview(tester)).toList();
      expect(runs.map((run) => run.text).join(), 'before test after');
      final word = runs.singleWhere((run) => run.text == 'test');
      expect(word.style.fontWeight, FontWeight.bold);
      expect(word.style.fontStyle, FontStyle.italic);
      expect(controller.text, '*before **test** after*');
    });

    for (final order in const [
      ['Bold (Ctrl+B)', 'Italic (Ctrl+I)'],
      ['Italic (Ctrl+I)', 'Bold (Ctrl+B)'],
    ]) {
      testWidgets('renders ${order.join(' then ')} without visible markers', (
        tester,
      ) async {
        final controller = await pumpComposer(tester);
        await tester.enterText(find.byType(TextField), 'before test after');
        controller.selection = const TextSelection(
          baseOffset: 7,
          extentOffset: 11,
        );
        await tester.pump();

        for (final tooltip in order) {
          await tester.tap(find.byTooltip(tooltip));
          await tester.pump();
        }

        final preview = composerPreview(tester);
        final runs = visibleTextRuns(preview).toList();
        expect(runs.map((run) => run.text).join(), 'before test after');
        final formattedWord = runs.singleWhere((run) => run.text == 'test');
        expect(formattedWord.style.fontWeight, FontWeight.bold);
        expect(formattedWord.style.fontStyle, FontStyle.italic);
        expect(controller.text, 'before ***test*** after');
        expect(controller.selection.textInside(controller.text), 'test');
        // Hidden markers must retain their character positions for editing.
        expect(preview.toPlainText(), controller.text);
      });
    }

    testWidgets('preserves independent styles beside combined formatting', (
      tester,
    ) async {
      await pumpComposer(tester);
      const draft = '**bold** *italic* ***both*** ~~strike~~ `code`';
      await tester.enterText(find.byType(TextField), draft);
      await tester.pump();

      final preview = composerPreview(tester);
      final runs = visibleTextRuns(preview).toList();
      TextStyle styleOf(String word) =>
          runs.singleWhere((run) => run.text == word).style;

      expect(
        runs.map((run) => run.text).join(),
        'bold italic both strike code',
      );
      expect(styleOf('bold').fontWeight, FontWeight.bold);
      expect(styleOf('bold').fontStyle, isNot(FontStyle.italic));
      expect(styleOf('italic').fontStyle, FontStyle.italic);
      expect(styleOf('italic').fontWeight, isNot(FontWeight.bold));
      expect(styleOf('both').fontWeight, FontWeight.bold);
      expect(styleOf('both').fontStyle, FontStyle.italic);
      expect(styleOf('strike').decoration, TextDecoration.lineThrough);
      expect(styleOf('code').fontFamily, 'monospace');
      expect(preview.toPlainText(), draft);
    });

    testWidgets('renders combined formatting across line breaks', (
      tester,
    ) async {
      final controller = await pumpComposer(tester);
      const draft = '***first\nsecond***';
      await tester.enterText(find.byType(TextField), draft);
      await tester.pump();

      final preview = composerPreview(tester);
      final run = visibleTextRuns(preview).single;
      expect(run.text, 'first\nsecond');
      expect(run.style.fontWeight, FontWeight.bold);
      expect(run.style.fontStyle, FontStyle.italic);
      expect(preview.toPlainText(), draft);
      expect(controller.selection.baseOffset, draft.length);
    });
  });

  group('DM message combined formatting', () {
    for (final messageCase in const [
      (name: 'sent', isMe: true, status: 'sent'),
      (name: 'failed', isMe: true, status: 'failed'),
      (name: 'incoming', isMe: false, status: null),
    ]) {
      for (final fixture in combinedFixtures) {
        testWidgets('${messageCase.name} bubble renders ${fixture.name}', (
          tester,
        ) async {
          final message = <String, dynamic>{
            'id': 'formatting-message',
            'content': fixture.draft,
            'created_at': '2026-10-18T12:00:00Z',
            'status': messageCase.status,
          };
          final history = MockChatHistoryNotifier();
          when(() => history.messages).thenReturn([message]);
          when(() => history.isLoading).thenReturn(false);
          when(() => history.hasMore).thenReturn(true);
          when(() => history.isMyMessage(message)).thenReturn(messageCase.isMe);
          when(() => history.currentUserName).thenReturn('You');
          when(() => history.currentUserAvatarUrl).thenReturn(null);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                chatHistoryProvider(
                  'formatting-test',
                ).overrideWith((_) => history),
              ],
              child: buildTestMaterialApp(
                Scaffold(
                  body: DmChatArea(
                    conversation: DmConversation(
                      channelId: 'formatting-test',
                      username: 'Test recipient',
                      participantId: 'recipient',
                      previewMessage: '',
                      unreadCount: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final bubble = tester.widget<RichText>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText() == fixture.visible,
            ),
          );
          expect(bubble.text.toPlainText(), fixture.visible);
          final formattedWord = visibleTextRuns(
            bubble.text,
          ).singleWhere((run) => run.text == 'test');
          expect(formattedWord.style.fontWeight, FontWeight.bold);
          expect(formattedWord.style.fontStyle, FontStyle.italic);
          expect(message['content'], fixture.draft);
        });
      }
    }
  });
}

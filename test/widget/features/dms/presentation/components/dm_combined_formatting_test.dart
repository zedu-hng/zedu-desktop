import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class _History extends Mock implements ChatHistoryNotifier {}

const _fixtures = {
  'before ***test*** after': 'before test after',
  '**before *test* after**': 'before test after',
  '*before **test** after*': 'before test after',
  '**before *test***': 'before test',
  '*before **test***': 'before test',
  '***test* after**': 'test after',
  '***test** after*': 'test after',
  'before *****test***** after': 'before test after',
  '***test\nsecond***': 'test\nsecond',
};

Iterable<TextSpan> _visible(InlineSpan span, [TextStyle? inherited]) sync* {
  if (span is! TextSpan) return;
  final style = (inherited ?? const TextStyle()).merge(span.style);
  if (span.text?.isNotEmpty == true && style.color != Colors.transparent) {
    yield TextSpan(text: span.text, style: style);
  }
  for (final child in span.children?.whereType<TextSpan>() ?? <TextSpan>[]) {
    yield* _visible(child, style);
  }
}

void _expectCombined(InlineSpan span, String expected) {
  final runs = _visible(span).toList();
  expect(runs.map((s) => s.text).join(), expected);
  final word = runs.firstWhere((s) => s.text!.contains('test'));
  expect(word.style?.fontWeight, FontWeight.bold);
  expect(word.style?.fontStyle, FontStyle.italic);
}

Future<TextEditingController> _pump(
  WidgetTester tester,
  String text, {
  String? status = 'sent',
}) async {
  final message = {'id': 'm', 'content': text, 'status': status};
  final history = _History();
  when(() => history.messages).thenReturn([message]);
  when(() => history.isLoading).thenReturn(false);
  when(() => history.hasMore).thenReturn(true);
  when(() => history.isMyMessage(message)).thenReturn(status != null);
  when(() => history.currentUserName).thenReturn('You');
  when(() => history.currentUserAvatarUrl).thenReturn(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [chatHistoryProvider('format').overrideWith((_) => history)],
      child: buildTestMaterialApp(
        Scaffold(
          body: DmChatArea(
            conversation: DmConversation(
              channelId: 'format',
              username: 'Test',
              participantId: 'test',
              previewMessage: '',
              unreadCount: 0,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.widget<TextField>(find.byType(TextField)).controller!;
}

InlineSpan _preview(WidgetTester tester) => tester
    .state<EditableTextState>(find.byType(EditableText))
    .renderEditable
    .text!;
Finder _bubble(String text) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText() == text,
);

void main() {
  for (final status in ['sent', 'failed', null]) {
    for (final entry in _fixtures.entries) {
      testWidgets('$status bubble and editor: ${entry.key}', (tester) async {
        final controller = await _pump(tester, entry.key, status: status);
        _expectCombined(
          tester.widget<RichText>(_bubble(entry.value)).text,
          entry.value,
        );
        await tester.enterText(find.byType(TextField), entry.key);
        await tester.pump();
        _expectCombined(_preview(tester), entry.value);
        expect(_preview(tester).toPlainText(), entry.key);
        expect(controller.selection.baseOffset, entry.key.length);
      });
    }
  }
  for (final boldFirst in [true, false]) {
    testWidgets('toolbar order boldFirst=$boldFirst', (tester) async {
      final controller = await _pump(tester, '');
      await tester.enterText(find.byType(TextField), 'before test after');
      controller.selection = const TextSelection(
        baseOffset: 7,
        extentOffset: 11,
      );
      final actions = ['Bold (Ctrl+B)', 'Italic (Ctrl+I)'];
      for (final action in boldFirst ? actions : actions.reversed) {
        await tester.tap(find.byTooltip(action));
        await tester.pump();
      }
      _expectCombined(_preview(tester), 'before test after');
      expect(controller.text, 'before ***test*** after');
      expect(controller.selection.textInside(controller.text), 'test');
      await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
      await tester.pump();
      _expectCombined(_preview(tester), 'before test after');
      expect(_preview(tester).toPlainText(), controller.text);
      await tester.enterText(find.byType(TextField), 'before test after');
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 17,
      );
      await tester.tap(find.byTooltip(actions[boldFirst ? 0 : 1]));
      await tester.pump();
      final start = boldFirst ? 9 : 8;
      controller.selection = TextSelection(
        baseOffset: start,
        extentOffset: start + 4,
      );
      await tester.tap(find.byTooltip(actions[boldFirst ? 1 : 0]));
      await tester.pump();
      _expectCombined(_preview(tester), 'before test after');
      expect(_preview(tester).toPlainText(), controller.text);
    });
  }
  for (final text in [
    '****',
    'a **** b',
    'my password is ********',
    '`***literal***` and **unfinished',
  ]) {
    testWidgets('preserves literal message text: $text', (tester) async {
      final expected = text.replaceAll('`', '');
      final controller = await _pump(tester, text);
      expect(_bubble(expected), findsOneWidget);
      if (text == '****') {
        await tester.tap(find.byType(TextField));
        await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
        await tester.pump();
        expect(controller.text, '****');
        expect(controller.selection, const TextSelection.collapsed(offset: 2));
        expect(_preview(tester).toPlainText(), '****');
        expect(_visible(_preview(tester)), isEmpty);
      }
    });
  }
}

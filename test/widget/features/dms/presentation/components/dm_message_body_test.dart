import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

bool _hasBoldText(InlineSpan span, String text) {
  if (span is TextSpan &&
      span.text?.contains(text) == true &&
      span.style?.fontWeight == FontWeight.bold) {
    return true;
  }

  return span is TextSpan &&
      (span.children?.any((child) => _hasBoldText(child, text)) ?? false);
}

void main() {
  for (final message in [
    'line one\nline two',
    '# not a heading, just a hashtag',
    '1. first point and 2. second',
    '> quoted text\n- ordinary line',
    'unmatched **delimiter',
    'ordinary_snake_case',
  ]) {
    testWidgets('preserves plain chat text: $message', (tester) async {
      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: DmMessageBody(
              content: message,
              textStyle: const TextStyle(fontSize: 14),
              accentColor: AppPalette.light.primary,
            ),
          ),
        ),
      );
      final spans = tester.widgetList<RichText>(find.byType(RichText));
      expect(
        spans.any((widget) => widget.text.toPlainText() == message),
        isTrue,
      );
    });
  }

  testWidgets('renders sent Markdown bold text as bold without delimiters', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: DmMessageBody(
            content: 'A **bold message**.',
            textStyle: const TextStyle(fontSize: 14),
            accentColor: AppPalette.light.primary,
          ),
        ),
      ),
    );

    final textSpans = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((richText) => richText.text);

    expect(
      textSpans.any((span) => span.toPlainText() == 'A bold message.'),
      isTrue,
    );
    expect(textSpans.any((span) => _hasBoldText(span, 'bold message')), isTrue);
  });
}

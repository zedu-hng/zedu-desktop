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

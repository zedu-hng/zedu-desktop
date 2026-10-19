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

  testWidgets('renders a web HTML message as text instead of an empty bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: DmMessageBody(
            content: '<p>hello <strong>there</strong></p>',
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
      textSpans.any((span) => span.toPlainText() == 'hello there'),
      isTrue,
    );
    expect(textSpans.any((span) => _hasBoldText(span, 'there')), isTrue);
  });

  testWidgets('renders a Markdown autolink instead of an empty bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: DmMessageBody(
            content: '<https://example.com>',
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
      textSpans.any(
        (span) => span.toPlainText().contains('https://example.com'),
      ),
      isTrue,
    );
  });

  group('DmMessageBody.toMarkdown', () {
    test('returns desktop Markdown unchanged', () {
      expect(
        DmMessageBody.toMarkdown('plain **md** text'),
        'plain **md** text',
      );
      expect(
        DmMessageBody.toMarkdown('[site](https://x.com) **b**'),
        '[site](https://x.com) **b**',
      );
    });

    test('keeps Markdown autolinks', () {
      expect(
        DmMessageBody.toMarkdown('<https://example.com>'),
        '<https://example.com>',
      );
      expect(
        DmMessageBody.toMarkdown('see <https://example.com> now'),
        'see <https://example.com> now',
      );
      expect(
        DmMessageBody.toMarkdown('mail <user@mail.com>'),
        'mail <user@mail.com>',
      );
    });

    test('handles self-closing and upper-case tags', () {
      expect(DmMessageBody.toMarkdown('<p>a<br/>b<br />c</p>'), 'a  \nb  \nc');
      expect(DmMessageBody.toMarkdown('<P>Up</P>'), 'Up');
    });

    test('unwraps a web paragraph', () {
      expect(DmMessageBody.toMarkdown('<p>damnnnn</p>'), 'damnnnn');
    });

    test('converts bold and italic', () {
      expect(
        DmMessageBody.toMarkdown(
          '<p><strong>bold</strong> and <em>it</em></p>',
        ),
        '**bold** and *it*',
      );
    });

    test('keeps paragraphs and line breaks', () {
      expect(DmMessageBody.toMarkdown('<p>one</p><p>two</p>'), 'one\n\ntwo');
      expect(DmMessageBody.toMarkdown('<p>a<br>b</p>'), 'a  \nb');
    });

    test('decodes entities and escapes a literal less-than', () {
      expect(
        DmMessageBody.toMarkdown('<p>Tom &amp; Jerry &lt;3</p>'),
        r'Tom & Jerry \<3',
      );
    });

    test('converts links, lists, strikethrough and code', () {
      expect(
        DmMessageBody.toMarkdown('<p><a href="https://x.com">site</a></p>'),
        '[site](https://x.com)',
      );
      expect(
        DmMessageBody.toMarkdown('<ul><li>a</li><li>b</li></ul>'),
        '- a\n- b',
      );
      expect(
        DmMessageBody.toMarkdown('<p><s>old</s> <code>x</code></p>'),
        '~~old~~ `x`',
      );
    });

    test('converts block quotes', () {
      expect(
        DmMessageBody.toMarkdown(
          '<blockquote><p>a</p><p><strong>b</strong></p></blockquote>'
          '<p>after</p>',
        ),
        '> a\n> **b**\n\nafter',
      );
    });

    test('leaves comparison signs that are not tags alone', () {
      expect(DmMessageBody.toMarkdown('1 < 2 and 3 > 2'), '1 < 2 and 3 > 2');
    });

    test('returns an empty string for an empty paragraph', () {
      expect(DmMessageBody.toMarkdown('<p></p>'), '');
    });
  });
}

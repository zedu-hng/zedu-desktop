import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('HtmlUtils.toPlainText', () {
    test('strips a paragraph tag', () {
      expect(HtmlUtils.toPlainText('<p>hello</p>'), 'hello');
    });

    test('leaves plain text unchanged', () {
      expect(HtmlUtils.toPlainText('hello there'), 'hello there');
    });

    test('returns an empty string for empty input', () {
      expect(HtmlUtils.toPlainText(''), '');
    });

    test('strips inline formatting tags', () {
      expect(
        HtmlUtils.toPlainText(
          '<p><strong>bold</strong> and <em>italic</em></p>',
        ),
        'bold and italic',
      );
    });

    test('turns paragraphs and line breaks into single spaces', () {
      expect(
        HtmlUtils.toPlainText('<p>first</p><p>second</p>third<br/>fourth'),
        'first second third fourth',
      );
    });

    test('decodes named entities', () {
      expect(
        HtmlUtils.toPlainText(
          '<p>Tom &amp; Jerry &lt;3 &quot;hi&quot; it&apos;s</p>',
        ),
        'Tom & Jerry <3 "hi" it\'s',
      );
    });

    test('decodes numeric and hex entities', () {
      expect(HtmlUtils.toPlainText('it&#39;s &#x1F600;'), 'it\'s 😀');
    });

    test('decodes entities in a single pass', () {
      expect(HtmlUtils.toPlainText('&amp;lt;b&amp;gt;'), '&lt;b&gt;');
    });

    test('keeps escaped markup as literal text', () {
      expect(
        HtmlUtils.toPlainText('<p>&lt;b&gt;not bold&lt;/b&gt;</p>'),
        '<b>not bold</b>',
      );
    });

    test('keeps a less-than sign that is not a tag', () {
      expect(HtmlUtils.toPlainText('1 < 2 and 3 > 2'), '1 < 2 and 3 > 2');
    });

    test('collapses whitespace and non-breaking spaces', () {
      expect(
        HtmlUtils.toPlainText('  <p>a&nbsp;&nbsp;b\n\n c </p>  '),
        'a b c',
      );
    });

    test('leaves unknown entities untouched', () {
      expect(HtmlUtils.toPlainText('&unknown; stays'), '&unknown; stays');
    });

    test('drops script and style content', () {
      expect(
        HtmlUtils.toPlainText(
          '<style>p{color:red}</style><p>safe</p><script>alert(1)</script>',
        ),
        'safe',
      );
    });
  });
}

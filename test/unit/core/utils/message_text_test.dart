import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('MessageText.stripHtml', () {
    test('returns an empty string for null or empty content', () {
      expect(MessageText.stripHtml(null), '');
      expect(MessageText.stripHtml(''), '');
    });

    test('drops tags and keeps the words', () {
      expect(
        MessageText.stripHtml('<p>Hello <strong>there</strong></p>'),
        'Hello there',
      );
    });

    test('drops tag attributes without leaking them into the text', () {
      expect(
        MessageText.stripHtml(
          '<p style="margin:0"><a href="https://zedu.chat">Zedu</a></p>',
        ),
        'Zedu',
      );
    });

    test('turns paragraph and line breaks into newlines', () {
      expect(MessageText.stripHtml('<p>one</p><p>two</p>'), 'one\ntwo');
      expect(MessageText.stripHtml('one<br />two'), 'one\ntwo');
    });

    test('decodes named and numeric entities', () {
      expect(
        MessageText.stripHtml('<p>Tom &amp; Jerry&nbsp;say &quot;hi&quot;</p>'),
        'Tom & Jerry say "hi"',
      );
      expect(MessageText.stripHtml('&#39;quoted&#39;'), "'quoted'");
      expect(MessageText.stripHtml('&#x27;hex&#x27;'), "'hex'");
    });

    test('leaves an unknown entity alone rather than dropping it', () {
      expect(MessageText.stripHtml('a &bogus; b'), 'a &bogus; b');
    });

    test('collapses the blank lines markup leaves behind', () {
      expect(MessageText.stripHtml('<p>a</p><p></p><p></p><p>b</p>'), 'a\n\nb');
    });

    test('a tag-name query no longer matches a plain paragraph', () {
      final body = MessageText.stripHtml('<p>Hello there</p>').toLowerCase();
      expect(body.contains('p'), isFalse);
      expect(body.contains('strong'), isFalse);
      expect(body.contains('hello'), isTrue);
    });

    test('stripping is stable when applied twice', () {
      const html = '<p>one</p><p>two &amp; three</p>';
      final once = MessageText.stripHtml(html);
      expect(MessageText.stripHtml(once), once);
    });
  });
}

import 'package:zedu/core/core.dart';

class DmMessageBody extends StatelessWidget {
  const DmMessageBody({
    super.key,
    required this.content,
    required this.textStyle,
    required this.accentColor,
  });

  final String content;
  final TextStyle textStyle;
  final Color accentColor;

  // Only real HTML elements count as tags. A Markdown autolink such as
  // `<https://example.com>` or `<user@mail.com>` also starts with `<` and a
  // letter, and must be left alone.
  static const String _htmlTags =
      'a|b|blockquote|br|code|del|div|em|h[1-6]|hr|i|img|li|mark|ol|p|pre|s|'
      'span|strike|strong|sub|sup|u|ul';
  static final RegExp _anyTag = RegExp(
    '</?($_htmlTags)(\\s[^>]*)?/?>',
    caseSensitive: false,
  );
  static final RegExp _scriptOrStyle = RegExp(
    r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>',
    caseSensitive: false,
  );
  static final RegExp _link = RegExp(
    r'''<a\b[^>]*?href\s*=\s*["']([^"']*)["'][^>]*>([\s\S]*?)</a\s*>''',
    caseSensitive: false,
  );
  static final RegExp _blockquote = RegExp(
    r'<blockquote\b[^>]*>([\s\S]*?)</blockquote\s*>',
    caseSensitive: false,
  );
  static final RegExp _quoteLineBreak = RegExp(
    r'<br\s*/?>|</?(p|div)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _listItemOpen = RegExp(
    r'<li\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _listItemClose = RegExp(
    r'</li\s*>',
    caseSensitive: false,
  );
  static final RegExp _list = RegExp(
    r'</?(ul|ol)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _block = RegExp(
    r'</?(p|div|h[1-6])\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _bold = RegExp(
    r'</?(strong|b)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _italic = RegExp(
    r'</?(em|i)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _strike = RegExp(
    r'</?(s|del|strike)\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _code = RegExp(r'</?code\b[^>]*>', caseSensitive: false);
  static final RegExp _remainingTag = RegExp(
    '</?($_htmlTags)(\\s[^>]*)?/?>',
    caseSensitive: false,
  );
  static final RegExp _entity = RegExp(
    r'&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);',
  );
  static final RegExp _blankLines = RegExp(r'[ \t]*\n[ \t]*\n\s*');

  static const String _quoteMarker = '\u0001';

  static const Map<String, String> _namedEntities = {
    'amp': '&',
    'lt': r'\<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
  };

  /// Converts message content to Markdown for [MarkdownBody].
  ///
  /// Messages sent from the desktop are already Markdown and are returned
  /// unchanged. Messages sent from Zedu web are HTML (e.g. `<p>hi</p>`),
  /// which `flutter_markdown` drops entirely, leaving an empty bubble.
  /// Those are converted to the equivalent Markdown so the text shows and
  /// bold, italic, strikethrough, code, links, lists, quotes and line
  /// breaks are kept.
  static String toMarkdown(String content) {
    if (!_anyTag.hasMatch(content)) return content;

    var text = content
        .replaceAll('\r\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(_scriptOrStyle, '')
        .replaceAllMapped(
          _link,
          (match) => '[${match.group(2)}](${match.group(1)})',
        )
        .replaceAllMapped(_blockquote, (match) {
          final lines = match
              .group(1)!
              .split(_quoteLineBreak)
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .map((line) => '$_quoteMarker$line');
          return '\n\n${lines.join('\n')}\n\n';
        })
        .replaceAll(_lineBreak, '  \n')
        .replaceAll(_listItemOpen, '\n- ')
        .replaceAll(_listItemClose, '')
        .replaceAll(_list, '\n\n')
        .replaceAll(_block, '\n\n')
        .replaceAll(_bold, '**')
        .replaceAll(_italic, '*')
        .replaceAll(_strike, '~~')
        .replaceAll(_code, '`')
        .replaceAll(_remainingTag, '');

    text = text.replaceAllMapped(_entity, (match) {
      final entity = match.group(1)!;
      if (entity.startsWith('#')) {
        final isHex = entity.startsWith('#x') || entity.startsWith('#X');
        final codePoint = int.tryParse(
          isHex ? entity.substring(2) : entity.substring(1),
          radix: isHex ? 16 : 10,
        );
        if (codePoint == null || codePoint < 1 || codePoint > 0x10FFFF) {
          return match.group(0)!;
        }
        final char = String.fromCharCode(codePoint);
        return char == '<' ? r'\<' : char;
      }
      return _namedEntities[entity.toLowerCase()] ?? match.group(0)!;
    });

    return text
        .replaceAll(_blankLines, '\n\n')
        .trim()
        .replaceAll(_quoteMarker, '> ');
  }

  @override
  Widget build(BuildContext context) {
    final markdownContent = toMarkdown(content);
    // Ensure inline **bold** markdown renders as bold. flutter_markdown in this
    // version may not reliably render inline **bold** syntax, so convert it to
    // HTML <strong> which is always supported.
    final renderContent = markdownContent.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*', dotAll: true),
      (match) => '<strong>${match.group(1)}</strong>',
    );
    return MarkdownBody(
      data: renderContent,
      styleSheet: MarkdownStyleSheet(
        p: textStyle,
        strong: textStyle.copyWith(fontWeight: FontWeight.bold),
        em: textStyle.copyWith(fontStyle: FontStyle.italic),
        del: textStyle.copyWith(decoration: TextDecoration.lineThrough),
        code: textStyle.copyWith(
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: accentColor.withValues(alpha: 0.1),
          color: accentColor,
        ),
      ),
    );
  }
}

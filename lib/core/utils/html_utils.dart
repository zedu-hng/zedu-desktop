/// Helpers for showing HTML message content as plain text.
abstract final class HtmlUtils {
  static final RegExp _scriptOrStyle = RegExp(
    r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>',
    caseSensitive: false,
  );
  static final RegExp _blockBoundary = RegExp(
    r'<br\s*/?>|</(p|div|li|h[1-6]|blockquote|pre|tr)\s*>',
    caseSensitive: false,
  );
  static final RegExp _tag = RegExp(r'</?[a-zA-Z!][^>]*>');
  static final RegExp _entity = RegExp(
    r'&(#[xX][0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);',
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  static const Map<String, String> _namedEntities = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
  };

  /// Converts an HTML snippet such as `<p>Hello &amp; welcome</p>` into
  /// single-line plain text (`Hello & welcome`).
  ///
  /// Block elements and line breaks become spaces, tags are removed,
  /// entities are decoded in a single pass (so `&amp;lt;` stays `&lt;`),
  /// and runs of whitespace collapse to one space. Plain text without tags
  /// or entities is returned unchanged apart from trimming.
  static String toPlainText(String html) {
    if (html.isEmpty) return html;

    final withoutTags = html
        .replaceAll(_scriptOrStyle, '')
        .replaceAll(_blockBoundary, ' ')
        .replaceAll(_tag, '');

    final decoded = withoutTags.replaceAllMapped(_entity, (match) {
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
        return String.fromCharCode(codePoint);
      }
      return _namedEntities[entity.toLowerCase()] ?? match.group(0)!;
    });

    return decoded.replaceAll(_whitespace, ' ').trim();
  }
}

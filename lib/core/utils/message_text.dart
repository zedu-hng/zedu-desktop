/// Helpers for message bodies, which the API returns as HTML.
///
/// Message bubbles render their own markup, but anywhere the app needs the
/// words a person actually typed (search results, previews) the HTML has to
/// be flattened first: showing `<p>` tags and matching on `p`, `br` or
/// `strong` makes a search useless.
class MessageText {
  MessageText._();

  /// Block-level tags that end a line in the rendered message.
  static final RegExp _lineBreaks = RegExp(
    r'<\s*(br|/p|/div|/li|/h[1-6])\s*/?\s*>',
    caseSensitive: false,
  );

  static final RegExp _tags = RegExp(r'<[^>]*>');

  static final RegExp _entities = RegExp(
    r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);',
  );

  static const Map<String, String> _namedEntities = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'ndash': '–',
    'mdash': '—',
    'hellip': '…',
    'lsquo': '‘',
    'rsquo': '’',
    'ldquo': '“',
    'rdquo': '”',
  };

  /// The plain text of an HTML message body: tags dropped, block breaks kept
  /// as newlines, entities decoded and surrounding whitespace trimmed.
  static String stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';

    var text = html
        .replaceAll(_lineBreaks, '\n')
        .replaceAll(_tags, '')
        .replaceAllMapped(_entities, (match) => _decode(match.group(1)!));

    // Collapse the runs of blank space markup leaves behind, but keep the
    // paragraph spacing a person can see in the bubble.
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// The largest value a Unicode code point can take.
  static const int _maxCodePoint = 0x10FFFF;

  static String _decode(String entity) {
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      return _decodeCodePoint(
        int.tryParse(entity.substring(2), radix: 16),
        entity,
      );
    }
    if (entity.startsWith('#')) {
      return _decodeCodePoint(int.tryParse(entity.substring(1)), entity);
    }
    return _namedEntities[entity.toLowerCase()] ?? '&$entity;';
  }

  /// Decodes [codePoint], or keeps the entity as written when it is not one.
  ///
  /// Senders put arbitrary text in a message body, and `String.fromCharCode`
  /// throws above the Unicode range, so a bad entity must stay literal rather
  /// than take the caller down with it.
  static String _decodeCodePoint(int? codePoint, String entity) {
    if (codePoint == null || codePoint < 0 || codePoint > _maxCodePoint) {
      return '&$entity;';
    }
    return String.fromCharCode(codePoint);
  }
}

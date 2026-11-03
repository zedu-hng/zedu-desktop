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

  static String _decode(String entity) {
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      final code = int.tryParse(entity.substring(2), radix: 16);
      return code == null ? '&$entity;' : String.fromCharCode(code);
    }
    if (entity.startsWith('#')) {
      final code = int.tryParse(entity.substring(1));
      return code == null ? '&$entity;' : String.fromCharCode(code);
    }
    return _namedEntities[entity.toLowerCase()] ?? '&$entity;';
  }
}

/// A message pinned in a channel, as returned by
/// `GET /channels/pin/{channel_id}` (Ziki #17).
class PinnedMessage {
  /// The reply's id for a pinned reply, otherwise the thread id.
  final String id;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  const PinnedMessage({
    required this.id,
    required this.senderName,
    required this.text,
    this.createdAt,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) {
    String? nonEmpty(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return PinnedMessage(
      id: nonEmpty(json['message_id']) ?? nonEmpty(json['thread_id']) ?? '',
      senderName:
          nonEmpty(json['full_name']) ??
          nonEmpty(json['username']) ??
          nonEmpty(json['email']) ??
          'Unknown',
      text: _plainText(json['message']?.toString() ?? ''),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }

  /// Messages sent from the web app arrive as HTML (`<p>hi</p>`).
  static String _plainText(String raw) {
    var text = raw.replaceAll(
      RegExp(r'<\s*(br|/p|/div|/li)\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    const entities = {
      '&nbsp;': ' ',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      // Last, so '&amp;lt;' stays '&lt;' instead of being decoded twice.
      '&amp;': '&',
    };
    entities.forEach((entity, value) => text = text.replaceAll(entity, value));
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n')
        .trim();
  }
}

class SearchResultItem {
  final String id;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final String timestamp;
  final String? conversationId;
  final String? conversationTitle;
  final String conversationType; // 'channel', 'dm', 'group_dm'
  final String category; // 'message', 'channel', 'file'

  const SearchResultItem({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    required this.timestamp,
    this.conversationId,
    this.conversationTitle,
    this.conversationType = 'channel',
    this.category = 'message',
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    // 1. Resolve ID
    final id =
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['message_id']?.toString() ??
        '';

    // 2. Resolve Content / Text
    final content =
        json['content'] as String? ??
        json['text'] as String? ??
        json['message'] as String? ??
        json['body'] as String? ??
        json['name'] as String? ??
        json['title'] as String? ??
        '';

    // 3. Resolve Author / User
    String authorName = 'Member';
    String? authorAvatar;

    if (json['author'] is Map<String, dynamic>) {
      final author = json['author'] as Map<String, dynamic>;
      authorName =
          author['name'] as String? ??
          author['username'] as String? ??
          author['email'] as String? ??
          'Member';
      authorAvatar =
          author['avatar_url'] as String? ??
          author['profile_picture'] as String?;
    } else if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      authorName =
          user['name'] as String? ??
          user['username'] as String? ??
          user['email'] as String? ??
          'Member';
      authorAvatar =
          user['avatar_url'] as String? ?? user['profile_picture'] as String?;
    } else if (json['author_name'] is String) {
      authorName = json['author_name'] as String;
    } else if (json['username'] is String) {
      authorName = json['username'] as String;
    }

    // 4. Resolve Timestamp
    String formattedTime = 'Recently';
    final rawTime =
        json['created_at'] ??
        json['timestamp'] ??
        json['createdAt'] ??
        json['date'];
    if (rawTime is String) {
      try {
        final parsed = DateTime.parse(rawTime).toLocal();
        final now = DateTime.now();
        final diff = now.difference(parsed);

        if (diff.inMinutes < 1) {
          formattedTime = 'Just now';
        } else if (diff.inMinutes < 60) {
          formattedTime = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          formattedTime = '${diff.inHours}h ago';
        } else if (diff.inDays == 1) {
          formattedTime = 'Yesterday';
        } else if (diff.inDays < 7) {
          formattedTime = '${diff.inDays}d ago';
        } else {
          formattedTime = '${parsed.day}/${parsed.month}/${parsed.year}';
        }
      } catch (_) {
        formattedTime = rawTime;
      }
    }

    // 5. Resolve Conversation
    final conversationId =
        json['conversation_id']?.toString() ??
        json['channel_id']?.toString() ??
        json['dm_id']?.toString() ??
        json['recipient_id']?.toString();

    final channel = json['channel'];
    final channelName = channel is Map<String, dynamic>
        ? channel['name'] as String?
        : null;

    final conversationTitle =
        json['conversation_title'] as String? ??
        json['channel_name'] as String? ??
        channelName;

    final rawType =
        json['type'] as String? ??
        json['conversation_type'] as String? ??
        'channel';

    final category =
        json['category'] as String? ??
        (json['file_url'] != null
            ? 'file'
            : (json['is_channel'] == true ? 'channel' : 'message'));

    return SearchResultItem(
      id: id,
      content: content,
      authorName: authorName,
      authorAvatar: authorAvatar,
      timestamp: formattedTime,
      conversationId: conversationId,
      conversationTitle: conversationTitle,
      conversationType: rawType,
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'timestamp': timestamp,
      'conversation_id': conversationId,
      'conversation_title': conversationTitle,
      'conversation_type': conversationType,
      'category': category,
    };
  }
}

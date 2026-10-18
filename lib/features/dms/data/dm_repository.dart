import 'package:zedu/core/core.dart';

import '../domain/dm_conversation.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 20;

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  Future<List<DmConversation>> getConversations({
    required String orgId,
    int page = 1,
    bool recentDm = false,
    String? search,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/organisations/$orgId/dms',
      queryParameters: {
        'page': page,
        'limit': pageSize,
        'recent_dm': recentDm,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.data;
    final rawList = data['data'];
    final list = (rawList is List ? rawList : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DmConversation.fromJson)
        .toList();

    list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    return list;
  }

  /// Loads one page of a DM's history, newest first.
  ///
  /// DM history lives on the DM threads route, the same one the web app
  /// uses. `/channels/:id/messages` rejects DM channels with a 400.
  Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/dms/channels/$channelId/threads',
      queryParameters: {'page': page, 'limit': pageSize},
    );

    final threads = response.data['data'];
    if (threads is! List) return const [];

    return threads
        .whereType<Map<dynamic, dynamic>>()
        .map((thread) => threadToMessage(Map<String, dynamic>.from(thread)))
        .toList();
  }

  /// Maps a DM thread to the message shape the chat UI reads: the thread's
  /// `thread_id` becomes `id` and its `message` text becomes `content`.
  /// Every other field (`user_id`, `username`, `created_at`, `media`, ...)
  /// is kept as it is.
  static Map<String, dynamic> threadToMessage(Map<String, dynamic> thread) {
    return {
      ...thread,
      'id': thread['id'] ?? thread['thread_id'],
      'content': thread['content'] ?? thread['message'] ?? '',
    };
  }

  Future<void> sendMessage(
    String channelId,
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      path: '/channels/$channelId/messages',
      data: {
        "content": content,
        if (media != null && media.isNotEmpty)
          "media": media.map(_mediaPayloadFromFile).toList(),
        ...?(mentions != null ? {'mentions': mentions} : null),
      },
    );
  }

  Map<String, dynamic> _mediaPayloadFromFile(XFile file) {
    return {
      'name': file.name,
      'path': file.path,
      if (file.mimeType != null) 'mime_type': file.mimeType,
    };
  }

  Future<void> editMessage(
    String channelId, {
    required String content,
    String? threadId,
    List<Map<String, dynamic>>? media,
    List<Map<String, dynamic>>? mentions,
  }) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/dms/messages/$channelId',
      data: {
        'content': content,
        ...?(threadId != null ? {'thread_id': threadId} : null),
        ...?(media != null ? {'media': media} : null),
        ...?(mentions != null ? {'mentions': mentions} : null),
      },
    );
  }
}

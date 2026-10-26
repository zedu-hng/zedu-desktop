import 'package:zedu/core/core.dart';

import '../../domain/repositories/search_repository.dart';
import '../models/search_result_item.dart';

class SearchRepositoryImpl implements SearchRepository {
  final ApiBaseService apiBaseService;

  SearchRepositoryImpl({required this.apiBaseService});

  @override
  Future<Result<List<SearchResultItem>>> search({
    required String query,
    required String orgId,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // zedu-be serves organisation search at /search/organisation/:orgId and
      // reads only `query` (filters such as `from:` go inside the query), so
      // page, limit and category are not sent.
      final response = await apiBaseService.get<Map<String, dynamic>>(
        path: '/search/organisation/$orgId',
        queryParameters: {'query': query},
      );

      final groups = response.data['data'];
      final list = <SearchResultItem>[
        if (groups is List<dynamic>)
          for (final group in groups.whereType<Map<String, dynamic>>())
            ..._resultsFrom(group),
      ];

      return Success(list);
    } on ApiFailure catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ApiFailure(message: e.toString()));
    }
  }

  /// zedu-be returns one entry per author and conversation, shaped like
  /// `{user: {user_id, user_name, avatar_url}, channel: {channel_id,
  /// channel_name}, messages: [{message_id, message, timestamp}]}`.
  /// Each matching message becomes one result row.
  static Iterable<SearchResultItem> _resultsFrom(Map<String, dynamic> group) {
    final user = group['user'];
    final channel = group['channel'];
    final messages = group['messages'];
    if (messages is! List<dynamic>) return const [];

    final author = user is Map<String, dynamic>
        ? user
        : const <String, dynamic>{};
    final conversation = channel is Map<String, dynamic>
        ? channel
        : const <String, dynamic>{};

    return messages.whereType<Map<String, dynamic>>().map(
      (message) => SearchResultItem(
        id: message['message_id']?.toString() ?? '',
        content: message['message']?.toString() ?? '',
        authorName: _textOrNull(author['user_name']) ?? 'Member',
        authorAvatar: _textOrNull(author['avatar_url']),
        timestamp: message['timestamp']?.toString() ?? '',
        conversationId: _textOrNull(conversation['channel_id']),
        conversationTitle: _textOrNull(conversation['channel_name']),
      ),
    );
  }

  static String? _textOrNull(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : text;
  }
}

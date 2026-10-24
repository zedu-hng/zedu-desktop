import '../../../helpers/helpers.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'package:zedu/features/home/data/repositories/search_repository_impl.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('SearchResultItem', () {
    test('parses correctly with full JSON data', () {
      final json = {
        'id': 'msg_123',
        'content': 'Meeting tomorrow at 10am',
        'author': {
          'name': 'Faith Dombe',
          'avatar_url': 'https://example.com/avatar.png',
        },
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'conversation_id': 'channel_general',
        'channel_name': 'general',
        'type': 'channel',
        'category': 'message',
      };

      final item = SearchResultItem.fromJson(json);

      expect(item.id, 'msg_123');
      expect(item.content, 'Meeting tomorrow at 10am');
      expect(item.authorName, 'Faith Dombe');
      expect(item.authorAvatar, 'https://example.com/avatar.png');
      expect(item.timestamp, '5m ago');
      expect(item.conversationId, 'channel_general');
      expect(item.conversationTitle, 'general');
      expect(item.conversationType, 'channel');
      expect(item.category, 'message');
    });

    test('falls back gracefully on missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'msg_456',
        'text': 'Assignment submission deadline',
      };

      final item = SearchResultItem.fromJson(json);

      expect(item.id, 'msg_456');
      expect(item.content, 'Assignment submission deadline');
      expect(item.authorName, 'Member');
      expect(item.authorAvatar, isNull);
      expect(item.timestamp, 'Recently');
      expect(item.conversationId, isNull);
    });

    test('toJson produces valid map matching fields', () {
      const item = SearchResultItem(
        id: '1',
        content: 'Hello world',
        authorName: 'Alex',
        timestamp: 'Just now',
        conversationId: 'c1',
        conversationTitle: 'dev',
      );

      final map = item.toJson();
      expect(map['id'], '1');
      expect(map['content'], 'Hello world');
      expect(map['author_name'], 'Alex');
      expect(map['conversation_title'], 'dev');
    });
  });

  group('SearchRepositoryImpl', () {
    late MockApiBaseService mockApiService;
    late SearchRepositoryImpl repository;

    setUp(() {
      mockApiService = MockApiBaseService();
      repository = SearchRepositoryImpl(apiBaseService: mockApiService);
    });

    test(
      'returns Success<List<SearchResultItem>> when API returns search results',
      () async {
        final mockData = {
          'status': 'success',
          'data': [
            {
              'id': 'msg_001',
              'content': 'Found discussion about flutter desktop',
              'author': {'name': 'Faith Dombe'},
              'channel_name': 'desktop-dev',
              'conversation_id': 'chan_1',
            },
            {
              'id': 'msg_002',
              'content': 'Bug report for search panel',
              'author': {'name': 'Mark Essien'},
              'channel_name': 'general',
              'conversation_id': 'chan_2',
            },
          ],
        };

        when(
          () => mockApiService.get<Map<String, dynamic>>(
            path: any(named: 'path'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel(data: mockData, statusCode: 200),
        );

        final result = await repository.search(
          query: 'desktop',
          orgId: 'org_123',
        );

        expect(result, isA<Success<List<SearchResultItem>>>());
        final list = (result as Success<List<SearchResultItem>>).value;
        expect(list.length, 2);
        expect(list[0].id, 'msg_001');
        expect(list[0].authorName, 'Faith Dombe');
        expect(list[1].authorName, 'Mark Essien');
      },
    );

    test('returns Failure when API request throws ApiFailure', () async {
      when(
        () => mockApiService.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        ApiFailure(
          message: 'Search service temporarily unavailable',
          statusCode: 503,
        ),
      );

      final result = await repository.search(query: 'error', orgId: 'org_123');

      expect(result, isA<Failure<List<SearchResultItem>>>());
      final failure = result as Failure<List<SearchResultItem>>;
      expect(failure.error.message, 'Search service temporarily unavailable');
    });
  });
}

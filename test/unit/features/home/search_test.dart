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
      'calls zedu-be search route and maps each message to a result',
      () async {
        // Shaped like zedu-be's GET /search/organisation/:orgId response.
        final mockData = {
          'status': 'success',
          'data': [
            {
              'user': {
                'user_id': 'u-faith',
                'user_name': 'Faith Dombe',
                'avatar_url': 'https://example.com/faith.png',
              },
              'channel': {
                'channel_id': 'chan_1',
                'channel_name': 'desktop-dev',
              },
              'messages': [
                {
                  'message_id': 'msg_001',
                  'message': 'Found discussion about flutter desktop',
                  'timestamp': '2026-10-20T10:00:00Z',
                },
                {
                  'message_id': 'msg_002',
                  'message': 'More on the desktop search panel',
                  'timestamp': '2026-10-20T11:00:00Z',
                },
              ],
              'thread': null,
            },
            {
              'user': {
                'user_id': 'u-mark',
                'user_name': 'Mark Essien',
                'avatar_url': '',
              },
              'channel': {'channel_id': 'chan_2', 'channel_name': 'general'},
              'messages': [
                {
                  'message_id': 'msg_003',
                  'message': 'Bug report for desktop search',
                  'timestamp': '2026-10-21T09:30:00Z',
                },
              ],
              'thread': null,
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
          category: 'message',
        );

        final captured = verify(
          () => mockApiService.get<Map<String, dynamic>>(
            path: captureAny(named: 'path'),
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured;
        expect(captured[0], '/search/organisation/org_123');
        expect(captured[1], {'query': 'desktop'});

        expect(result, isA<Success<List<SearchResultItem>>>());
        final list = (result as Success<List<SearchResultItem>>).value;
        expect(list.map((item) => item.id), ['msg_001', 'msg_002', 'msg_003']);

        final first = list[0];
        expect(first.content, 'Found discussion about flutter desktop');
        expect(first.authorName, 'Faith Dombe');
        expect(first.authorAvatar, 'https://example.com/faith.png');
        expect(first.timestamp, '2026-10-20T10:00:00Z');
        expect(first.conversationId, 'chan_1');
        expect(first.conversationTitle, 'desktop-dev');

        expect(list[2].authorName, 'Mark Essien');
        expect(list[2].authorAvatar, isNull);
        expect(list[2].conversationTitle, 'general');
      },
    );

    test('returns an empty list when nothing matches', () async {
      when(
        () => mockApiService.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel(
          data: {'status': 'success', 'data': <dynamic>[]},
          statusCode: 200,
        ),
      );

      final result = await repository.search(query: 'nothing', orgId: 'org_123');

      expect(result, isA<Success<List<SearchResultItem>>>());
      expect((result as Success<List<SearchResultItem>>).value, isEmpty);
    });

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

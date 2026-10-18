import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  late MockApiBaseService api;
  late DmRepository repository;

  setUp(() {
    api = MockApiBaseService();
    repository = DmRepository(api);
  });

  void stubThreads(Map<String, dynamic> body) {
    when(
      () => api.get<Map<String, dynamic>>(
        path: any(named: 'path'),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async =>
          ApiResponseModel<Map<String, dynamic>>(data: body, statusCode: 200),
    );
  }

  group('DmRepository.getMessages', () {
    test('loads history from the DM threads route', () async {
      stubThreads({'data': <dynamic>[]});

      await repository.getMessages('ch-1', page: 2);

      verify(
        () => api.get<Map<String, dynamic>>(
          path: '/dms/channels/ch-1/threads',
          queryParameters: {'page': 2, 'limit': DmRepository.pageSize},
        ),
      ).called(1);
    });

    test('maps each thread to the message shape the chat reads', () async {
      stubThreads({
        'data': [
          {
            'thread_id': 'thread-1',
            'message': '<p>hello</p>',
            'user_id': 'user-2',
            'username': 'test200hundred',
            'created_at': '2026-10-16T19:19:04Z',
          },
        ],
      });

      final messages = await repository.getMessages('ch-1');

      expect(messages, hasLength(1));
      expect(messages.single['id'], 'thread-1');
      expect(messages.single['content'], '<p>hello</p>');
      expect(messages.single['user_id'], 'user-2');
      expect(messages.single['username'], 'test200hundred');
      expect(messages.single['created_at'], '2026-10-16T19:19:04Z');
    });

    test('returns an empty list when data is not a list', () async {
      stubThreads({'data': null});

      expect(await repository.getMessages('ch-1'), isEmpty);
    });
  });

  group('DmRepository.threadToMessage', () {
    test('keeps an existing id and content', () {
      final message = DmRepository.threadToMessage({
        'id': 'message-1',
        'thread_id': 'thread-1',
        'content': 'from content',
        'message': 'from message',
      });

      expect(message['id'], 'message-1');
      expect(message['content'], 'from content');
    });

    test('uses an empty string when the thread has no text', () {
      final message = DmRepository.threadToMessage({'thread_id': 'thread-1'});

      expect(message['content'], '');
    });
  });
}

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class _MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('ChannelRemoteDataSourceImpl.fetchPinnedMessages (Ziki #17)', () {
    late _MockApiBaseService api;
    late ChannelRemoteDataSourceImpl datasource;

    setUp(() {
      api = _MockApiBaseService();
      datasource = ChannelRemoteDataSourceImpl(apiBaseService: api);
    });

    void stub(Object? data) {
      when(
        () => api.get<Map<String, dynamic>>(path: '/channels/pin/ch-1'),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {'data': data},
          statusCode: 200,
        ),
      );
    }

    test('reads the pinned messages from GET /channels/pin/{id}', () async {
      stub([
        {
          'message_id': 'm1',
          'thread_id': 't1',
          'message': 'Release is on Friday',
          'full_name': 'Ada Lovelace',
          'username': 'ada',
          'created_at': '2026-11-05T10:30:00Z',
        },
      ]);

      final result = await datasource.fetchPinnedMessages('ch-1');

      expect(result, hasLength(1));
      expect(result.single.id, 'm1');
      expect(result.single.senderName, 'Ada Lovelace');
      expect(result.single.text, 'Release is on Friday');
      expect(result.single.createdAt, isNotNull);
      verify(
        () => api.get<Map<String, dynamic>>(path: '/channels/pin/ch-1'),
      ).called(1);
    });

    test('a pinned thread falls back to its thread id and username', () async {
      stub([
        {
          'message_id': '',
          'thread_id': 't2',
          'message': 'hi',
          'username': 'bo',
        },
      ]);

      final result = await datasource.fetchPinnedMessages('ch-1');

      expect(result.single.id, 't2');
      expect(result.single.senderName, 'bo');
    });

    test('turns the HTML of web messages into plain text', () async {
      stub([
        {'thread_id': 't3', 'message': '<p>Hello <strong>team</strong></p>'},
      ]);

      final result = await datasource.fetchPinnedMessages('ch-1');

      expect(result.single.text, isNot(contains('<')));
      expect(result.single.text, contains('Hello'));
      expect(result.single.text, contains('team'));
      expect(result.single.senderName, 'Unknown');
    });

    test('no data means no pinned messages', () async {
      stub(null);

      expect(await datasource.fetchPinnedMessages('ch-1'), isEmpty);
    });
  });
}

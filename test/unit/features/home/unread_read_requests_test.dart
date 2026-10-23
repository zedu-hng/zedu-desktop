import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockReadApi extends Mock implements ApiBaseService {}

void main() {
  for (final isDm in [true, false]) {
    test(
      'persists the last-read marker for a conversation (DM: $isDm)',
      () async {
        final api = MockReadApi();
        when(
          () => api.get<Map<String, dynamic>>(
            path: '/threads/channels/c1',
            queryParameters: {'page': 1, 'limit': 1},
          ),
        ).thenAnswer(
          (_) async => const ApiResponseModel<Map<String, dynamic>>(
            statusCode: 200,
            data: {},
          ),
        );
        if (isDm) {
          await DmRepository(api).markRead('c1');
        } else {
          final repository = ChannelRepositoryImpl(
            remoteDataSource: ChannelRemoteDataSourceImpl(apiBaseService: api),
          );
          expect(await repository.markRead('c1'), isA<Success<void>>());
        }
        verify(
          () => api.get<Map<String, dynamic>>(
            path: '/threads/channels/c1',
            queryParameters: {'page': 1, 'limit': 1},
          ),
        ).called(1);
      },
    );
  }
}

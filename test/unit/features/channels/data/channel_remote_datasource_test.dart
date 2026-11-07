import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('ChannelRemoteDataSourceImpl.toggleStarChannel', () {
    late MockApiBaseService mockApi;
    late ChannelRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = ChannelRemoteDataSourceImpl(apiBaseService: mockApi);
    });

    void stubResponse(Map<String, dynamic> body) {
      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/organisations/org-1/channels/ch-1/star',
        ),
      ).thenAnswer(
        (_) async =>
            ApiResponseModel<Map<String, dynamic>>(data: body, statusCode: 200),
      );
    }

    test('posts to the channel star path and returns the new state', () async {
      stubResponse({
        'data': {'is_starred': true, 'channel_id': 'ch-1'},
      });

      final starred = await datasource.toggleStarChannel(
        orgId: 'org-1',
        channelId: 'ch-1',
      );

      expect(starred, isTrue);
      verify(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/organisations/org-1/channels/ch-1/star',
        ),
      ).called(1);
    });

    test('returns false when the channel was unstarred', () async {
      stubResponse({
        'data': {'is_starred': false, 'channel_id': 'ch-1'},
      });

      expect(
        await datasource.toggleStarChannel(orgId: 'org-1', channelId: 'ch-1'),
        isFalse,
      );
    });

    test('fails when the response has no star state', () async {
      stubResponse({'data': null});

      await expectLater(
        datasource.toggleStarChannel(orgId: 'org-1', channelId: 'ch-1'),
        throwsException,
      );
    });

    test('passes a request failure on to the caller', () async {
      const failure = ApiFailure(
        message: 'channel not found',
        kind: ApiFailureKind.notFound,
      );
      when(
        () => mockApi.post<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenThrow(failure);

      await expectLater(
        datasource.toggleStarChannel(orgId: 'org-1', channelId: 'ch-1'),
        throwsA(failure),
      );
    });
  });

  group('ChannelRemoteDataSourceImpl.updateChannelTopicOrDescription', () {
    late MockApiBaseService mockApi;
    late ChannelRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = ChannelRemoteDataSourceImpl(apiBaseService: mockApi);
    });

    void stubPatch(Map<String, dynamic> body) {
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: '/channels/ch-1',
          data: body,
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {'status': 'success'},
          statusCode: 200,
        ),
      );
    }

    test('saves the topic with PATCH /channels/{id}', () async {
      stubPatch({'topic': 'Release notes'});

      await datasource.updateChannelTopicOrDescription(
        channelId: 'ch-1',
        topic: 'Release notes',
      );

      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          path: '/channels/ch-1',
          data: {'topic': 'Release notes'},
        ),
      ).called(1);
    });

    test('saves the description with PATCH /channels/{id}', () async {
      stubPatch({'description': 'Where we plan launches'});

      await datasource.updateChannelTopicOrDescription(
        channelId: 'ch-1',
        description: 'Where we plan launches',
      );

      verify(
        () => mockApi.patch<Map<String, dynamic>>(
          path: '/channels/ch-1',
          data: {'description': 'Where we plan launches'},
        ),
      ).called(1);
    });
  });
}

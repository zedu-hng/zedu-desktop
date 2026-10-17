import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

Map<String, dynamic> _invite(String id, String email, String status) => {
  'id': id,
  'email': email,
  'role': 'User',
  'status': status,
  'created_at': '2026-10-11T08:00:00Z',
};

void main() {
  group('UserProfileRemoteDataSourceImpl.getInvites', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'http://test/',
          usesMockData: false,
        ),
        apiBaseService: api,
      );
    });

    void stubInvites(List<Map<String, dynamic>> invites) {
      when(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {'data': invites},
          statusCode: 200,
        ),
      );
    }

    test('asks the backend for invited invites only', () async {
      stubInvites([_invite('1', 'guest1@example.com', 'invited')]);

      await datasource.getInvites(orgId: 'org-1', page: 2);

      verify(
        () => api.get<Map<String, dynamic>>(
          path: '/organisations/org-1/invites',
          queryParameters: {'page': 2, 'limit': 20, 'invite_status': 'invited'},
        ),
      ).called(1);
    });

    test('drops accepted invites and matches the search on email', () async {
      stubInvites([
        _invite('1', 'Guest7@example.com', 'invited'),
        _invite('2', 'guest8@example.com', 'accepted'),
        _invite('3', 'other@example.com', 'invited'),
      ]);

      final all = await datasource.getInvites(orgId: 'org-1');
      final matches = await datasource.getInvites(
        orgId: 'org-1',
        search: 'GUEST',
      );

      expect(all.map((invite) => invite.id), ['1', '3']);
      expect(matches.map((invite) => invite.id), ['1']);
    });
  });
}

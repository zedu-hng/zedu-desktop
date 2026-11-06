import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.updateAccount', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {'status': 'success'},
          statusCode: 200,
        ),
      );
    });

    test('sends the phone number to PATCH /profile as form data', () async {
      const account = ProfileAccount(
        name: 'Odofin Moronke',
        email: '',
        timezone: '',
        phoneNumber: '+2348012345678',
      );

      final saved = await datasource.updateAccount(account);

      final data =
          verify(
                () => mockApi.patch<Map<String, dynamic>>(
                  path: '/profile',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(Map.fromEntries(data.fields), {
        'full_name': 'Odofin Moronke',
        'phone': '+2348012345678',
      });
      expect(saved.phoneNumber, '+2348012345678');
    });
  });

  group('UserProfileRemoteDataSourceImpl.getTeamMembers', () {
    const orgId = '019700db-4e22-7f90-a20e-f9116291ef24';

    test('parses each member status instead of forcing active', () async {
      final mockApi = MockApiBaseService();
      final datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );

      when(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/$orgId/users',
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {'id': '1', 'email': 'active@example.com', 'status': 'active'},
              {'id': '2', 'email': 'pending@example.com', 'status': 'pending'},
              {
                'id': '3',
                'email': 'inactive@example.com',
                'status': 'inactive',
              },
              {'id': '4', 'email': 'unknown@example.com'},
            ],
          },
        ),
      );

      final members = await datasource.getTeamMembers(orgId: orgId);

      expect(members.map((member) => member.status), [
        TeamMemberStatus.active,
        TeamMemberStatus.pending,
        TeamMemberStatus.inactive,
        TeamMemberStatus.active,
      ]);
    });
  });
}

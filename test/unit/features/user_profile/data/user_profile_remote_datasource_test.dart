import '../../../../helpers/helpers.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.getAccount', () {
    test(
      'loads saved account fields from the current profile endpoint',
      () async {
        final mockApi = MockApiBaseService();
        final datasource = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(apiBaseUrl: '', usesMockData: false),
          apiBaseService: mockApi,
        );
        when(
          () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
        ).thenAnswer(
          (_) async => const ApiResponseModel<Map<String, dynamic>>(
            statusCode: 200,
            data: {
              'data': {
                'full_name': 'Test Learner',
                'email': 'learner@example.com',
                'timezone': 'Africa/Lagos',
                'display_name': 'Learner',
                'username': 'test-learner',
                'phone': '+2348000000000',
                'title': 'Student',
                'name_pronounciation': 'lear-ner',
              },
            },
          ),
        );

        final account = await datasource.getAccount();

        verify(
          () => mockApi.get<Map<String, dynamic>>(path: '/profile'),
        ).called(1);
        expect(account.name, 'Test Learner');
        expect(account.displayName, 'Learner');
        expect(account.username, 'test-learner');
        expect(account.phoneNumber, '+2348000000000');
        expect(account.title, 'Student');
        expect(account.namePronunciation, 'lear-ner');
      },
    );
  });

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
}

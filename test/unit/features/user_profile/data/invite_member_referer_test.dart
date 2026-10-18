import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('webAppUrlFromApiBaseUrl', () {
    test('converts the staging API URL to the website root', () {
      expect(
        webAppUrlFromApiBaseUrl('https://api.staging.zedu.chat/api/v1/'),
        'https://staging.zedu.chat/',
      );
    });

    test('converts the team API URL to the website root', () {
      expect(
        webAppUrlFromApiBaseUrl('https://api.mando.groups.zedu.chat/api/v1/'),
        'https://mando.groups.zedu.chat/',
      );
    });

    test('preserves localhost scheme and port', () {
      expect(
        webAppUrlFromApiBaseUrl('http://localhost:8019/api/v1/'),
        'http://localhost:8019/',
      );
    });
  });

  test('inviteMember sends the derived Referer header', () async {
    final config = AppConfig(
      apiBaseUrl: 'https://api.staging.zedu.chat/api/v1/',
      usesMockData: false,
    );
    final dio = Dio();
    RequestOptions? capturedRequest;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'data': {'invitations': <dynamic>[]},
              },
            ),
          );
        },
      ),
    );

    final dataSource = UserProfileRemoteDataSourceImpl(
      config: config,
      apiBaseService: ApiBaseService(config: config, dio: dio),
    );

    await dataSource.inviteMember(
      email: 'invitee@example.com',
      role: 'Member',
      orgId: 'org-1',
    );

    expect(capturedRequest?.path, '/invite');
    expect(capturedRequest?.headers['Referer'], 'https://staging.zedu.chat/');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('resolveWebAppUrl', () {
    test('configured web URL wins when API and web origins differ', () {
      expect(
        resolveWebAppUrl(
          apiBaseUrl: 'http://localhost:8019/api/v1/',
          webAppUrl: 'http://localhost:3000',
        ),
        'http://localhost:3000/',
      );
    });

    test('configured web URL wins over API host derivation', () {
      expect(
        resolveWebAppUrl(
          apiBaseUrl: 'https://api.staging.zedu.chat/api/v1/',
          webAppUrl: 'https://app.example.com/',
        ),
        'https://app.example.com/',
      );
    });

    test('derives web URL from an api-prefixed staging host', () {
      expect(
        resolveWebAppUrl(apiBaseUrl: 'https://api.staging.zedu.chat/api/v1/'),
        'https://staging.zedu.chat/',
      );
    });

    test('derives web URL from an api-prefixed team host', () {
      expect(
        resolveWebAppUrl(
          apiBaseUrl: 'https://api.mando.groups.zedu.chat/api/v1/',
        ),
        'https://mando.groups.zedu.chat/',
      );
    });

    test('returns null for localhost without a configured web URL', () {
      expect(
        resolveWebAppUrl(apiBaseUrl: 'http://localhost:8019/api/v1/'),
        isNull,
      );
    });

    test('returns null for localhost with a blank web URL', () {
      expect(
        resolveWebAppUrl(
          apiBaseUrl: 'http://localhost:8019/api/v1/',
          webAppUrl: '  ',
        ),
        isNull,
      );
    });
  });

  group('inviteMember Referer header', () {
    test(
      'sends the configured web URL when API and web origins differ',
      () async {
        final config = AppConfig(
          apiBaseUrl: 'http://localhost:8019/api/v1/',
          usesMockData: false,
          webAppUrl: 'http://localhost:3000/',
        );

        final request = await _captureInviteRequest(config);

        expect(request.headers['Referer'], 'http://localhost:3000/');
      },
    );

    test('sends the derived Referer for an api-prefixed host', () async {
      final config = AppConfig(
        apiBaseUrl: 'https://api.staging.zedu.chat/api/v1/',
        usesMockData: false,
      );

      final request = await _captureInviteRequest(config);

      expect(request.headers['Referer'], 'https://staging.zedu.chat/');
    });

    test('omits Referer for localhost without a configured web URL', () async {
      final config = AppConfig(
        apiBaseUrl: 'http://localhost:8019/api/v1/',
        usesMockData: false,
      );

      final request = await _captureInviteRequest(config);

      expect(request.headers.containsKey('Referer'), isFalse);
    });
  });
}

Future<RequestOptions> _captureInviteRequest(AppConfig config) async {
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

  return capturedRequest!;
}

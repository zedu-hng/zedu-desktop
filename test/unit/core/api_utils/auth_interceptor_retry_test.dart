import 'dart:io';

import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';

class _MemoryStorage extends SecureStorageService {
  String? token;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token, {bool persist = true}) async {
    this.token = token;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;
}

void main() {
  late HttpServer server;
  late Dio dio;
  late _MemoryStorage storage;
  late List<String?> authorizationHeaders;
  late int requestCount;
  late int unauthorizedCount;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}/'));
    storage = _MemoryStorage()..token = 'expired-token';
    authorizationHeaders = <String?>[];
    requestCount = 0;
    unauthorizedCount = 0;
  });

  tearDown(() async {
    dio.close(force: true);
    await server.close(force: true);
  });

  AuthInterceptor addInterceptor({Future<String?> Function()? refresh}) {
    final interceptor = AuthInterceptor(
      storage: storage,
      dio: dio,
      onRefreshToken: refresh,
    )..onUnauthorized = () => unauthorizedCount++;
    dio.interceptors.add(interceptor);
    return interceptor;
  }

  void listen({required bool retrySucceeds}) {
    server.listen((request) async {
      requestCount++;
      authorizationHeaders.add(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      request.response.headers.contentType = ContentType.json;
      if (retrySucceeds && requestCount == 2) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('{"ok":true}');
      } else {
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('{"message":"unauthorized"}');
      }
      await request.response.close();
    });
  }

  test('retries once with a refreshed token and resolves the caller', () async {
    listen(retrySucceeds: true);
    addInterceptor(
      refresh: () async {
        storage.token = 'refreshed-token';
        return storage.token;
      },
    );

    final response = await dio.get<Map<String, dynamic>>('resource');

    expect(response.data, {'ok': true});
    expect(requestCount, 2);
    expect(authorizationHeaders, [
      'Bearer expired-token',
      'Bearer refreshed-token',
    ]);
    expect(storage.token, 'refreshed-token');
    expect(unauthorizedCount, 0);
  });

  test('falls back to unauthorized when no refreshed token exists', () async {
    listen(retrySucceeds: false);
    addInterceptor(refresh: () async => null);

    await expectLater(
      dio.get<Map<String, dynamic>>('resource'),
      throwsA(isA<DioException>()),
    );

    expect(requestCount, 1);
    expect(storage.token, isNull);
    expect(unauthorizedCount, 1);
  });

  test('does not retry when refresh returns the rejected token', () async {
    listen(retrySucceeds: false);
    addInterceptor(refresh: () async => 'expired-token');

    await expectLater(
      dio.get<Map<String, dynamic>>('resource'),
      throwsA(isA<DioException>()),
    );

    expect(requestCount, 1);
    expect(storage.token, isNull);
    expect(unauthorizedCount, 1);
  });

  test('a second 401 signs out without retrying again', () async {
    listen(retrySucceeds: false);
    addInterceptor(
      refresh: () async {
        storage.token = 'refreshed-token';
        return storage.token;
      },
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('resource'),
      throwsA(isA<DioException>()),
    );

    expect(requestCount, 2);
    expect(authorizationHeaders, [
      'Bearer expired-token',
      'Bearer refreshed-token',
    ]);
    expect(storage.token, isNull);
    expect(unauthorizedCount, 1);
  });
}

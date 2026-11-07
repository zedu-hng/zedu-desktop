import 'package:zedu/core/core.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    Dio? dio,
    this.onRefreshToken,
  }) : _storage = storage,
       _dio = dio ?? Dio();

  static const _retriedAfterRefreshKey = 'auth_retried_after_refresh';

  final SecureStorageService _storage;
  final Dio _dio;
  VoidCallback? onUnauthorized;
  Future<String?> Function()? onRefreshToken;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_retriedAfterRefreshKey] == true) {
      handler.next(options);
      return;
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;
    if (request.extra[_retriedAfterRefreshKey] != true) {
      final rejectedToken = _bearerToken(request.headers['Authorization']);
      final refreshedToken = await _refreshToken();

      if (refreshedToken != null && refreshedToken != rejectedToken) {
        request
          ..headers['Authorization'] = 'Bearer $refreshedToken'
          ..extra[_retriedAfterRefreshKey] = true;

        try {
          final response = await _dio.fetch<dynamic>(request);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
    }

    await _handleUnauthorized();
    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    try {
      final token = await onRefreshToken?.call();
      return token?.trim().isEmpty ?? true ? null : token;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleUnauthorized() async {
    await _storage.deleteAccessToken();
    onUnauthorized?.call();
  }

  String? _bearerToken(Object? authorization) {
    if (authorization is! String || !authorization.startsWith('Bearer ')) {
      return null;
    }
    return authorization.substring('Bearer '.length);
  }
}

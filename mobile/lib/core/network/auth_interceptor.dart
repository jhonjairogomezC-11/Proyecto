import 'package:dio/dio.dart';
import 'package:voluntapp_mobile/core/storage/secure_token_storage.dart';

/// Inyecta Authorization Bearer en cada request (excepto auth pública).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final SecureTokenStorage _tokenStorage;

  static const _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));

    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}

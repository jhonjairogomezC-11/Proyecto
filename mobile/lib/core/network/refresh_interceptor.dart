import 'package:dio/dio.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/storage/secure_token_storage.dart';

typedef OnSessionExpired = Future<void> Function();

/// Refresh automático en 401 (patrón alineado al frontend Vue).
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio dio,
    required SecureTokenStorage tokenStorage,
    required this.onSessionExpired,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;
  final OnSessionExpired onSessionExpired;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pending = [];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final request = err.requestOptions;

    if (response?.statusCode != 401 || request.extra['_retried'] == true) {
      return handler.next(err);
    }

    if (request.path.endsWith(ApiConstants.authRefresh) ||
        request.path.endsWith(ApiConstants.authLogin)) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      _pending.add(_PendingRequest(request, handler));
      return;
    }

    _isRefreshing = true;
    request.extra['_retried'] = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await onSessionExpired();
        return handler.next(err);
      }

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      final data = refreshResponse.data;
      final newAccess = data?['token'] as String?;
      final newRefresh = data?['refresh_token'] as String?;

      if (newAccess == null || newRefresh == null) {
        await onSessionExpired();
        return handler.next(err);
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      await _resolvePending(newAccess);
      final retryResponse = await _retry(request, newAccess);
      return handler.resolve(retryResponse);
    } catch (_) {
      await onSessionExpired();
      for (final pending in _pending) {
        pending.handler.next(err);
      }
      _pending.clear();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _resolvePending(String token) async {
    final queue = List<_PendingRequest>.from(_pending);
    _pending.clear();

    for (final pending in queue) {
      try {
        final response = await _retry(pending.options, token);
        pending.handler.resolve(response);
      } catch (e) {
        pending.handler.reject(
          e is DioException
              ? e
              : DioException(requestOptions: pending.options, error: e),
        );
      }
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    final headers = Map<String, dynamic>.from(options.headers);
    headers['Authorization'] = 'Bearer $token';

    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: headers,
        responseType: options.responseType,
        contentType: options.contentType,
        extra: options.extra,
      ),
    );
  }
}

class _PendingRequest {
  _PendingRequest(this.options, this.handler);

  final RequestOptions options;
  final ErrorInterceptorHandler handler;
}

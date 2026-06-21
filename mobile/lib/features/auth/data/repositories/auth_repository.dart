import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/auth/data/models/auth_session.dart';

class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authLogin,
        data: {'email': email.trim(), 'password': password},
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AuthSession> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String rol,
    String? telefono,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authRegister,
        data: {
          'nombre': nombre.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'rol': rol,
          if (telefono != null && telefono.trim().isNotEmpty)
            'telefono': telefono.trim(),
        },
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.authLogout);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return;
      throw mapDioError(e);
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authForgotPassword,
        data: {'email': email.trim()},
      );
      return response.data?['message'] as String? ??
          'Si el email existe, recibirás un enlace de recuperación.';
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<String> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
    String? email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authResetPassword,
        data: {
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return response.data?['message'] as String? ??
          'Contraseña actualizada correctamente.';
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Error de conexión.']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'No autenticado.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'No autorizado.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Recurso no encontrado.']);
}

class ValidationException extends ApiException {
  const ValidationException(this.errors, [String? message])
      : super(message ?? 'Los datos proporcionados no son válidos.');

  final Map<String, String> errors;
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Error del servidor.']);
}

ApiException mapDioError(DioException error) {
  final response = error.response;

  if (response == null) {
    return NetworkException(error.message ?? 'Error de red.');
  }

  final data = response.data;
  final message = _extractMessage(data);

  switch (response.statusCode) {
    case 401:
      return UnauthorizedException(message);
    case 403:
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 422:
      return ValidationException(_extractErrors(data), message);
    default:
      return ServerException(message);
  }
}

String _extractMessage(dynamic data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return 'Error inesperado.';
}

Map<String, String> _extractErrors(dynamic data) {
  if (data is! Map || data['errors'] is! Map) return {};

  final errors = <String, String>{};
  (data['errors'] as Map).forEach((key, value) {
    if (value is List && value.isNotEmpty) {
      errors[key.toString()] = value.first.toString();
    }
  });
  return errors;
}

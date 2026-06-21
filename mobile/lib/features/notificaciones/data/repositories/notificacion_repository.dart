import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/notificaciones/data/models/notificacion.dart';

class NotificacionRepository {
  NotificacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<PaginatedResponse<Notificacion>> fetchNotificaciones({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.notificaciones,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(response.data!, Notificacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<int> fetchNoLeidas() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiConstants.notificacionesNoLeidas);
      return response.data?['total'] as int? ?? 0;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Notificacion> marcarLeida(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.notificaciones}/$id/marcar-leida',
      );
      return Notificacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> marcarTodasLeidas() async {
    try {
      await _dio.post<void>('${ApiConstants.notificaciones}/marcar-todas-leidas');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return NotificacionRepository(ref);
});

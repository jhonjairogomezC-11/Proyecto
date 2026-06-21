import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_historial_item.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_voluntario_item.dart';
import 'package:voluntapp_mobile/features/admin/data/models/reporte.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/fundacion_perfil.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

class AdminRepository {
  AdminRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<int> countFundacionesPendientes() async {
    final result = await fetchFundaciones(estado: 'PENDIENTE', page: 1, perPage: 1);
    return result.meta.total;
  }

  Future<int> countPublicacionesPendientes() async {
    final result = await fetchPublicaciones(estado: 'PENDIENTE_APROBACION', page: 1, perPage: 1);
    return result.meta.total;
  }

  Future<int> countReportesPendientes() async {
    final result = await fetchReportes(estado: 'PENDIENTE', page: 1, perPage: 1);
    return result.meta.total;
  }

  Future<PaginatedResponse<FundacionPerfil>> fetchFundaciones({
    String? estado,
    String? nombre,
    int page = 1,
    int? perPage,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (estado != null && estado.isNotEmpty) params['estado'] = estado;
      if (nombre != null && nombre.isNotEmpty) params['nombre'] = nombre;
      if (perPage != null) params['per_page'] = perPage;

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminFundaciones,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(response.data!, FundacionPerfil.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> aprobarFundacion(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminFundaciones}/$id/aprobar',
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> rechazarFundacion(String id, String motivo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminFundaciones}/$id/rechazar',
        data: {'motivo': motivo},
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> suspenderFundacion(String id, String motivo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminFundaciones}/$id/suspender',
        data: {'motivo': motivo},
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> reactivarFundacion(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminFundaciones}/$id/reactivar',
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<AdminHistorialItem>> fetchFundacionHistorial(String fundacionId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiConstants.adminFundaciones}/$fundacionId/historial',
      );
      return (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminHistorialItem.fromFundacionJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<AdminHistorialItem>> fetchVoluntarioHistorial(String voluntarioId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiConstants.adminVoluntarios}/$voluntarioId/historial',
      );
      return (response.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminHistorialItem.fromVoluntarioJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PaginatedResponse<Publicacion>> fetchPublicaciones({
    String estado = 'PENDIENTE_APROBACION',
    int page = 1,
    int? perPage,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'estado': estado};
      if (perPage != null) params['per_page'] = perPage;

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminPublicaciones,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(response.data!, Publicacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> aprobarPublicacion(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminPublicaciones}/$id/aprobar',
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> rechazarPublicacion(String id, String motivo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminPublicaciones}/$id/rechazar',
        data: {'motivo': motivo},
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PaginatedResponse<AdminVoluntarioItem>> fetchVoluntarios({
    String? estado,
    String? nombre,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (estado != null && estado.isNotEmpty) params['estado'] = estado;
      if (nombre != null && nombre.isNotEmpty) params['nombre'] = nombre;

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminVoluntarios,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(response.data!, AdminVoluntarioItem.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AdminVoluntarioItem> suspenderVoluntario(
    String id, {
    required String motivo,
    int? duracionDias,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminVoluntarios}/$id/suspender',
        data: {
          'motivo': motivo,
          if (duracionDias != null) 'duracion_dias': duracionDias,
        },
      );
      return AdminVoluntarioItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AdminVoluntarioItem> bloquearVoluntario(String id, String motivo) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminVoluntarios}/$id/bloquear',
        data: {'motivo': motivo},
      );
      return AdminVoluntarioItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<AdminVoluntarioItem> reactivarVoluntario(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminVoluntarios}/$id/reactivar',
      );
      return AdminVoluntarioItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PaginatedResponse<Reporte>> fetchReportes({
    String? estado,
    int page = 1,
    int? perPage,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (estado != null && estado.isNotEmpty) params['estado'] = estado;
      if (perPage != null) params['per_page'] = perPage;

      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.adminReportes,
        queryParameters: params,
      );
      return PaginatedResponse.fromJson(response.data!, Reporte.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Reporte> resolverReporte(
    String id, {
    required String estado,
    required String resolucion,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminReportes}/$id/resolver',
        data: {'estado': estado, 'resolucion': resolucion},
      );
      return Reporte.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref);
});

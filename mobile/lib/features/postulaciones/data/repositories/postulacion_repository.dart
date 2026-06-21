import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/models/postulacion.dart';

class PostulacionRepository {
  PostulacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<PaginatedResponse<Postulacion>> fetchMisPostulaciones(
      {int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.misPostulaciones,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return PaginatedResponse.fromJson(response.data!, Postulacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Postulacion>> fetchMisPostulacionesActivas() async {
    final result = await fetchMisPostulaciones(page: 1, perPage: 100);
    return result.data;
  }

  Future<Postulacion> postular({
    required String publicacionId,
    String? mensajeVoluntario,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.postulaciones,
        data: {
          'publicacion_id': publicacionId,
          'mensaje_voluntario': mensajeVoluntario,
        },
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Postulacion> retirar(String postulacionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.postulaciones}/$postulacionId/retirar',
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<PaginatedResponse<Postulacion>> fetchPostulantesDePublicacion({
    required String publicacionId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$publicacionId/postulaciones',
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(response.data!, Postulacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Postulacion> responder({
    required String postulacionId,
    required String estado,
    String? motivoRechazo,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.postulaciones}/$postulacionId/responder',
        data: {
          'estado': estado,
          if (motivoRechazo != null) 'motivo_rechazo': motivoRechazo,
        },
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Postulacion> confirmarAsistencia({
    required String postulacionId,
    required bool asistio,
    int? calificacion,
    String? comentarioFundacion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.postulaciones}/$postulacionId/confirmar-asistencia',
        data: {
          'asistio': asistio,
          if (calificacion != null) 'calificacion': calificacion,
          if (comentarioFundacion != null && comentarioFundacion.isNotEmpty)
            'comentario_fundacion': comentarioFundacion,
        },
      );
      return Postulacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final postulacionRepositoryProvider = Provider<PostulacionRepository>((ref) {
  return PostulacionRepository(ref);
});

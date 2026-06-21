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

  Future<PaginatedResponse<Postulacion>> fetchMisPostulaciones({int page = 1, int perPage = 15}) async {
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
}

final postulacionRepositoryProvider = Provider<PostulacionRepository>((ref) {
  return PostulacionRepository(ref);
});

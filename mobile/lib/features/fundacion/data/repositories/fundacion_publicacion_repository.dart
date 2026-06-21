import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/publicacion_input.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

class FundacionPublicacionRepository {
  FundacionPublicacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<PaginatedResponse<Publicacion>> fetchMisPublicaciones(
      {int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.misPublicaciones,
        queryParameters: {'page': page},
      );
      return PaginatedResponse.fromJson(response.data!, Publicacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> create(PublicacionInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.publicaciones,
        data: input.toJson(),
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> update(String id, PublicacionInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$id',
        data: input.toJson(),
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> publicar(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$id/publicar',
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> cancelar(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$id/cancelar',
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> subirImagenes(
      String publicacionId, List<String> filePaths) async {
    try {
      final files = await Future.wait(
        filePaths.map((path) async {
          final name = path.split(RegExp(r'[/\\]')).last;
          return MapEntry(
              'imagenes[]', await MultipartFile.fromFile(path, filename: name));
        }),
      );

      final formData = FormData();
      formData.files.addAll(files);

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$publicacionId/imagenes',
        data: formData,
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Publicacion> eliminarImagen(
      String publicacionId, String imagenId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '${ApiConstants.publicaciones}/$publicacionId/imagenes/$imagenId',
      );
      return Publicacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final fundacionPublicacionRepositoryProvider =
    Provider<FundacionPublicacionRepository>((ref) {
  return FundacionPublicacionRepository(ref);
});

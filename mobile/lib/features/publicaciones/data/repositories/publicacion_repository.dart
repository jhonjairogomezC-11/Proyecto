import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

class PublicacionRepository {
  PublicacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<PaginatedResponse<Publicacion>> fetchPublicaciones({
    required PublicacionFilters filters,
    required int page,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.publicaciones,
        queryParameters: filters.toQueryParams(page: page),
      );
      return PaginatedResponse.fromJson(response.data!, Publicacion.fromJson);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final publicacionRepositoryProvider = Provider<PublicacionRepository>((ref) {
  return PublicacionRepository(ref);
});

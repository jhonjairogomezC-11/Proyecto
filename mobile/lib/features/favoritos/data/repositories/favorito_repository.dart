import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/favoritos/data/models/favorito.dart';

class FavoritoIds {
  const FavoritoIds({required this.publicaciones, required this.fundaciones});

  final List<String> publicaciones;
  final List<String> fundaciones;
}

class FavoritoRepository {
  FavoritoRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<FavoritoIds> fetchIds() async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiConstants.voluntarioFavoritosIds);
      final data = response.data ?? {};
      return FavoritoIds(
        publicaciones: (data['publicaciones'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        fundaciones: (data['fundaciones'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<bool> togglePublicacion(String publicacionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.voluntarioFavoritos}/publicacion/$publicacionId',
      );
      return response.data?['favorito'] as bool? ?? false;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<bool> toggleFundacion(String fundacionId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.voluntarioFavoritos}/fundacion/$fundacionId',
      );
      return response.data?['favorito'] as bool? ?? false;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Favorito>> fetchAll({String? tipo}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.voluntarioFavoritos,
        queryParameters: tipo != null ? {'tipo': tipo} : null,
      );
      final raw = response.data;
      final list =
          raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      return (list ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Favorito.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> remove(String favoritoId) async {
    try {
      await _dio
          .delete<void>('${ApiConstants.voluntarioFavoritos}/$favoritoId');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final favoritoRepositoryProvider = Provider<FavoritoRepository>((ref) {
  return FavoritoRepository(ref);
});

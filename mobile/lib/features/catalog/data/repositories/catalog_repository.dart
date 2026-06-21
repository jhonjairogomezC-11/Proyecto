import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/core/storage/catalog_cache.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';

class CatalogRepository {
  CatalogRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<List<Departamento>> getDepartamentos({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CatalogCache.readList(CatalogCache.departamentosKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(Departamento.fromJson).toList();
      }
    }

    try {
      final response = await _dio.get<List<dynamic>>(ApiConstants.catalogosDepartamentos);
      final list = response.data ?? [];
      final maps = list.cast<Map<String, dynamic>>();
      await CatalogCache.writeList(CatalogCache.departamentosKey, maps);
      return maps.map(Departamento.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Municipio>> getMunicipios(
    int departamentoId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = CatalogCache.readMunicipios(departamentoId);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(Municipio.fromJson).toList();
      }
    }

    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.catalogosMunicipios,
        queryParameters: {'departamento_id': departamentoId},
      );
      final list = response.data ?? [];
      final maps = list.cast<Map<String, dynamic>>();
      await CatalogCache.writeMunicipios(departamentoId, maps);
      return maps.map(Municipio.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<CatalogItem>> getHabilidades({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CatalogCache.readList(CatalogCache.habilidadesKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(CatalogItem.fromJson).toList();
      }
    }

    try {
      final response = await _dio.get<List<dynamic>>(ApiConstants.catalogosHabilidades);
      final list = response.data ?? [];
      final maps = list.cast<Map<String, dynamic>>();
      await CatalogCache.writeList(CatalogCache.habilidadesKey, maps);
      return maps.map(CatalogItem.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<CatalogItem>> getIntereses({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CatalogCache.readList(CatalogCache.interesesKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map(CatalogItem.fromJson).toList();
      }
    }

    try {
      final response = await _dio.get<List<dynamic>>(ApiConstants.catalogosIntereses);
      final list = response.data ?? [];
      final maps = list.cast<Map<String, dynamic>>();
      await CatalogCache.writeList(CatalogCache.interesesKey, maps);
      return maps.map(CatalogItem.fromJson).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref);
});

final departamentosProvider = FutureProvider<List<Departamento>>((ref) {
  return ref.watch(catalogRepositoryProvider).getDepartamentos();
});

final habilidadesProvider = FutureProvider<List<CatalogItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).getHabilidades();
});

final interesesProvider = FutureProvider<List<CatalogItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).getIntereses();
});

final municipiosProvider = FutureProvider.family<List<Municipio>, int>((ref, deptId) {
  if (deptId <= 0) return Future.value([]);
  return ref.watch(catalogRepositoryProvider).getMunicipios(deptId);
});

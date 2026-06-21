import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/fundacion_perfil.dart';

class FundacionRepository {
  FundacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<FundacionPerfil?> fetchPerfil() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.miFundacion);
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> createPerfil(FundacionPerfilInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.fundaciones,
        data: input.toJson(),
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> updatePerfil(
      String id, FundacionPerfilInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConstants.fundaciones}/$id',
        data: input.toJson(includeNit: false),
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<FundacionPerfil> actualizarLogo(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.miFundacion}/logo',
        data: formData,
      );
      return FundacionPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final fundacionRepositoryProvider = Provider<FundacionRepository>((ref) {
  return FundacionRepository(ref);
});

final fundacionPerfilProvider = FutureProvider<FundacionPerfil?>((ref) async {
  return ref.read(fundacionRepositoryProvider).fetchPerfil();
});

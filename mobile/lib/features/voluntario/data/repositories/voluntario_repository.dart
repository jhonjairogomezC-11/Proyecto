import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/dashboard_voluntario.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/voluntario_perfil.dart';

class VoluntarioRepository {
  VoluntarioRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<VoluntarioPerfil?> fetchPerfil() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.voluntario);
      return VoluntarioPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapDioError(e);
    }
  }

  Future<VoluntarioPerfil> createPerfil(VoluntarioPerfilInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.voluntario,
        data: input.toJson(),
      );
      return VoluntarioPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VoluntarioPerfil> updatePerfil(VoluntarioPerfilInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConstants.voluntario,
        data: input.toJson(),
      );
      return VoluntarioPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VoluntarioPerfil> subirFotoPerfil(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'foto_perfil': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.voluntario}/foto-perfil',
        data: formData,
      );
      return VoluntarioPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<VoluntarioPerfil> subirDocumentoIdentidad(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'documento_identidad': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.voluntario}/documento-identidad',
        data: formData,
      );
      return VoluntarioPerfil.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<DashboardVoluntario> fetchDashboard() async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiConstants.voluntarioDashboard);
      return DashboardVoluntario.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final voluntarioRepositoryProvider = Provider<VoluntarioRepository>((ref) {
  return VoluntarioRepository(ref);
});

final voluntarioPerfilProvider = FutureProvider<VoluntarioPerfil?>((ref) {
  return ref.watch(voluntarioRepositoryProvider).fetchPerfil();
});

final dashboardVoluntarioProvider =
    FutureProvider<DashboardVoluntario?>((ref) async {
  final perfil = await ref.watch(voluntarioPerfilProvider.future);
  if (perfil == null) return null;

  try {
    return await ref.watch(voluntarioRepositoryProvider).fetchDashboard();
  } on NotFoundException {
    return null;
  }
});

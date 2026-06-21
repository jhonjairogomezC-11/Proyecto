import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/logros/data/models/logros_models.dart';

class GamificacionRepository {
  GamificacionRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<PuntosDetalle> fetchPuntos() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.voluntarioPuntos);
      return PuntosDetalle.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<LogrosDetalle> fetchLogros() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(ApiConstants.voluntarioLogros);
      return LogrosDetalle.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final gamificacionRepositoryProvider = Provider<GamificacionRepository>((ref) {
  return GamificacionRepository(ref);
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voluntapp_mobile/core/constants/api_constants.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';
import 'package:voluntapp_mobile/core/providers/core_providers.dart';
import 'package:voluntapp_mobile/features/admin/data/models/reporte.dart';

class ReporteInput {
  const ReporteInput({
    required this.objetoTipo,
    required this.objetoId,
    required this.motivo,
    this.detalle,
  });

  final String objetoTipo;
  final String objetoId;
  final String motivo;
  final String? detalle;

  Map<String, dynamic> toJson() => {
        'objeto_tipo': objetoTipo,
        'objeto_id': objetoId,
        'motivo': motivo,
        if (detalle != null && detalle!.isNotEmpty) 'detalle': detalle,
      };
}

class ReporteRepository {
  ReporteRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<Reporte> crear(ReporteInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.reportes,
        data: input.toJson(),
      );
      return Reporte.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final reporteRepositoryProvider = Provider<ReporteRepository>((ref) {
  return ReporteRepository(ref);
});

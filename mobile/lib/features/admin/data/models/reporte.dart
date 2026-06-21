class Reporte {
  const Reporte({
    required this.id,
    required this.motivo,
    required this.estado,
    required this.objetoTipo,
    required this.objetoId,
    this.detalle,
    this.resolucion,
    this.fechaCreacion,
    this.reportanteNombre,
  });

  final String id;
  final String motivo;
  final String estado;
  final String objetoTipo;
  final String objetoId;
  final String? detalle;
  final String? resolucion;
  final String? fechaCreacion;
  final String? reportanteNombre;

  bool get isPendiente => estado == 'PENDIENTE' || estado == 'EN_REVISION';

  factory Reporte.fromJson(Map<String, dynamic> json) {
    String? reportanteNombre;
    final reportante = json['reportante'];
    if (reportante is Map<String, dynamic>) {
      reportanteNombre = reportante['nombre'] as String?;
    }

    return Reporte(
      id: json['id'].toString(),
      motivo: _enumValue(json['motivo']),
      estado: _enumValue(json['estado']),
      objetoTipo: json['objeto_tipo'] as String? ?? '',
      objetoId: json['objeto_id']?.toString() ?? '',
      detalle: json['detalle'] as String?,
      resolucion: json['resolucion'] as String?,
      fechaCreacion: json['fecha_creacion']?.toString(),
      reportanteNombre: reportanteNombre,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value?.toString() ?? '';
  }
}

abstract final class ReporteMotivos {
  static const labels = {
    'INFORMACION_FALSA': 'Información falsa',
    'CONTENIDO_INAPROPIADO': 'Contenido inapropiado',
    'ACTIVIDAD_SOSPECHOSA': 'Actividad sospechosa',
    'PERFIL_SOSPECHOSO': 'Perfil sospechoso',
    'OTRO': 'Otro',
  };

  static String label(String motivo) => labels[motivo] ?? motivo;
}

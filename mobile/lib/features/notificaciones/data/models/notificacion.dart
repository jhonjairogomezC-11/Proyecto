class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.mensaje,
    required this.leida,
    this.objetoTipo,
    this.objetoId,
    this.fechaLectura,
    this.fechaCreacion,
  });

  final String id;
  final String tipo;
  final String mensaje;
  final bool leida;
  final String? objetoTipo;
  final String? objetoId;
  final String? fechaLectura;
  final String? fechaCreacion;

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'].toString(),
      tipo: _enumValue(json['tipo']),
      mensaje: json['mensaje'] as String? ?? '',
      leida: json['leida'] as bool? ?? false,
      objetoTipo: json['objeto_tipo'] as String?,
      objetoId: json['objeto_id']?.toString(),
      fechaLectura: json['fecha_lectura']?.toString(),
      fechaCreacion: json['fecha_creacion']?.toString(),
    );
  }

  Notificacion copyWith({bool? leida, String? fechaLectura}) {
    return Notificacion(
      id: id,
      tipo: tipo,
      mensaje: mensaje,
      leida: leida ?? this.leida,
      objetoTipo: objetoTipo,
      objetoId: objetoId,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      fechaCreacion: fechaCreacion,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String) return value['value'] as String;
    return value?.toString() ?? '';
  }
}

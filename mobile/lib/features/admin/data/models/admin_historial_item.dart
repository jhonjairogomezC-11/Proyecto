class AdminHistorialItem {
  const AdminHistorialItem({
    this.tipo,
    this.fecha,
    this.estadoAnterior,
    this.estadoNuevo,
    this.estado,
    this.motivo,
    this.adminNombre,
    this.publicacion,
    this.calificacion,
    this.duracionDias,
    this.activa,
  });

  final String? tipo;
  final String? fecha;
  final String? estadoAnterior;
  final String? estadoNuevo;
  final String? estado;
  final String? motivo;
  final String? adminNombre;
  final String? publicacion;
  final num? calificacion;
  final int? duracionDias;
  final bool? activa;

  factory AdminHistorialItem.fromFundacionJson(Map<String, dynamic> json) {
    return AdminHistorialItem(
      fecha: json['fecha']?.toString(),
      estadoAnterior: _enum(json['estado_anterior']),
      estadoNuevo: _enum(json['estado_nuevo']),
      motivo: json['motivo'] as String?,
      adminNombre: _adminNombre(json['admin']),
    );
  }

  factory AdminHistorialItem.fromVoluntarioJson(Map<String, dynamic> json) {
    return AdminHistorialItem(
      tipo: json['tipo'] as String?,
      fecha: json['fecha']?.toString(),
      estadoAnterior: _enum(json['estado_anterior']),
      estadoNuevo: _enum(json['estado_nuevo']),
      estado: _enum(json['estado']),
      motivo: json['motivo'] as String?,
      adminNombre: json['admin'] as String? ?? _adminNombre(json['admin']),
      publicacion: json['publicacion'] as String?,
      calificacion: json['calificacion'] as num?,
      duracionDias: json['duracion_dias'] as int?,
      activa: json['activa'] as bool?,
    );
  }

  static String? _adminNombre(dynamic admin) {
    if (admin is String) return admin;
    if (admin is Map<String, dynamic>) {
      final usuario = admin['usuario'];
      if (usuario is Map<String, dynamic>) {
        return usuario['nombre'] as String?;
      }
    }
    return null;
  }

  static String? _enum(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value.toString();
  }

  String get titulo {
    if (tipo == 'PARTICIPACION') {
      return publicacion ?? 'Participación';
    }
    if (tipo == 'SANCION') {
      return '${estadoAnterior ?? ''} → ${estadoNuevo ?? ''}'.trim();
    }
    if (tipo == 'ADVERTENCIA') {
      return 'Advertencia${activa == false ? ' (inactiva)' : ''}';
    }
    return '${estadoAnterior ?? ''} → ${estadoNuevo ?? ''}'.trim();
  }
}

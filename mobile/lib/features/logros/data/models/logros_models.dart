class TransaccionPuntos {
  const TransaccionPuntos({
    required this.id,
    required this.puntosTotal,
    this.motivo,
    this.fecha,
  });

  final String id;
  final int puntosTotal;
  final String? motivo;
  final String? fecha;

  factory TransaccionPuntos.fromJson(Map<String, dynamic> json) {
    return TransaccionPuntos(
      id: json['id'].toString(),
      puntosTotal: json['puntos_total'] as int? ?? 0,
      motivo: json['motivo'] as String?,
      fecha: json['fecha']?.toString(),
    );
  }
}

class PuntosDetalle {
  const PuntosDetalle({
    required this.saldo,
    required this.totalHistorico,
    this.transacciones = const [],
  });

  final int saldo;
  final int totalHistorico;
  final List<TransaccionPuntos> transacciones;

  factory PuntosDetalle.fromJson(Map<String, dynamic> json) {
    return PuntosDetalle(
      saldo: json['saldo'] as int? ?? 0,
      totalHistorico: json['total_historico'] as int? ?? 0,
      transacciones: (json['transacciones'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TransaccionPuntos.fromJson)
          .toList(),
    );
  }
}

class LogroObtenidoDetalle {
  const LogroObtenidoDetalle({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.icono,
    this.fechaObtencion,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String? fechaObtencion;

  factory LogroObtenidoDetalle.fromJson(Map<String, dynamic> json) {
    return LogroObtenidoDetalle(
      id: json['id'].toString(),
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      fechaObtencion: json['fecha_obtencion']?.toString(),
    );
  }
}

class LogroPendiente {
  const LogroPendiente({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    this.icono,
    required this.progreso,
    required this.umbral,
    required this.porcentaje,
  });

  final String id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final int progreso;
  final int umbral;
  final int porcentaje;

  factory LogroPendiente.fromJson(Map<String, dynamic> json) {
    return LogroPendiente(
      id: json['id'].toString(),
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      progreso: json['progreso'] as int? ?? 0,
      umbral: json['umbral'] as int? ?? 0,
      porcentaje: json['porcentaje'] as int? ?? 0,
    );
  }
}

class LogrosDetalle {
  const LogrosDetalle({
    this.obtenidos = const [],
    this.pendientes = const [],
  });

  final List<LogroObtenidoDetalle> obtenidos;
  final List<LogroPendiente> pendientes;

  factory LogrosDetalle.fromJson(Map<String, dynamic> json) {
    return LogrosDetalle(
      obtenidos: (json['obtenidos'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LogroObtenidoDetalle.fromJson)
          .toList(),
      pendientes: (json['pendientes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LogroPendiente.fromJson)
          .toList(),
    );
  }
}

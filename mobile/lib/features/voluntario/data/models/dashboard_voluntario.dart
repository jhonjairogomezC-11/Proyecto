import 'package:voluntapp_mobile/features/voluntario/data/models/postulacion_resumen.dart';

class DashboardVoluntario {
  const DashboardVoluntario({
    required this.perfilCompleto,
    required this.actividadesCompletadas,
    required this.puntos,
    required this.nivel,
    required this.logros,
    this.logroProximo,
    required this.ranking,
    required this.proximasActividades,
    required this.postulacionesResumen,
    required this.progresoMensual,
  });

  final bool perfilCompleto;
  final ActividadesCompletadas actividadesCompletadas;
  final PuntosResumen puntos;
  final NivelProgreso nivel;
  final LogrosResumen logros;
  final LogroProximo? logroProximo;
  final RankingResumen ranking;
  final List<PostulacionResumen> proximasActividades;
  final PostulacionesResumen postulacionesResumen;
  final ProgresoMensual progresoMensual;

  factory DashboardVoluntario.fromJson(Map<String, dynamic> json) {
    return DashboardVoluntario(
      perfilCompleto: json['perfil_completo'] as bool? ?? true,
      actividadesCompletadas: ActividadesCompletadas.fromJson(
        json['actividades_completadas'] as Map<String, dynamic>? ?? {},
      ),
      puntos: PuntosResumen.fromJson(
        json['puntos'] as Map<String, dynamic>? ?? {},
      ),
      nivel:
          NivelProgreso.fromJson(json['nivel'] as Map<String, dynamic>? ?? {}),
      logros:
          LogrosResumen.fromJson(json['logros'] as Map<String, dynamic>? ?? {}),
      logroProximo: json['logro_proximo'] is Map<String, dynamic>
          ? LogroProximo.fromJson(json['logro_proximo'] as Map<String, dynamic>)
          : null,
      ranking: RankingResumen.fromJson(
          json['ranking'] as Map<String, dynamic>? ?? {}),
      proximasActividades:
          (json['proximas_actividades'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(PostulacionResumen.fromJson)
              .toList(),
      postulacionesResumen: PostulacionesResumen.fromJson(
        json['postulaciones_resumen'] as Map<String, dynamic>? ?? {},
      ),
      progresoMensual: ProgresoMensual.fromJson(
        json['progreso_mensual'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ActividadesCompletadas {
  const ActividadesCompletadas({
    required this.total,
    required this.estaSemana,
    required this.esteMes,
  });

  final int total;
  final int estaSemana;
  final int esteMes;

  factory ActividadesCompletadas.fromJson(Map<String, dynamic> json) {
    return ActividadesCompletadas(
      total: json['total'] as int? ?? 0,
      estaSemana: json['esta_semana'] as int? ?? 0,
      esteMes: json['este_mes'] as int? ?? 0,
    );
  }
}

class PuntosResumen {
  const PuntosResumen({required this.saldo, required this.totalHistorico});

  final int saldo;
  final int totalHistorico;

  factory PuntosResumen.fromJson(Map<String, dynamic> json) {
    return PuntosResumen(
      saldo: json['saldo'] as int? ?? 0,
      totalHistorico: json['total_historico'] as int? ?? 0,
    );
  }
}

class NivelRef {
  const NivelRef({
    required this.codigo,
    required this.nombre,
    required this.color,
  });

  final String codigo;
  final String nombre;
  final String color;

  factory NivelRef.fromJson(Map<String, dynamic> json) {
    return NivelRef(
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Bronce',
      color: json['color'] as String? ?? '#cd7f32',
    );
  }
}

class NivelProgreso {
  const NivelProgreso({
    required this.nivelActual,
    this.nivelSiguiente,
    required this.puntosFaltan,
    this.umbralSiguiente,
    required this.porcentaje,
  });

  final NivelRef nivelActual;
  final NivelRef? nivelSiguiente;
  final int puntosFaltan;
  final int? umbralSiguiente;
  final int porcentaje;

  factory NivelProgreso.fromJson(Map<String, dynamic> json) {
    return NivelProgreso(
      nivelActual: NivelRef.fromJson(
        json['nivel_actual'] as Map<String, dynamic>? ?? {},
      ),
      nivelSiguiente: json['nivel_siguiente'] is Map<String, dynamic>
          ? NivelRef.fromJson(json['nivel_siguiente'] as Map<String, dynamic>)
          : null,
      puntosFaltan: json['puntos_faltan'] as int? ?? 0,
      umbralSiguiente: json['umbral_siguiente'] as int?,
      porcentaje: json['porcentaje'] as int? ?? 0,
    );
  }
}

class LogrosResumen {
  const LogrosResumen({required this.desbloqueados, required this.recientes});

  final int desbloqueados;
  final List<LogroObtenido> recientes;

  factory LogrosResumen.fromJson(Map<String, dynamic> json) {
    return LogrosResumen(
      desbloqueados: json['desbloqueados'] as int? ?? 0,
      recientes: (json['recientes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LogroObtenido.fromJson)
          .toList(),
    );
  }
}

class LogroObtenido {
  const LogroObtenido({
    required this.id,
    required this.nombre,
    this.fechaObtencion,
  });

  final int id;
  final String nombre;
  final String? fechaObtencion;

  factory LogroObtenido.fromJson(Map<String, dynamic> json) {
    return LogroObtenido(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre'] as String? ?? 'Logro',
      fechaObtencion: json['fecha_obtencion']?.toString(),
    );
  }
}

class LogroProximo {
  const LogroProximo({
    required this.nombre,
    required this.progreso,
    required this.umbral,
    required this.porcentaje,
  });

  final String nombre;
  final int progreso;
  final int umbral;
  final int porcentaje;

  factory LogroProximo.fromJson(Map<String, dynamic> json) {
    return LogroProximo(
      nombre: json['nombre'] as String? ?? '',
      progreso: json['progreso'] as int? ?? 0,
      umbral: json['umbral'] as int? ?? 0,
      porcentaje: json['porcentaje'] as int? ?? 0,
    );
  }
}

class RankingResumen {
  const RankingResumen({
    this.posicion,
    required this.total,
    this.topPercent,
  });

  final int? posicion;
  final int total;
  final double? topPercent;

  factory RankingResumen.fromJson(Map<String, dynamic> json) {
    return RankingResumen(
      posicion: json['posicion'] as int?,
      total: json['total'] as int? ?? 0,
      topPercent: (json['top_percent'] as num?)?.toDouble(),
    );
  }
}

class PostulacionesResumen {
  const PostulacionesResumen({
    required this.pendientes,
    required this.aceptadas,
    required this.rechazadas,
    required this.completadas,
  });

  final int pendientes;
  final int aceptadas;
  final int rechazadas;
  final int completadas;

  factory PostulacionesResumen.fromJson(Map<String, dynamic> json) {
    return PostulacionesResumen(
      pendientes: json['pendientes'] as int? ?? 0,
      aceptadas: json['aceptadas'] as int? ?? 0,
      rechazadas: json['rechazadas'] as int? ?? 0,
      completadas: json['completadas'] as int? ?? 0,
    );
  }
}

class ProgresoMensual {
  const ProgresoMensual({
    required this.completadas,
    required this.meta,
    required this.faltan,
    required this.porcentaje,
  });

  final int completadas;
  final int meta;
  final int faltan;
  final int porcentaje;

  factory ProgresoMensual.fromJson(Map<String, dynamic> json) {
    return ProgresoMensual(
      completadas: json['completadas'] as int? ?? 0,
      meta: json['meta'] as int? ?? 5,
      faltan: json['faltan'] as int? ?? 0,
      porcentaje: json['porcentaje'] as int? ?? 0,
    );
  }
}

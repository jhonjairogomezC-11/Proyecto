class RankingEntry {
  const RankingEntry({
    required this.posicion,
    required this.voluntarioId,
    required this.nombre,
    this.municipio,
    required this.puntos,
    required this.participaciones,
    this.fotoPerfil,
  });

  final int posicion;
  final String voluntarioId;
  final String nombre;
  final String? municipio;
  final int puntos;
  final int participaciones;
  final String? fotoPerfil;

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      posicion: json['posicion'] as int? ?? 0,
      voluntarioId: json['voluntario_id'].toString(),
      nombre: json['nombre'] as String? ?? '',
      municipio: json['municipio'] as String?,
      puntos: json['puntos'] as int? ?? 0,
      participaciones: json['participaciones'] as int? ?? 0,
      fotoPerfil: json['foto_perfil'] as String?,
    );
  }
}

class RankingResponse {
  const RankingResponse({
    this.top = const [],
    this.miPosicion,
    this.total = 0,
  });

  final List<RankingEntry> top;
  final RankingEntry? miPosicion;
  final int total;

  bool miPosicionFueraDelTop(String? voluntarioId) {
    if (miPosicion == null || voluntarioId == null) return false;
    return !top.any((e) => e.voluntarioId == voluntarioId);
  }

  factory RankingResponse.fromJson(Map<String, dynamic> json) {
    RankingEntry? miPosicion;
    if (json['mi_posicion'] is Map<String, dynamic>) {
      miPosicion =
          RankingEntry.fromJson(json['mi_posicion'] as Map<String, dynamic>);
    }

    return RankingResponse(
      top: (json['top'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RankingEntry.fromJson)
          .toList(),
      miPosicion: miPosicion,
      total: json['total'] as int? ?? 0,
    );
  }
}

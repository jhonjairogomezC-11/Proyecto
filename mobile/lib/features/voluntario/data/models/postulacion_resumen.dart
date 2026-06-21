class PostulacionResumen {
  const PostulacionResumen({
    required this.id,
    required this.estado,
    this.publicacion,
  });

  final String id;
  final String estado;
  final PublicacionResumen? publicacion;

  factory PostulacionResumen.fromJson(Map<String, dynamic> json) {
    return PostulacionResumen(
      id: json['id']?.toString() ?? '',
      estado: _enumValue(json['estado']),
      publicacion: json['publicacion'] is Map<String, dynamic>
          ? PublicacionResumen.fromJson(
              json['publicacion'] as Map<String, dynamic>)
          : null,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value.toString();
  }
}

class PublicacionResumen {
  const PublicacionResumen({
    required this.titulo,
    this.fechaInicio,
    this.fundacionNombre,
  });

  final String titulo;
  final String? fechaInicio;
  final String? fundacionNombre;

  factory PublicacionResumen.fromJson(Map<String, dynamic> json) {
    String? fundacion;
    final fundacionJson = json['fundacion'];
    if (fundacionJson is Map<String, dynamic>) {
      fundacion = fundacionJson['nombre'] as String?;
    }

    return PublicacionResumen(
      titulo: json['titulo'] as String? ?? '',
      fechaInicio: json['fecha_inicio']?.toString(),
      fundacionNombre: fundacion,
    );
  }
}

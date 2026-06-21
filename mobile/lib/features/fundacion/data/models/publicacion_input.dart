class PublicacionInput {
  const PublicacionInput({
    required this.titulo,
    required this.descripcion,
    required this.categoriaId,
    required this.modalidad,
    required this.fechaInicio,
    required this.fechaFin,
    required this.cupoMaximo,
    this.municipioId,
    this.direccionExacta,
    this.enlaceVirtual,
    this.horaInicio,
    this.horaFin,
    this.edadMinima,
    this.edadMaxima,
    this.requisitosAdicionales,
    this.habilidades = const [],
  });

  final String titulo;
  final String descripcion;
  final int categoriaId;
  final String modalidad;
  final String fechaInicio;
  final String fechaFin;
  final int cupoMaximo;
  final int? municipioId;
  final String? direccionExacta;
  final String? enlaceVirtual;
  final String? horaInicio;
  final String? horaFin;
  final int? edadMinima;
  final int? edadMaxima;
  final String? requisitosAdicionales;
  final List<int> habilidades;

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'modalidad': modalidad,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'cupo_maximo': cupoMaximo,
      if (municipioId != null) 'municipio_id': municipioId,
      if (direccionExacta != null && direccionExacta!.isNotEmpty) 'direccion_exacta': direccionExacta,
      if (enlaceVirtual != null && enlaceVirtual!.isNotEmpty) 'enlace_virtual': enlaceVirtual,
      if (horaInicio != null && horaInicio!.isNotEmpty) 'hora_inicio': horaInicio,
      if (horaFin != null && horaFin!.isNotEmpty) 'hora_fin': horaFin,
      if (edadMinima != null) 'edad_minima': edadMinima,
      if (edadMaxima != null) 'edad_maxima': edadMaxima,
      if (requisitosAdicionales != null && requisitosAdicionales!.isNotEmpty)
        'requisitos_adicionales': requisitosAdicionales,
      if (habilidades.isNotEmpty) 'habilidades': habilidades,
    };
  }
}

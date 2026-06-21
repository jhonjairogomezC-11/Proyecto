import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';

class PublicacionImagen {
  const PublicacionImagen({this.id, required this.url, this.orden = 0});

  final String? id;
  final String url;
  final int orden;

  factory PublicacionImagen.fromJson(Map<String, dynamic> json) {
    return PublicacionImagen(
      id: json['id']?.toString(),
      url: json['url'] as String? ?? '',
      orden: json['orden'] as int? ?? 0,
    );
  }
}

class Publicacion {
  const Publicacion({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.modalidad,
    this.fechaInicio,
    this.fechaFin,
    this.cupoMaximo,
    this.fundacionId,
    this.fundacionNombre,
    this.categoriaNombre,
    this.municipio,
    this.imagenes = const [],
    this.imagenPrincipal,
    this.habilidades = const [],
    this.horaInicio,
    this.horaFin,
    this.direccionExacta,
    this.enlaceVirtual,
    this.edadMinima,
    this.edadMaxima,
    this.requisitosAdicionales,
    this.contactoNombre,
    this.contactoEmail,
    this.contactoTelefono,
    this.estado,
    this.categoriaId,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final String modalidad;
  final String? fechaInicio;
  final String? fechaFin;
  final int? cupoMaximo;
  final String? fundacionId;
  final String? fundacionNombre;
  final String? categoriaNombre;
  final Municipio? municipio;
  final List<PublicacionImagen> imagenes;
  final String? imagenPrincipal;
  final List<CatalogItem> habilidades;
  final String? horaInicio;
  final String? horaFin;
  final String? direccionExacta;
  final String? enlaceVirtual;
  final int? edadMinima;
  final int? edadMaxima;
  final String? requisitosAdicionales;
  final String? contactoNombre;
  final String? contactoEmail;
  final String? contactoTelefono;
  final String? estado;
  final int? categoriaId;

  List<String> get imageUrls {
    if (imagenes.isNotEmpty) {
      return imagenes.map((i) => i.url).where((u) => u.isNotEmpty).toList();
    }
    if (imagenPrincipal != null && imagenPrincipal!.isNotEmpty) {
      return [imagenPrincipal!];
    }
    return const [];
  }

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    Municipio? municipio;
    if (json['municipio'] is Map<String, dynamic>) {
      municipio = Municipio.fromJson(json['municipio'] as Map<String, dynamic>);
    }

    String? fundacionId;
    String? fundacionNombre;
    final fundacion = json['fundacion'];
    if (fundacion is Map<String, dynamic>) {
      fundacionId = fundacion['id']?.toString();
      fundacionNombre = fundacion['nombre'] as String?;
    }

    String? categoriaNombre;
    int? categoriaId;
    final categoria = json['categoria'];
    if (categoria is Map<String, dynamic>) {
      categoriaNombre = categoria['nombre'] as String?;
      categoriaId = categoria['id'] as int?;
    }

    List<PublicacionImagen> imagenes = [];
    if (json['imagenes'] is List) {
      imagenes = (json['imagenes'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PublicacionImagen.fromJson)
          .toList();
    }

    return Publicacion(
      id: json['id'].toString(),
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      modalidad: _enumValue(json['modalidad']),
      fechaInicio: json['fecha_inicio']?.toString(),
      fechaFin: json['fecha_fin']?.toString(),
      cupoMaximo: json['cupo_maximo'] as int?,
      fundacionId: fundacionId,
      fundacionNombre: fundacionNombre,
      categoriaNombre: categoriaNombre,
      municipio: municipio,
      imagenes: imagenes,
      imagenPrincipal: json['imagen'] as String?,
      habilidades: (json['habilidades'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogItem.fromJson)
          .toList(),
      horaInicio: json['hora_inicio']?.toString(),
      horaFin: json['hora_fin']?.toString(),
      direccionExacta: json['direccion_exacta'] as String?,
      enlaceVirtual: json['enlace_virtual'] as String?,
      edadMinima: json['edad_minima'] as int?,
      edadMaxima: json['edad_maxima'] as int?,
      requisitosAdicionales: json['requisitos_adicionales'] as String?,
      contactoNombre: json['contacto_nombre'] as String?,
      contactoEmail: json['contacto_email'] as String?,
      contactoTelefono: json['contacto_telefono'] as String?,
      estado: _enumValue(json['estado']).isEmpty
          ? null
          : _enumValue(json['estado']),
      categoriaId: categoriaId ?? json['categoria_id'] as int?,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value?.toString() ?? '';
  }
}

class PublicacionFilters {
  const PublicacionFilters({
    this.buscar = '',
    this.categoriaId,
    this.modalidad,
    this.municipioId,
  });

  final String buscar;
  final int? categoriaId;
  final String? modalidad;
  final int? municipioId;

  PublicacionFilters copyWith({
    String? buscar,
    int? categoriaId,
    String? modalidad,
    int? municipioId,
    bool clearCategoria = false,
    bool clearModalidad = false,
    bool clearMunicipio = false,
  }) {
    return PublicacionFilters(
      buscar: buscar ?? this.buscar,
      categoriaId: clearCategoria ? null : (categoriaId ?? this.categoriaId),
      modalidad: clearModalidad ? null : (modalidad ?? this.modalidad),
      municipioId: clearMunicipio ? null : (municipioId ?? this.municipioId),
    );
  }

  Map<String, dynamic> toQueryParams({required int page}) {
    return {
      'page': page,
      if (buscar.isNotEmpty) 'buscar': buscar,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (modalidad != null && modalidad!.isNotEmpty) 'modalidad': modalidad,
      if (municipioId != null) 'municipio_id': municipioId,
    };
  }
}

import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';

class FundacionPerfil {
  const FundacionPerfil({
    required this.id,
    required this.nombre,
    required this.nit,
    required this.representanteLegal,
    required this.telefono,
    required this.direccion,
    required this.descripcion,
    required this.estadoVerificacion,
    this.correoInstitucional,
    this.paginaWeb,
    this.logo,
    this.municipio,
    this.areas = const [],
    this.motivoRechazo,
  });

  final String id;
  final String nombre;
  final String nit;
  final String representanteLegal;
  final String telefono;
  final String direccion;
  final String descripcion;
  final String estadoVerificacion;
  final String? correoInstitucional;
  final String? paginaWeb;
  final String? logo;
  final Municipio? municipio;
  final List<CatalogItem> areas;
  final String? motivoRechazo;

  bool get isAprobada => estadoVerificacion == 'APROBADA';
  bool get isPendiente => estadoVerificacion == 'PENDIENTE';
  bool get isRechazada => estadoVerificacion == 'RECHAZADA';

  factory FundacionPerfil.fromJson(Map<String, dynamic> json) {
    Municipio? municipio;
    if (json['municipio'] is Map<String, dynamic>) {
      municipio = Municipio.fromJson(json['municipio'] as Map<String, dynamic>);
    }

    return FundacionPerfil(
      id: json['id'].toString(),
      nombre: json['nombre'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      representanteLegal: json['representante_legal'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      estadoVerificacion: _enumValue(json['estado_verificacion']),
      correoInstitucional: json['correo_institucional'] as String?,
      paginaWeb: json['pagina_web'] as String?,
      logo: json['logo'] as String?,
      municipio: municipio,
      areas: (json['areas'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CatalogItem.fromJson)
          .toList(),
      motivoRechazo: json['motivo_rechazo'] as String?,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value?.toString() ?? '';
  }
}

class FundacionPerfilInput {
  const FundacionPerfilInput({
    required this.nombre,
    required this.nit,
    required this.representanteLegal,
    required this.telefono,
    required this.direccion,
    required this.municipioId,
    required this.descripcion,
    required this.documentoLegal,
    this.correoInstitucional,
    this.paginaWeb,
    this.areas = const [],
  });

  final String nombre;
  final String nit;
  final String representanteLegal;
  final String telefono;
  final String direccion;
  final int municipioId;
  final String descripcion;
  final String documentoLegal;
  final String? correoInstitucional;
  final String? paginaWeb;
  final List<int> areas;

  Map<String, dynamic> toJson({bool includeNit = true}) {
    return {
      'nombre': nombre,
      if (includeNit) 'nit': nit,
      'representante_legal': representanteLegal,
      'telefono': telefono,
      'direccion': direccion,
      'municipio_id': municipioId,
      'descripcion': descripcion,
      'documento_legal': documentoLegal,
      if (correoInstitucional != null && correoInstitucional!.isNotEmpty)
        'correo_institucional': correoInstitucional,
      if (paginaWeb != null && paginaWeb!.isNotEmpty) 'pagina_web': paginaWeb,
      if (areas.isNotEmpty) 'areas': areas,
    };
  }
}

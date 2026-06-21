import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';

class VoluntarioPerfil {
  const VoluntarioPerfil({
    required this.id,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.fechaNacimiento,
    required this.genero,
    required this.disponibilidad,
    this.experiencia,
    this.fotoPerfil,
    this.documentoIdentidad,
    this.estaVerificado = false,
    this.municipio,
    this.habilidades = const [],
    this.intereses = const [],
  });

  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String fechaNacimiento;
  final String genero;
  final String disponibilidad;
  final String? experiencia;
  final String? fotoPerfil;
  final String? documentoIdentidad;
  final bool estaVerificado;
  final Municipio? municipio;
  final List<CatalogItem> habilidades;
  final List<CatalogItem> intereses;

  factory VoluntarioPerfil.fromJson(Map<String, dynamic> json) {
    return VoluntarioPerfil(
      id: json['id'].toString(),
      tipoDocumento: _enumValue(json['tipo_documento']),
      numeroDocumento: json['numero_documento'] as String,
      fechaNacimiento: json['fecha_nacimiento'] as String,
      genero: _enumValue(json['genero']),
      disponibilidad: _enumValue(json['disponibilidad']),
      experiencia: json['experiencia'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      documentoIdentidad: json['documento_identidad'] as String?,
      estaVerificado: json['esta_verificado'] == true,
      municipio: json['municipio'] is Map<String, dynamic>
          ? Municipio.fromJson(json['municipio'] as Map<String, dynamic>)
          : null,
      habilidades: _parseItems(json['habilidades']),
      intereses: _parseItems(json['intereses']),
    );
  }

  Map<String, dynamic> toPayload() => {
        'tipo_documento': tipoDocumento,
        'numero_documento': numeroDocumento,
        'fecha_nacimiento': fechaNacimiento,
        'genero': genero,
        'municipio_id': municipio?.id,
        'disponibilidad': disponibilidad,
        'experiencia': experiencia,
        'habilidades': habilidades.map((h) => h.id).toList(),
        'intereses': intereses.map((i) => i.id).toList(),
      };

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value.toString();
  }

  static List<CatalogItem> _parseItems(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CatalogItem.fromJson)
        .toList();
  }
}

class VoluntarioPerfilInput {
  const VoluntarioPerfilInput({
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.fechaNacimiento,
    required this.genero,
    required this.municipioId,
    required this.disponibilidad,
    this.experiencia,
    this.habilidades = const [],
    this.intereses = const [],
  });

  final String tipoDocumento;
  final String numeroDocumento;
  final String fechaNacimiento;
  final String genero;
  final int municipioId;
  final String disponibilidad;
  final String? experiencia;
  final List<int> habilidades;
  final List<int> intereses;

  Map<String, dynamic> toJson() => {
        'tipo_documento': tipoDocumento,
        'numero_documento': numeroDocumento,
        'fecha_nacimiento': fechaNacimiento,
        'genero': genero,
        'municipio_id': municipioId,
        'disponibilidad': disponibilidad,
        'experiencia': experiencia,
        'habilidades': habilidades,
        'intereses': intereses,
      };
}

abstract final class VoluntarioOptions {
  static const tiposDocumento = ['CC', 'TI', 'CE', 'PASAPORTE'];

  static const generos = [
    ('MASCULINO', 'Masculino'),
    ('FEMENINO', 'Femenino'),
    ('OTRO', 'Otro'),
  ];

  static const disponibilidades = [
    ('ENTRE_SEMANA', 'Entre semana'),
    ('FINES_DE_SEMANA', 'Fines de semana'),
    ('FLEXIBLE', 'Flexible'),
  ];

  static String labelGenero(String value) {
    return generos
        .firstWhere((g) => g.$1 == value, orElse: () => (value, value))
        .$2;
  }

  static String labelDisponibilidad(String value) {
    return disponibilidades
        .firstWhere((d) => d.$1 == value, orElse: () => (value, value))
        .$2;
  }
}

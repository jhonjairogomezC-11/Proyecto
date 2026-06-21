import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

class FavoritoFundacion {
  const FavoritoFundacion({
    required this.id,
    required this.nombre,
    this.logo,
    this.municipio,
  });

  final String id;
  final String nombre;
  final String? logo;
  final Municipio? municipio;

  factory FavoritoFundacion.fromJson(Map<String, dynamic> json) {
    Municipio? municipio;
    if (json['municipio'] is Map<String, dynamic>) {
      municipio = Municipio.fromJson(json['municipio'] as Map<String, dynamic>);
    }

    return FavoritoFundacion(
      id: json['id'].toString(),
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      municipio: municipio,
    );
  }
}

class Favorito {
  const Favorito({
    required this.id,
    required this.tipo,
    this.fechaCreacion,
    this.publicacion,
    this.fundacion,
  });

  final String id;
  final String tipo;
  final String? fechaCreacion;
  final Publicacion? publicacion;
  final FavoritoFundacion? fundacion;

  bool get esPublicacion => tipo == 'PUBLICACION';
  bool get esFundacion => tipo == 'FUNDACION';

  factory Favorito.fromJson(Map<String, dynamic> json) {
    Publicacion? publicacion;
    if (json['publicacion'] is Map<String, dynamic>) {
      publicacion =
          Publicacion.fromJson(json['publicacion'] as Map<String, dynamic>);
    }

    FavoritoFundacion? fundacion;
    if (json['fundacion'] is Map<String, dynamic>) {
      fundacion =
          FavoritoFundacion.fromJson(json['fundacion'] as Map<String, dynamic>);
    }

    return Favorito(
      id: json['id'].toString(),
      tipo: _enumValue(json['tipo']),
      fechaCreacion: json['fecha_creacion']?.toString(),
      publicacion: publicacion,
      fundacion: fundacion,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String)
      return value['value'] as String;
    return value?.toString() ?? '';
  }
}

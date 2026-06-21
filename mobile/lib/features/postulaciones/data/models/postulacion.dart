import 'package:voluntapp_mobile/features/fundacion/data/models/postulacion_voluntario_resumen.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

class Postulacion {
  const Postulacion({
    required this.id,
    required this.estado,
    this.mensajeVoluntario,
    this.motivoRechazo,
    this.calificacion,
    this.comentarioFundacion,
    this.fechaPostulacion,
    this.fechaRespuesta,
    this.fechaConfirmacion,
    this.publicacion,
    this.publicacionId,
    this.voluntario,
  });

  final String id;
  final String estado;
  final String? mensajeVoluntario;
  final String? motivoRechazo;
  final int? calificacion;
  final String? comentarioFundacion;
  final String? fechaPostulacion;
  final String? fechaRespuesta;
  final String? fechaConfirmacion;
  final Publicacion? publicacion;
  final String? publicacionId;
  final PostulacionVoluntarioResumen? voluntario;

  bool get puedeRetirar => estado == 'PENDIENTE' || estado == 'ACEPTADO';
  bool get activa => !['RETIRADO', 'RECHAZADO'].contains(estado);

  factory Postulacion.fromJson(Map<String, dynamic> json) {
    Publicacion? pub;
    if (json['publicacion'] is Map<String, dynamic>) {
      pub = Publicacion.fromJson(json['publicacion'] as Map<String, dynamic>);
    }

    PostulacionVoluntarioResumen? voluntario;
    if (json['voluntario'] is Map<String, dynamic>) {
      voluntario = PostulacionVoluntarioResumen.fromJson(json['voluntario'] as Map<String, dynamic>);
    }

    return Postulacion(
      id: json['id'].toString(),
      estado: _enumValue(json['estado']),
      mensajeVoluntario: json['mensaje_voluntario'] as String?,
      motivoRechazo: json['motivo_rechazo'] as String?,
      calificacion: json['calificacion'] as int?,
      comentarioFundacion: json['comentario_fundacion'] as String?,
      fechaPostulacion: json['fecha_postulacion']?.toString(),
      fechaRespuesta: json['fecha_respuesta']?.toString(),
      fechaConfirmacion: json['fecha_confirmacion']?.toString(),
      publicacion: pub,
      publicacionId: pub?.id ?? json['publicacion_id']?.toString(),
      voluntario: voluntario,
    );
  }

  static String _enumValue(dynamic value) {
    if (value is String) return value;
    if (value is Map && value['value'] is String) return value['value'] as String;
    return value?.toString() ?? '';
  }
}

import 'package:voluntapp_mobile/features/voluntario/data/models/voluntario_perfil.dart';

class AdminVoluntarioItem {
  const AdminVoluntarioItem({
    required this.perfil,
    this.nombreUsuario,
    this.emailUsuario,
    this.estadoUsuario,
  });

  final VoluntarioPerfil perfil;
  final String? nombreUsuario;
  final String? emailUsuario;
  final String? estadoUsuario;

  String get id => perfil.id;

  factory AdminVoluntarioItem.fromJson(Map<String, dynamic> json) {
    final perfil = VoluntarioPerfil.fromJson(json);
    String? nombre;
    String? email;
    String? estado;

    final usuario = json['usuario'];
    if (usuario is Map<String, dynamic>) {
      nombre = usuario['nombre'] as String?;
      email = usuario['email'] as String?;
      estado = _enumValue(usuario['estado']);
    }

    return AdminVoluntarioItem(
      perfil: perfil,
      nombreUsuario: nombre,
      emailUsuario: email,
      estadoUsuario: estado,
    );
  }

  static String? _enumValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['value'] is String) return value['value'] as String;
    return value.toString();
  }
}

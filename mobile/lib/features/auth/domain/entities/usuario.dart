class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.estado,
    this.telefono,
    this.emailVerificado = false,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? estado;
  final String? telefono;
  final bool emailVerificado;

  bool get isVoluntario => rol == 'VOLUNTARIO';
  bool get isFundacion => rol == 'FUNDACION';
  bool get isAdmin => rol == 'ADMIN';
  bool get isSuspendido => estado == 'SUSPENDIDO';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'].toString(),
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rol: _parseEnumField(json['rol']) ?? 'VOLUNTARIO',
      estado: _parseEnumField(json['estado']),
      telefono: json['telefono'] as String?,
      emailVerificado: json['email_verificado'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'estado': estado,
        'telefono': telefono,
        'email_verificado': emailVerificado,
      };

  static String? _parseEnumField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['value'] is String) {
      return value['value'] as String;
    }
    return value.toString();
  }
}

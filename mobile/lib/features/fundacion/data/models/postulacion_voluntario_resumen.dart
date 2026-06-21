class PostulacionVoluntarioResumen {
  const PostulacionVoluntarioResumen({
    required this.id,
    this.nombreUsuario,
    this.emailUsuario,
  });

  final String id;
  final String? nombreUsuario;
  final String? emailUsuario;

  factory PostulacionVoluntarioResumen.fromJson(Map<String, dynamic> json) {
    String? nombre;
    String? email;
    final usuario = json['usuario'];
    if (usuario is Map<String, dynamic>) {
      nombre = usuario['nombre'] as String?;
      email = usuario['email'] as String?;
    }

    return PostulacionVoluntarioResumen(
      id: json['id'].toString(),
      nombreUsuario: nombre,
      emailUsuario: email,
    );
  }
}

import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';

class AuthSession {
  const AuthSession({
    required this.usuario,
    required this.accessToken,
    required this.refreshToken,
  });

  final Usuario usuario;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
      accessToken: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}

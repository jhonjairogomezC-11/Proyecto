import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/auth/data/models/auth_session.dart';
import 'package:voluntapp_mobile/features/auth/domain/entities/usuario.dart';
import 'package:voluntapp_mobile/features/auth/presentation/utils/auth_validators.dart';

void main() {
  group('AuthSession', () {
    test('fromJson parsea respuesta del backend', () {
      final session = AuthSession.fromJson({
        'usuario': {
          'id': 'abc-123',
          'nombre': 'Juan',
          'email': 'juan@demo.com',
          'rol': 'VOLUNTARIO',
          'estado': 'ACTIVO',
          'email_verificado': true,
        },
        'token': 'access-token',
        'refresh_token': 'refresh-token',
      });

      expect(session.accessToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.usuario.nombre, 'Juan');
      expect(session.usuario.isVoluntario, isTrue);
    });
  });

  group('Usuario', () {
    test('fromJson normaliza rol como objeto enum', () {
      final user = Usuario.fromJson({
        'id': 1,
        'nombre': 'Ana',
        'email': 'ana@demo.com',
        'rol': {'value': 'FUNDACION'},
        'estado': {'value': 'ACTIVO'},
      });

      expect(user.id, '1');
      expect(user.rol, 'FUNDACION');
      expect(user.estado, 'ACTIVO');
      expect(user.isFundacion, isTrue);
    });
  });

  group('AuthValidators', () {
    test('email rechaza formato invalido', () {
      expect(AuthValidators.email('invalido'), isNotNull);
      expect(AuthValidators.email('ok@demo.com'), isNull);
    });

    test('password exige minimo 8 caracteres', () {
      expect(AuthValidators.password('123'), isNotNull);
      expect(AuthValidators.password('12345678'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/core/network/api_exception.dart';

void main() {
  group('ApiException', () {
    test('ValidationException guarda errores por campo', () {
      const ex = ValidationException({'email': 'Email inválido'});
      expect(ex.errors['email'], 'Email inválido');
      expect(ex.message, contains('válidos'));
    });
  });
}

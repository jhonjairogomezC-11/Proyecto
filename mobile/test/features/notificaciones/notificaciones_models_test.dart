import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/notificaciones/data/models/notificacion.dart';
import 'package:voluntapp_mobile/features/notificaciones/presentation/utils/notificacion_utils.dart';

void main() {
  group('Notificacion', () {
    test('fromJson parsea campos del backend', () {
      final n = Notificacion.fromJson({
        'id': 'n1',
        'tipo': 'POSTULACION_ACEPTADA',
        'mensaje': 'Tu postulación fue aceptada',
        'leida': false,
        'objeto_tipo': 'POSTULACION',
        'objeto_id': 'p1',
        'fecha_creacion': '2026-06-20T10:00:00.000000Z',
      });

      expect(n.tipo, 'POSTULACION_ACEPTADA');
      expect(n.leida, isFalse);
      expect(n.objetoId, 'p1');
    });

    test('copyWith actualiza leida', () {
      const n = Notificacion(id: '1', tipo: 'X', mensaje: 'Hola', leida: false);
      expect(n.copyWith(leida: true).leida, isTrue);
    });
  });

  group('formatRelativeNotificacion', () {
    test('retorna Ahora mismo para fechas recientes', () {
      final now = DateTime.now().toUtc().toIso8601String();
      expect(formatRelativeNotificacion(now), 'Ahora mismo');
    });
  });
}

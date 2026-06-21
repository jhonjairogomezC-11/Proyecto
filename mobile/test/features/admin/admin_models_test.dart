import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_historial_item.dart';
import 'package:voluntapp_mobile/features/admin/data/models/admin_voluntario_item.dart';
import 'package:voluntapp_mobile/features/admin/data/models/reporte.dart';
import 'package:voluntapp_mobile/features/reportes/data/repositories/reporte_repository.dart';

void main() {
  group('Reporte', () {
    test('fromJson parsea enums y reportante', () {
      final reporte = Reporte.fromJson({
        'id': 'r1',
        'motivo': 'INFORMACION_FALSA',
        'estado': 'PENDIENTE',
        'objeto_tipo': 'PUBLICACION',
        'objeto_id': 'p1',
        'detalle': 'Detalle del reporte',
        'fecha_creacion': '2026-06-20T10:00:00',
        'reportante': {'nombre': 'Juan'},
      });

      expect(reporte.isPendiente, isTrue);
      expect(reporte.reportanteNombre, 'Juan');
      expect(ReporteMotivos.label(reporte.motivo), 'Información falsa');
    });
  });

  group('AdminVoluntarioItem', () {
    test('fromJson incluye datos de usuario', () {
      final item = AdminVoluntarioItem.fromJson({
        'id': 'v1',
        'tipo_documento': 'CC',
        'numero_documento': '123',
        'fecha_nacimiento': '2000-01-01',
        'genero': 'MASCULINO',
        'disponibilidad': 'FLEXIBLE',
        'usuario': {
          'nombre': 'Pedro Voluntario',
          'email': 'pedro@demo.com',
          'estado': 'ACTIVO',
        },
      });

      expect(item.nombreUsuario, 'Pedro Voluntario');
      expect(item.estadoUsuario, 'ACTIVO');
      expect(item.perfil.numeroDocumento, '123');
    });
  });

  group('AdminHistorialItem', () {
    test('fromFundacionJson parsea cambios de estado', () {
      final item = AdminHistorialItem.fromFundacionJson({
        'fecha': '2026-06-01',
        'estado_anterior': 'PENDIENTE',
        'estado_nuevo': 'APROBADA',
        'motivo': null,
        'admin': {'usuario': {'nombre': 'Admin'}},
      });

      expect(item.titulo, contains('PENDIENTE'));
      expect(item.adminNombre, 'Admin');
    });

    test('fromVoluntarioJson parsea sanciones', () {
      final item = AdminHistorialItem.fromVoluntarioJson({
        'tipo': 'SANCION',
        'fecha': '2026-06-01',
        'estado_anterior': 'ACTIVO',
        'estado_nuevo': 'SUSPENDIDO',
        'motivo': 'Incumplimiento',
        'admin': 'Admin Demo',
      });

      expect(item.tipo, 'SANCION');
      expect(item.adminNombre, 'Admin Demo');
    });
  });

  group('ReporteInput', () {
    test('toJson incluye campos requeridos', () {
      const input = ReporteInput(
        objetoTipo: 'PUBLICACION',
        objetoId: 'p1',
        motivo: 'OTRO',
        detalle: 'Detalle',
      );

      final json = input.toJson();
      expect(json['objeto_tipo'], 'PUBLICACION');
      expect(json['motivo'], 'OTRO');
    });
  });
}

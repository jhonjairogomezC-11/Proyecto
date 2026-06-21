import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/fundacion_perfil.dart';
import 'package:voluntapp_mobile/features/fundacion/data/models/publicacion_input.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

void main() {
  group('FundacionPerfil', () {
    test('fromJson parsea estado y areas', () {
      final perfil = FundacionPerfil.fromJson({
        'id': 'f1',
        'nombre': 'Fundación Demo',
        'nit': '900123456-1',
        'representante_legal': 'Ana',
        'telefono': '300',
        'direccion': 'Calle 1',
        'descripcion': 'Desc',
        'estado_verificacion': 'APROBADA',
        'areas': [
          {'id': 1, 'nombre': 'Educación'}
        ],
      });

      expect(perfil.isAprobada, isTrue);
      expect(perfil.areas.first.nombre, 'Educación');
    });
  });

  group('PublicacionInput', () {
    test('toJson incluye campos requeridos', () {
      const input = PublicacionInput(
        titulo: 'Taller',
        descripcion: 'Desc',
        categoriaId: 2,
        modalidad: 'VIRTUAL',
        fechaInicio: '2026-07-01',
        fechaFin: '2026-07-02',
        cupoMaximo: 10,
      );

      final json = input.toJson();
      expect(json['titulo'], 'Taller');
      expect(json['categoria_id'], 2);
      expect(json.containsKey('municipio_id'), isFalse);
    });
  });

  group('Publicacion estado', () {
    test('fromJson parsea estado de publicacion', () {
      final pub = Publicacion.fromJson({
        'id': '1',
        'titulo': 'A',
        'descripcion': 'B',
        'modalidad': 'PRESENCIAL',
        'estado': 'BORRADOR',
        'categoria': {'id': 3, 'nombre': 'Salud'},
      });

      expect(pub.estado, 'BORRADOR');
      expect(pub.categoriaId, 3);
    });
  });
}

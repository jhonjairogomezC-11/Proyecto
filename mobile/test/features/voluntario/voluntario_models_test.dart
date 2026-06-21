import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/catalog/data/models/catalog_models.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/voluntario_perfil.dart';

void main() {
  group('Catalog models', () {
    test('Municipio parsea departamento anidado', () {
      final m = Municipio.fromJson({
        'id': 1,
        'nombre': 'Medellín',
        'departamento': {'id': 5, 'nombre': 'Antioquia'},
      });

      expect(m.departamento?.nombre, 'Antioquia');
    });
  });

  group('VoluntarioPerfil', () {
    test('fromJson parsea perfil completo', () {
      final perfil = VoluntarioPerfil.fromJson({
        'id': 'uuid-1',
        'tipo_documento': 'CC',
        'numero_documento': '123456',
        'fecha_nacimiento': '2000-01-15',
        'genero': 'MASCULINO',
        'disponibilidad': 'FLEXIBLE',
        'experiencia': 'Voluntariado escolar',
        'municipio': {
          'id': 1,
          'nombre': 'Bogotá',
          'departamento': {'id': 11, 'nombre': 'Cundinamarca'},
        },
        'habilidades': [
          {'id': 1, 'nombre': 'Comunicación'}
        ],
        'intereses': [
          {'id': 2, 'nombre': 'Medio ambiente'}
        ],
      });

      expect(perfil.numeroDocumento, '123456');
      expect(perfil.habilidades.first.nombre, 'Comunicación');
      expect(perfil.municipio?.departamento?.nombre, 'Cundinamarca');
    });

    test('VoluntarioPerfilInput serializa payload API', () {
      const input = VoluntarioPerfilInput(
        tipoDocumento: 'CC',
        numeroDocumento: '999',
        fechaNacimiento: '2000-05-01',
        genero: 'FEMENINO',
        municipioId: 3,
        disponibilidad: 'ENTRE_SEMANA',
        habilidades: [1, 2],
        intereses: [3],
      );

      expect(input.toJson()['municipio_id'], 3);
      expect(input.toJson()['habilidades'], [1, 2]);
    });
  });
}

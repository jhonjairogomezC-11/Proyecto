import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/favoritos/data/models/favorito.dart';
import 'package:voluntapp_mobile/features/logros/data/models/logros_models.dart';
import 'package:voluntapp_mobile/features/ranking/data/models/ranking.dart';

void main() {
  group('Favorito', () {
    test('fromJson parsea publicacion anidada', () {
      final fav = Favorito.fromJson({
        'id': 'f1',
        'tipo': 'PUBLICACION',
        'publicacion': {
          'id': 'p1',
          'titulo': 'Taller',
          'descripcion': 'Desc',
          'modalidad': 'VIRTUAL',
        },
      });

      expect(fav.esPublicacion, isTrue);
      expect(fav.publicacion?.titulo, 'Taller');
    });
  });

  group('LogrosDetalle', () {
    test('fromJson parsea obtenidos y pendientes', () {
      final data = LogrosDetalle.fromJson({
        'obtenidos': [
          {
            'id': 1,
            'codigo': 'PRIMER_PASO',
            'nombre': 'Primer paso',
            'fecha_obtencion': '2026-01-01',
          },
        ],
        'pendientes': [
          {
            'id': 2,
            'codigo': 'VETERANO',
            'nombre': 'Veterano',
            'progreso': 3,
            'umbral': 10,
            'porcentaje': 30,
          },
        ],
      });

      expect(data.obtenidos.length, 1);
      expect(data.pendientes.first.porcentaje, 30);
    });
  });

  group('PuntosDetalle', () {
    test('fromJson parsea transacciones', () {
      final data = PuntosDetalle.fromJson({
        'saldo': 120,
        'total_historico': 500,
        'transacciones': [
          {'id': 't1', 'puntos_total': 50, 'motivo': 'Asistió a actividad'},
        ],
      });

      expect(data.saldo, 120);
      expect(data.transacciones.first.puntosTotal, 50);
    });
  });

  group('RankingResponse', () {
    test('miPosicionFueraDelTop detecta cuando no está en top', () {
      final response = RankingResponse.fromJson({
        'top': [
          {
            'posicion': 1,
            'voluntario_id': 'v-other',
            'nombre': 'Ana',
            'puntos': 100,
            'participaciones': 5,
          },
        ],
        'mi_posicion': {
          'posicion': 12,
          'voluntario_id': 'v-me',
          'nombre': 'Yo',
          'puntos': 20,
          'participaciones': 1,
        },
        'total': 50,
      });

      expect(response.miPosicionFueraDelTop('v-me'), isTrue);
      expect(response.miPosicionFueraDelTop('v-other'), isFalse);
    });
  });
}

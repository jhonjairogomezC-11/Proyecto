import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/dashboard_voluntario.dart';
import 'package:voluntapp_mobile/features/voluntario/data/models/postulacion_resumen.dart';

void main() {
  group('DashboardVoluntario', () {
    test('fromJson parsea respuesta del backend', () {
      final dash = DashboardVoluntario.fromJson({
        'perfil_completo': true,
        'actividades_completadas': {'total': 5, 'esta_semana': 1, 'este_mes': 2},
        'puntos': {'saldo': 100, 'total_historico': 1200},
        'nivel': {
          'nivel_actual': {'codigo': 'BRONCE', 'nombre': 'Bronce', 'color': '#cd7f32'},
          'nivel_siguiente': {'codigo': 'PLATA', 'nombre': 'Plata', 'color': '#94a3b8'},
          'puntos_faltan': 200,
          'umbral_siguiente': 1000,
          'porcentaje': 20,
        },
        'logros': {
          'desbloqueados': 2,
          'recientes': [
            {'id': 1, 'nombre': 'Primer paso', 'fecha_obtencion': '2026-01-01'},
          ],
        },
        'logro_proximo': {
          'nombre': 'Voluntario activo',
          'progreso': 3,
          'umbral': 5,
          'porcentaje': 60,
        },
        'ranking': {'posicion': 4, 'total': 50, 'top_percent': 92.0},
        'proximas_actividades': [
          {
            'id': 'post-1',
            'estado': 'ACEPTADO',
            'publicacion': {
              'titulo': 'Reforestación',
              'fecha_inicio': '2026-07-01',
              'fundacion': {'nombre': 'Fundación Verde'},
            },
          },
        ],
        'postulaciones_resumen': {
          'pendientes': 1,
          'aceptadas': 2,
          'rechazadas': 0,
          'completadas': 5,
        },
        'progreso_mensual': {
          'completadas': 2,
          'meta': 5,
          'faltan': 3,
          'porcentaje': 40,
        },
      });

      expect(dash.actividadesCompletadas.total, 5);
      expect(dash.nivel.nivelActual.nombre, 'Bronce');
      expect(dash.ranking.posicion, 4);
      expect(dash.proximasActividades.first.publicacion?.titulo, 'Reforestación');
      expect(dash.logroProximo?.nombre, 'Voluntario activo');
    });
  });

  group('PostulacionResumen', () {
    test('fromJson parsea publicacion anidada', () {
      final p = PostulacionResumen.fromJson({
        'id': 'abc',
        'estado': 'PENDIENTE',
        'publicacion': {
          'titulo': 'Taller',
          'fecha_inicio': '2026-06-01',
          'fundacion': {'nombre': 'Esperanza'},
        },
      });

      expect(p.estado, 'PENDIENTE');
      expect(p.publicacion?.fundacionNombre, 'Esperanza');
    });
  });
}

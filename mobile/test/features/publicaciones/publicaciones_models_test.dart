import 'package:flutter_test/flutter_test.dart';
import 'package:voluntapp_mobile/core/models/paginated_response.dart';
import 'package:voluntapp_mobile/core/utils/media_url.dart';
import 'package:voluntapp_mobile/features/postulaciones/data/models/postulacion.dart';
import 'package:voluntapp_mobile/features/publicaciones/data/models/publicacion.dart';

void main() {
  group('PaginatedResponse', () {
    test('fromJson parsea data y meta', () {
      final page = PaginatedResponse.fromJson({
        'data': [
          {
            'id': 'p1',
            'titulo': 'Taller',
            'descripcion': 'Desc',
            'modalidad': 'VIRTUAL'
          },
        ],
        'meta': {
          'current_page': 1,
          'last_page': 3,
          'per_page': 15,
          'total': 40
        },
      }, Publicacion.fromJson);

      expect(page.data.length, 1);
      expect(page.data.first.titulo, 'Taller');
      expect(page.meta.total, 40);
      expect(page.meta.hasMore, isTrue);
    });
  });

  group('Publicacion', () {
    test('imageUrls prioriza imagenes sobre imagen principal', () {
      final pub = Publicacion.fromJson({
        'id': '1',
        'titulo': 'A',
        'descripcion': 'B',
        'modalidad': 'PRESENCIAL',
        'imagen': '/storage/old.jpg',
        'imagenes': [
          {'id': 'i1', 'url': '/storage/new.jpg', 'orden': 0},
        ],
      });

      expect(pub.imageUrls, ['/storage/new.jpg']);
    });
  });

  group('Postulacion', () {
    test('puedeRetirar solo en pendiente o aceptado', () {
      expect(
          const Postulacion(id: '1', estado: 'PENDIENTE').puedeRetirar, isTrue);
      expect(
          const Postulacion(id: '1', estado: 'ASISTIO').puedeRetirar, isFalse);
    });
  });

  group('resolveMediaUrl', () {
    test('convierte path relativo usando api base', () {
      expect(
        resolveMediaUrl('/storage/foto.jpg', 'http://127.0.0.1:8000/api/v1'),
        'http://127.0.0.1:8000/storage/foto.jpg',
      );
    });
  });
}

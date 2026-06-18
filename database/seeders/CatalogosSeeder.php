<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CatalogosSeeder extends Seeder
{
    public function run(): void
    {
        // ── Cobertura geográfica: solo Bogotá D.C. y Cundinamarca ─
        $departamentos = [
            'Bogotá D.C.',
            'Cundinamarca',
        ];

        foreach ($departamentos as $nombre) {
            DB::table('departamentos')->insertOrIgnore(['nombre' => $nombre]);
        }

        $municipiosPorDepartamento = [
            'Bogotá D.C.' => [
                'Bogotá',
            ],
            'Cundinamarca' => [
                // Municipios del spec + los que ya existían
                'Soacha', 'Chía', 'Cajicá', 'Zipaquirá', 'Facatativá',
                'Funza', 'Mosquera', 'Madrid', 'Fusagasugá', 'Girardot',
                // Municipios adicionales Cundinamarca
                'La Calera', 'Sopó', 'Tocancipá', 'Gachancipá', 'Tabio',
                'Tenjo', 'Cota', 'Sibaté', 'Arbeláez', 'Pasca',
                'San Bernardo', 'Venecia', 'Ricaurte', 'Apulo', 'Tocaima',
                'Agua de Dios', 'Guataquí', 'Nilo', 'Villeta', 'Nimaima',
                'Nocaima', 'Quebradanegra', 'Utica',
            ],
        ];

        foreach ($municipiosPorDepartamento as $depNombre => $municipios) {
            $depId = DB::table('departamentos')->where('nombre', $depNombre)->value('id');
            if (!$depId) continue;
            foreach ($municipios as $municipio) {
                DB::table('municipios')->insertOrIgnore([
                    'nombre'          => $municipio,
                    'departamento_id' => $depId,
                ]);
            }
        }

        // ── Habilidades ───────────────────────────────────────────
        $habilidades = [
            'Educación', 'Tecnología', 'Salud', 'Medio Ambiente',
            'Arte', 'Deportes', 'Comunicación', 'Liderazgo', 'Idiomas', 'Cocina',
        ];
        foreach ($habilidades as $h) {
            DB::table('habilidades')->insertOrIgnore(['nombre' => $h]);
        }

        // ── Intereses ─────────────────────────────────────────────
        $intereses = [
            'Social', 'Ambiental', 'Educativo', 'Cultural',
            'Comunitario', 'Salud', 'Derechos Humanos', 'Infancia',
        ];
        foreach ($intereses as $i) {
            DB::table('intereses')->insertOrIgnore(['nombre' => $i]);
        }

        // ── Áreas de impacto ──────────────────────────────────────
        $areas = [
            'Educacion', 'Salud', 'Medio Ambiente', 'Derechos Humanos',
            'Infancia', 'Adulto Mayor', 'Discapacidad', 'Cultura',
            'Deportes', 'Tecnologia', 'Inclusion Social',
        ];
        foreach ($areas as $a) {
            DB::table('areas_impacto')->insertOrIgnore(['nombre' => $a]);
        }

        // ── Configuración del sistema ──────────────────────────────
        $config = [
            ['clave' => 'TOKEN_VERIFICACION_EMAIL_HORAS', 'valor_int'   => 24,   'descripcion' => 'Horas de vigencia del token de verificación de email.',      'modulo' => 'AUTH'],
            ['clave' => 'TOKEN_RESET_PASSWORD_HORAS',     'valor_int'   => 1,    'descripcion' => 'Horas de vigencia del token de recuperación de contraseña.', 'modulo' => 'AUTH'],
            ['clave' => 'SESSION_TTL_HORAS',              'valor_int'   => 24,   'descripcion' => 'Duración en horas de una sesión normal.',                    'modulo' => 'AUTH'],
            ['clave' => 'MAX_INTENTOS_LOGIN',             'valor_int'   => 5,    'descripcion' => 'Intentos fallidos antes de bloquear la cuenta.',             'modulo' => 'AUTH'],
            ['clave' => 'MAX_POSTULACIONES_ACTIVAS',      'valor_int'   => 10,   'descripcion' => 'Postulaciones simultáneas activas por voluntario.',           'modulo' => 'POSTULACIONES'],
            ['clave' => 'MAX_TAMANO_IMAGEN_MB',           'valor_int'   => 5,    'descripcion' => 'Tamaño máximo de imágenes subidas, en MB.',                  'modulo' => 'ARCHIVOS'],
            ['clave' => 'FORMATOS_IMAGEN_PERMITIDOS',     'valor_texto' => 'jpg,jpeg,png,webp', 'descripcion' => 'Formatos de imagen aceptados.', 'modulo' => 'ARCHIVOS'],
            ['clave' => 'COBERTURA_DEPARTAMENTOS',        'valor_texto' => 'Bogotá D.C.,Cundinamarca', 'descripcion' => 'Departamentos habilitados en el MVP.',  'modulo' => 'GEO'],
        ];

        foreach ($config as $row) {
            DB::table('configuracion_sistema')->insertOrIgnore(
                $row + ['fecha_actualizacion' => now()]
            );
        }

        // ── Catálogo de logros ────────────────────────────────────
        $logros = [
            ['codigo' => 'PRIMER_PASO',      'nombre' => 'Primer Paso',       'descripcion' => 'Participar en 1 convocatoria.',         'icono' => '👣', 'tipo' => 'participaciones', 'umbral' => 1,    'activo' => true],
            ['codigo' => 'COMPROMETIDO',      'nombre' => 'Comprometido',      'descripcion' => 'Participar en 5 convocatorias.',         'icono' => '🤝', 'tipo' => 'participaciones', 'umbral' => 5,    'activo' => true],
            ['codigo' => 'VOLUNTARIO_ACTIVO', 'nombre' => 'Voluntario Activo', 'descripcion' => 'Participar en 10 convocatorias.',        'icono' => '⭐', 'tipo' => 'participaciones', 'umbral' => 10,   'activo' => true],
            ['codigo' => 'IMPACTO_SOCIAL',    'nombre' => 'Impacto Social',    'descripcion' => 'Participar en 25 convocatorias.',        'icono' => '🌟', 'tipo' => 'participaciones', 'umbral' => 25,   'activo' => true],
            ['codigo' => 'LEYENDA_SOLIDARIA', 'nombre' => 'Leyenda Solidaria', 'descripcion' => 'Participar en 50 convocatorias.',        'icono' => '🏆', 'tipo' => 'participaciones', 'umbral' => 50,   'activo' => true],
            ['codigo' => 'ACUMULADOR',        'nombre' => 'Acumulador',        'descripcion' => 'Acumular 100 puntos.',                   'icono' => '💯', 'tipo' => 'puntos',          'umbral' => 100,  'activo' => true],
            ['codigo' => 'VETERANO',          'nombre' => 'Veterano',          'descripcion' => 'Acumular 500 puntos.',                   'icono' => '🎖️', 'tipo' => 'puntos',          'umbral' => 500,  'activo' => true],
            ['codigo' => 'ELITE',             'nombre' => 'Élite',             'descripcion' => 'Acumular 1000 puntos.',                  'icono' => '💎', 'tipo' => 'puntos',          'umbral' => 1000, 'activo' => true],
            ['codigo' => 'VALIENTE',          'nombre' => 'Valiente',          'descripcion' => 'Participar en 1 actividad DIFÍCIL.',     'icono' => '💪', 'tipo' => 'dificultad',      'umbral' => 1,    'activo' => true],
            ['codigo' => 'HEROE',             'nombre' => 'Héroe',             'descripcion' => 'Participar en 1 actividad MUY DIFÍCIL.', 'icono' => '🦸', 'tipo' => 'dificultad',      'umbral' => 1,    'activo' => true],
            ['codigo' => 'URGENTE_RESPONDER', 'nombre' => 'Siempre Presente',  'descripcion' => 'Participar en 3 actividades urgentes.',  'icono' => '🚨', 'tipo' => 'urgente',         'umbral' => 3,    'activo' => true],
        ];

        foreach ($logros as $logro) {
            DB::table('logros')->insertOrIgnore($logro);
        }
    }
}

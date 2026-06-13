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
    }
}

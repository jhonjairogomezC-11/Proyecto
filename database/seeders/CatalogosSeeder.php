<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CatalogosSeeder extends Seeder
{
    public function run(): void
    {
        $departamentos = [
            'Antioquia', 'Bogotá D.C.', 'Boyacá', 'Caldas',
            'Cundinamarca', 'Quindío', 'Risaralda', 'Tolima',
            'Valle del Cauca', 'Atlántico', 'Bolívar', 'Santander',
            'Nariño', 'Córdoba', 'Meta', 'Huila',
        ];

        foreach ($departamentos as $nombre) {
            DB::table('departamentos')->insertOrIgnore(['nombre' => $nombre]);
        }

        $municipiosPorDepartamento = [
            'Bogotá D.C.'   => ['Bogotá'],
            'Antioquia'     => ['Medellín', 'Bello', 'Itagüí', 'Envigado', 'Rionegro', 'Sabaneta', 'Apartadó', 'Turbo'],
            'Valle del Cauca' => ['Cali', 'Buenaventura', 'Palmira', 'Tuluá', 'Buga'],
            'Atlántico'     => ['Barranquilla', 'Soledad', 'Malambo', 'Sabanagrande'],
            'Bolívar'       => ['Cartagena', 'Magangué', 'Mompós'],
            'Santander'     => ['Bucaramanga', 'Floridablanca', 'Girón', 'Piedecuesta'],
            'Boyacá'        => ['Tunja', 'Duitama', 'Sogamoso', 'Chiquinquirá'],
            'Caldas'        => ['Manizales', 'La Dorada', 'Villamaría', 'Chinchiná'],
            'Cundinamarca'  => ['Soacha', 'Facatativá', 'Zipaquirá', 'Chía', 'Fusagasugá', 'Girardot', 'Mosquera', 'Madrid', 'Cajicá', 'Funza'],
            'Quindío'       => ['Armenia', 'Calarcá', 'Montenegro', 'La Tebaida'],
            'Risaralda'     => ['Pereira', 'Dosquebradas', 'Santa Rosa de Cabal'],
            'Tolima'        => ['Ibagué', 'Espinal', 'Melgar', 'Honda'],
            'Meta'          => ['Villavicencio', 'Acacías', 'Granada'],
            'Huila'         => ['Neiva', 'Pitalito', 'Garzón'],
            'Nariño'        => ['Pasto', 'Tumaco', 'Ipiales'],
            'Córdoba'       => ['Montería', 'Lorica', 'Cereté'],
        ];

        foreach ($municipiosPorDepartamento as $depNombre => $municipios) {
            $depId = DB::table('departamentos')->where('nombre', $depNombre)->value('id');
            if (!$depId) continue;
            foreach ($municipios as $municipio) {
                DB::table('municipios')->insertOrIgnore(['nombre' => $municipio, 'departamento_id' => $depId]);
            }
        }

        $habilidades = ['Educación', 'Tecnología', 'Salud', 'Medio Ambiente', 'Arte', 'Deportes', 'Comunicación', 'Liderazgo', 'Idiomas', 'Cocina'];
        foreach ($habilidades as $h) {
            DB::table('habilidades')->insertOrIgnore(['nombre' => $h]);
        }

        $intereses = ['Social', 'Ambiental', 'Educativo', 'Cultural', 'Comunitario', 'Salud', 'Derechos Humanos', 'Infancia'];
        foreach ($intereses as $i) {
            DB::table('intereses')->insertOrIgnore(['nombre' => $i]);
        }

        $areas = ['Educacion', 'Salud', 'Medio Ambiente', 'Derechos Humanos', 'Infancia', 'Adulto Mayor', 'Discapacidad', 'Cultura', 'Deportes', 'Tecnologia', 'Inclusion Social'];
        foreach ($areas as $a) {
            DB::table('areas_impacto')->insertOrIgnore(['nombre' => $a]);
        }

        $config = [
            ['clave' => 'TOKEN_VERIFICACION_EMAIL_HORAS', 'valor_int' => 24,  'descripcion' => 'Horas de vigencia del token de verificación de email.',      'modulo' => 'AUTH'],
            ['clave' => 'TOKEN_RESET_PASSWORD_HORAS',      'valor_int' => 1,   'descripcion' => 'Horas de vigencia del token de recuperación de contraseña.', 'modulo' => 'AUTH'],
            ['clave' => 'SESSION_TTL_HORAS',               'valor_int' => 24,  'descripcion' => 'Duración en horas de una sesión normal.',                    'modulo' => 'AUTH'],
            ['clave' => 'MAX_INTENTOS_LOGIN',              'valor_int' => 5,   'descripcion' => 'Intentos fallidos antes de bloquear.',                       'modulo' => 'AUTH'],
            ['clave' => 'MAX_POSTULACIONES_ACTIVAS',       'valor_int' => 10,  'descripcion' => 'Postulaciones simultáneas por voluntario.',                   'modulo' => 'POSTULACIONES'],
            ['clave' => 'MAX_TAMANO_IMAGEN_MB',            'valor_int' => 5,   'descripcion' => 'Tamaño máximo de imágenes en MB.',                           'modulo' => 'ARCHIVOS'],
            ['clave' => 'FORMATOS_IMAGEN_PERMITIDOS',      'valor_texto' => 'jpg,jpeg,png,webp', 'descripcion' => 'Formatos de imagen aceptados.',             'modulo' => 'ARCHIVOS'],
        ];

        foreach ($config as $row) {
            DB::table('configuracion_sistema')->insertOrIgnore($row + ['fecha_actualizacion' => now()]);
        }
    }
}

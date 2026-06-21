<?php

namespace Database\Seeders;

use App\Enums\DisponibilidadTipo;
use App\Enums\EstadoUsuario;
use App\Enums\EstadoVerificacion;
use App\Enums\GeneroTipo;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Enums\TipoDocumento;
use App\Models\AreaImpacto;
use App\Models\Fundacion;
use App\Models\Habilidad;
use App\Models\Municipio;
use App\Models\Postulacion;
use App\Models\Publicacion;
use App\Models\Usuario;
use App\Models\Voluntario;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $municipioId = Municipio::value('id');
        $habilidadIds = Habilidad::pluck('id')->toArray();
        $areaIds = AreaImpacto::pluck('id')->toArray();

        // Crear 5 voluntarios
        $voluntarios = [];
        for ($i = 1; $i <= 5; $i++) {
            $usuario = Usuario::firstOrCreate(
                [
                    'email'    => "voluntario{$i}@demo.com",
                    'provider' => ProveedorAuth::LOCAL,
                ],
                [
                    'nombre'           => "Voluntario Demo {$i}",
                    'password_hash'    => Hash::make('password'),
                    'rol'              => RolUsuario::VOLUNTARIO,
                    'estado'           => EstadoUsuario::ACTIVO,
                    'email_verificado' => true,
                ]
            );

            $voluntario = Voluntario::firstOrCreate(
                ['usuario_id' => $usuario->id],
                [
                    'tipo_documento'   => TipoDocumento::CC,
                    'numero_documento' => '100000000' . $i,
                    'fecha_nacimiento' => '1995-0' . $i . '-15',
                    'genero'           => GeneroTipo::MASCULINO,
                    'municipio_id'     => $municipioId,
                    'disponibilidad'   => DisponibilidadTipo::FLEXIBLE,
                    'foto_perfil'      => 'https://ui-avatars.com/api/?name=Voluntario+' . $i . '&background=random',
                    'esta_verificado'  => true,
                ]
            );

            $voluntario->habilidades()->sync(array_slice($habilidadIds, 0, 3));
            $voluntarios[] = $voluntario;
        }

        // Crear 3 fundaciones aprobadas
        for ($i = 1; $i <= 3; $i++) {
            $usuario = Usuario::firstOrCreate(
                [
                    'email'    => "fundacion{$i}@demo.com",
                    'provider' => ProveedorAuth::LOCAL,
                ],
                [
                    'nombre'           => "Fundacion Demo {$i}",
                    'password_hash'    => Hash::make('password'),
                    'rol'              => RolUsuario::FUNDACION,
                    'estado'           => EstadoUsuario::ACTIVO,
                    'email_verificado' => true,
                ]
            );

            $fundacion = Fundacion::firstOrCreate(
                ['usuario_id' => $usuario->id],
                [
                    'nombre'               => "Fundación Demo {$i}",
                    'nit'                  => "90000000{$i}-{$i}",
                    'representante_legal'  => "Representante {$i}",
                    'correo_institucional' => "institucional{$i}@fundacion.com",
                    'telefono'             => "60123456{$i}",
                    'direccion'            => "Calle Demo #{$i}",
                    'municipio_id'         => $municipioId,
                    'descripcion'          => "Descripción de la fundación demo {$i}",
                    'documento_legal'      => 'documentos/legal-placeholder.pdf',
                    'logo'                 => 'https://ui-avatars.com/api/?name=Fundacion+' . $i . '&background=random',
                    'estado_verificacion'  => EstadoVerificacion::APROBADA,
                ]
            );

            $fundacion->areas()->sync(array_slice($areaIds, 0, 2));

            // 2 publicaciones por fundación
            for ($j = 1; $j <= 2; $j++) {
                $titulo = "Actividad Demo {$i}-{$j}";
                $publicacion = Publicacion::firstOrCreate(
                    [
                        'fundacion_id' => $fundacion->id,
                        'titulo'       => $titulo,
                    ],
                    [
                        'descripcion'  => "Descripción de la actividad demo {$i}-{$j}",
                        'categoria_id' => $areaIds[0],
                        'modalidad'    => 'PRESENCIAL',
                        'municipio_id' => $municipioId,
                        'fecha_inicio' => now()->addDays(10)->format('Y-m-d'),
                        'fecha_fin'    => now()->addDays(20)->format('Y-m-d'),
                        'cupo_maximo'  => 20,
                        'estado'       => 'PUBLICADA',
                    ]
                );

                // Postular algunos voluntarios
                foreach (array_slice($voluntarios, 0, 3) as $voluntario) {
                    $post = Postulacion::where('publicacion_id', $publicacion->id)
                        ->where('voluntario_id', $voluntario->id)
                        ->first();
                    if (!$post) {
                        $p = new Postulacion();
                        $p->publicacion_id = $publicacion->id;
                        $p->voluntario_id  = $voluntario->id;
                        $p->estado         = 'PENDIENTE';
                        $p->save();
                    }
                }
            }
        }
    }
}

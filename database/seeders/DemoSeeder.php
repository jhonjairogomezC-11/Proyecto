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
            $usuario = new Usuario();
            $usuario->nombre           = "Voluntario Demo {$i}";
            $usuario->email            = "voluntario{$i}@demo.com";
            $usuario->password_hash    = Hash::make('password');
            $usuario->provider         = ProveedorAuth::LOCAL;
            $usuario->rol              = RolUsuario::VOLUNTARIO;
            $usuario->estado           = EstadoUsuario::ACTIVO;
            $usuario->email_verificado = true;
            $usuario->save();

            $voluntario = new Voluntario();
            $voluntario->usuario_id       = $usuario->id;
            $voluntario->tipo_documento   = TipoDocumento::CC;
            $voluntario->numero_documento = '100000000' . $i;
            $voluntario->fecha_nacimiento = '1995-0' . $i . '-15';
            $voluntario->genero           = GeneroTipo::MASCULINO;
            $voluntario->municipio_id     = $municipioId;
            $voluntario->disponibilidad   = DisponibilidadTipo::FLEXIBLE;
            $voluntario->save();

            $voluntario->habilidades()->sync(array_slice($habilidadIds, 0, 3));
            $voluntarios[] = $voluntario;
        }

        // Crear 3 fundaciones aprobadas
        for ($i = 1; $i <= 3; $i++) {
            $usuario = new Usuario();
            $usuario->nombre           = "Fundacion Demo {$i}";
            $usuario->email            = "fundacion{$i}@demo.com";
            $usuario->password_hash    = Hash::make('password');
            $usuario->provider         = ProveedorAuth::LOCAL;
            $usuario->rol              = RolUsuario::FUNDACION;
            $usuario->estado           = EstadoUsuario::ACTIVO;
            $usuario->email_verificado = true;
            $usuario->save();

            $fundacion = new Fundacion();
            $fundacion->usuario_id           = $usuario->id;
            $fundacion->nombre               = "Fundación Demo {$i}";
            $fundacion->nit                  = "90000000{$i}-{$i}";
            $fundacion->representante_legal  = "Representante {$i}";
            $fundacion->correo_institucional = "institucional{$i}@fundacion.com";
            $fundacion->telefono             = "60123456{$i}";
            $fundacion->direccion            = "Calle Demo #{$i}";
            $fundacion->municipio_id         = $municipioId;
            $fundacion->descripcion          = "Descripción de la fundación demo {$i}";
            $fundacion->documento_legal      = 'documentos/legal-placeholder.pdf';
            $fundacion->estado_verificacion  = EstadoVerificacion::APROBADA;
            $fundacion->save();

            $fundacion->areas()->sync(array_slice($areaIds, 0, 2));

            // 2 publicaciones por fundación
            for ($j = 1; $j <= 2; $j++) {
                $publicacion = new Publicacion();
                $publicacion->fundacion_id = $fundacion->id;
                $publicacion->titulo       = "Actividad Demo {$i}-{$j}";
                $publicacion->descripcion  = "Descripción de la actividad demo {$i}-{$j}";
                $publicacion->categoria_id = $areaIds[0];
                $publicacion->modalidad    = 'PRESENCIAL';
                $publicacion->municipio_id = $municipioId;
                $publicacion->fecha_inicio = now()->addDays(10)->format('Y-m-d');
                $publicacion->fecha_fin    = now()->addDays(20)->format('Y-m-d');
                $publicacion->cupo_maximo  = 20;
                $publicacion->estado       = 'PUBLICADA';
                $publicacion->save();

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

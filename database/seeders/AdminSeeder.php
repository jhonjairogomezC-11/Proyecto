<?php

namespace Database\Seeders;

use App\Enums\EstadoUsuario;
use App\Enums\NivelAdmin;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Models\AdminPerfil;
use App\Models\Usuario;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        // Administradores con diferentes niveles y perfiles realistas
        $administradores = [
            [
                'nombre' => 'María Elena Rodríguez',
                'email' => 'maria.rodriguez@voluntapp.co', 
                'cargo' => 'Directora General',
                'nivel' => NivelAdmin::SUPER,
                'password' => 'Admin1234!',
                'activo' => true
            ],
            [
                'nombre' => 'Carlos Andrés Martínez',
                'email' => 'carlos.martinez@voluntapp.co',
                'cargo' => 'Coordinador de Operaciones', 
                'nivel' => NivelAdmin::OPERATIVO,
                'password' => 'Coord2024!',
                'activo' => true
            ],
            [
                'nombre' => 'Ana Sofía Hernández',
                'email' => 'ana.hernandez@voluntapp.co',
                'cargo' => 'Especialista en Contenidos',
                'nivel' => NivelAdmin::OPERATIVO, // Cambiado a OPERATIVO
                'password' => 'Mod2024!',
                'activo' => true
            ],
            [
                'nombre' => 'Luis Fernando García',
                'email' => 'luis.garcia@voluntapp.co', 
                'cargo' => 'Supervisor de Calidad',
                'nivel' => NivelAdmin::OPERATIVO,
                'password' => 'Super2024!',
                'activo' => true
            ],
            [
                'nombre' => 'Patricia Morales Silva',
                'email' => 'patricia.morales@voluntapp.co',
                'cargo' => 'Coordinadora Regional',
                'nivel' => NivelAdmin::OPERATIVO, // Cambiado a OPERATIVO
                'password' => 'Region2024!',
                'activo' => true
            ],
            // Admin de pruebas (para mantener compatibilidad)
            [
                'nombre' => 'Administrador del Sistema',
                'email' => 'admin@voluntapp.co',
                'cargo' => 'Super Administrador',
                'nivel' => NivelAdmin::SUPER,
                'password' => 'Admin1234!',
                'activo' => true
            ]
        ];

        foreach ($administradores as $adminData) {
            $admin = Usuario::where('email', $adminData['email'])
                ->where('provider', ProveedorAuth::LOCAL->value)
                ->first();

            if (!$admin) {
                $admin = new Usuario();
                $admin->nombre           = $adminData['nombre'];
                $admin->email            = $adminData['email'];
                $admin->password_hash    = Hash::make($adminData['password']);
                $admin->provider         = ProveedorAuth::LOCAL;
                $admin->rol              = RolUsuario::ADMIN;
                $admin->estado           = EstadoUsuario::ACTIVO;
                $admin->email_verificado = true;
                $admin->save();
            }

            $perfil = AdminPerfil::where('usuario_id', $admin->id)->first();

            if (!$perfil) {
                $perfil = new AdminPerfil();
                $perfil->usuario_id = $admin->id;
                $perfil->nivel      = $adminData['nivel'];
                $perfil->activo     = $adminData['activo'];
                $perfil->cargo      = $adminData['cargo'];
                $perfil->save();
            }
        }
    }
}

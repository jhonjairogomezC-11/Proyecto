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
        $admin = Usuario::where('email', 'admin@voluntapp.co')
            ->where('provider', ProveedorAuth::LOCAL->value)
            ->first();

        if (!$admin) {
            $admin = new Usuario();
            $admin->nombre           = 'Administrador del Sistema';
            $admin->email            = 'admin@voluntapp.co';
            $admin->password_hash    = Hash::make('Admin1234!');
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
            $perfil->nivel      = NivelAdmin::SUPER;
            $perfil->activo     = true;
            $perfil->cargo      = 'Super Administrador';
            $perfil->save();
        }
    }
}

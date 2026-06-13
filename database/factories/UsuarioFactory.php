<?php

namespace Database\Factories;

use App\Enums\EstadoUsuario;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Models\Usuario;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

class UsuarioFactory extends Factory
{
    protected $model = Usuario::class;

    public function definition(): array
    {
        return [
            'nombre'           => fake()->name(),
            'email'            => fake()->unique()->safeEmail(),
            'password_hash'    => Hash::make('password'),
            'provider'         => ProveedorAuth::LOCAL,
            'telefono'         => fake()->numerify('3##-###-####'),
            'rol'              => RolUsuario::VOLUNTARIO,
            'estado'           => EstadoUsuario::ACTIVO,
            'email_verificado' => true,
        ];
    }

    public function fundacion(): static
    {
        return $this->state(['rol' => RolUsuario::FUNDACION]);
    }

    public function admin(): static
    {
        return $this->state(['rol' => RolUsuario::ADMIN]);
    }
}

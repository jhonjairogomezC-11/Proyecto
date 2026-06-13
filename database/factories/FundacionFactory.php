<?php

namespace Database\Factories;

use App\Enums\EstadoVerificacion;
use App\Enums\RolUsuario;
use App\Models\Fundacion;
use App\Models\Municipio;
use App\Models\Usuario;
use Illuminate\Database\Eloquent\Factories\Factory;

class FundacionFactory extends Factory
{
    protected $model = Fundacion::class;

    public function definition(): array
    {
        $nit     = fake()->numerify('#########') . '-' . fake()->numerify('#');
        $usuario = Usuario::factory()->create(['rol' => RolUsuario::FUNDACION]);

        return [
            'usuario_id'           => $usuario->id,
            'nombre'               => fake()->company(),
            'nit'                  => $nit,
            'representante_legal'  => fake()->name(),
            'correo_institucional' => fake()->unique()->companyEmail(),
            'telefono'             => fake()->numerify('60#-###-####'),
            'direccion'            => fake()->streetAddress(),
            'municipio_id'         => Municipio::inRandomOrder()->value('id') ?? 1,
            'descripcion'          => fake()->paragraphs(2, true),
            'documento_legal'      => 'documentos/legal-placeholder.pdf',
            'estado_verificacion'  => EstadoVerificacion::APROBADA,
        ];
    }

    public function pendiente(): static
    {
        return $this->state(['estado_verificacion' => EstadoVerificacion::PENDIENTE]);
    }
}

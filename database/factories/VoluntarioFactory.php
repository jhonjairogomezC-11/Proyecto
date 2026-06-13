<?php

namespace Database\Factories;

use App\Enums\DisponibilidadTipo;
use App\Enums\GeneroTipo;
use App\Enums\RolUsuario;
use App\Enums\TipoDocumento;
use App\Models\Municipio;
use App\Models\Usuario;
use App\Models\Voluntario;
use Illuminate\Database\Eloquent\Factories\Factory;

class VoluntarioFactory extends Factory
{
    protected $model = Voluntario::class;

    public function definition(): array
    {
        $usuario = Usuario::factory()->create();

        return [
            'usuario_id'       => $usuario->id,
            'tipo_documento'   => fake()->randomElement(TipoDocumento::cases())->value,
            'numero_documento' => fake()->unique()->numerify('##########'),
            'fecha_nacimiento' => fake()->dateTimeBetween('-50 years', '-16 years')->format('Y-m-d'),
            'genero'           => fake()->randomElement(GeneroTipo::cases())->value,
            'municipio_id'     => Municipio::inRandomOrder()->value('id') ?? 1,
            'disponibilidad'   => fake()->randomElement(DisponibilidadTipo::cases())->value,
            'experiencia'      => fake()->optional()->paragraph(),
        ];
    }
}

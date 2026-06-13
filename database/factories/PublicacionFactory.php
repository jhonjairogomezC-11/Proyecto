<?php

namespace Database\Factories;

use App\Enums\EstadoPublicacion;
use App\Enums\ModalidadTipo;
use App\Models\AreaImpacto;
use App\Models\Fundacion;
use App\Models\Municipio;
use App\Models\Publicacion;
use Illuminate\Database\Eloquent\Factories\Factory;

class PublicacionFactory extends Factory
{
    protected $model = Publicacion::class;

    public function definition(): array
    {
        $fundacion = Fundacion::inRandomOrder()->first() ?? Fundacion::factory()->create();
        $inicio    = fake()->dateTimeBetween('now', '+2 months');
        $fin       = fake()->dateTimeBetween($inicio, '+3 months');

        return [
            'fundacion_id' => $fundacion->id,
            'titulo'       => fake()->sentence(6),
            'descripcion'  => fake()->paragraphs(3, true),
            'categoria_id' => AreaImpacto::inRandomOrder()->value('id') ?? 1,
            'modalidad'    => fake()->randomElement(ModalidadTipo::cases())->value,
            'municipio_id' => Municipio::inRandomOrder()->value('id') ?? 1,
            'fecha_inicio' => $inicio->format('Y-m-d'),
            'fecha_fin'    => $fin->format('Y-m-d'),
            'cupo_maximo'  => fake()->numberBetween(5, 50),
            'estado'       => EstadoPublicacion::PUBLICADA,
        ];
    }
}

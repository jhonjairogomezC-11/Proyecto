<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MunicipioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'           => $this->id,
            'nombre'       => $this->nombre,
            'departamento' => $this->whenLoaded('departamento', fn() => [
                'id'     => $this->departamento->id,
                'nombre' => $this->departamento->nombre,
            ]),
        ];
    }
}

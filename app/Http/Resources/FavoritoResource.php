<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FavoritoResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'tipo'           => $this->tipo,
            'fecha_creacion' => $this->fecha_creacion,
            'publicacion'    => new PublicacionResource($this->whenLoaded('publicacion')),
            'fundacion'      => new FundacionResource($this->whenLoaded('fundacion')),
        ];
    }
}

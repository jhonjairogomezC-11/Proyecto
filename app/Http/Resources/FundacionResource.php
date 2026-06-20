<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FundacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'nombre'               => $this->nombre,
            'nit'                  => $this->nit,
            'representante_legal'  => $this->representante_legal,
            'correo_institucional' => $this->correo_institucional,
            'telefono'             => $this->telefono,
            'direccion'            => $this->direccion,
            'pagina_web'           => $this->pagina_web,
            'descripcion'          => $this->descripcion,
            'logo'                 => $this->logo,
            'estado_verificacion'  => $this->estado_verificacion instanceof \BackedEnum
                ? $this->estado_verificacion->value
                : $this->estado_verificacion,
            'municipio'            => new MunicipioResource($this->whenLoaded('municipio')),
            'areas'                => AreaImpactoResource::collection($this->whenLoaded('areas')),
            'fecha_creacion'       => $this->fecha_creacion,
        ];
    }
}

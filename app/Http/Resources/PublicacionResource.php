<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PublicacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                     => $this->id,
            'titulo'                 => $this->titulo,
            'descripcion'            => $this->descripcion,
            'modalidad'              => $this->modalidad instanceof \BackedEnum ? $this->modalidad->value : $this->modalidad,
            'dificultad'             => $this->dificultad instanceof \BackedEnum ? $this->dificultad->value : $this->dificultad,
            'urgente'                => $this->urgente,
            'estado'                 => $this->estado instanceof \BackedEnum ? $this->estado->value : $this->estado,
            'fecha_inicio'           => $this->fecha_inicio,
            'fecha_fin'              => $this->fecha_fin,
            'hora_inicio'            => $this->hora_inicio,
            'hora_fin'               => $this->hora_fin,
            'cupo_maximo'            => $this->cupo_maximo,
            'edad_minima'            => $this->edad_minima,
            'edad_maxima'            => $this->edad_maxima,
            'requisitos_adicionales' => $this->requisitos_adicionales,
            'direccion_exacta'       => $this->direccion_exacta,
            'enlace_virtual'         => $this->enlace_virtual,
        'imagen'                 => $this->resolveImagenPrincipal(),
        'imagenes'               => $this->relationLoaded('imagenes')
            ? PublicacionImagenResource::collection($this->imagenes)
            : ($this->imagen ? [['id' => null, 'url' => $this->imagen, 'orden' => 0]] : []),
            'contacto_nombre'        => $this->contacto_nombre,
            'contacto_email'         => $this->contacto_email,
            'contacto_telefono'      => $this->contacto_telefono,
            'fecha_publicacion'      => $this->fecha_publicacion,
            'fundacion'              => new FundacionResource($this->whenLoaded('fundacion')),
            'categoria'              => new AreaImpactoResource($this->whenLoaded('categoria')),
            'municipio'              => new MunicipioResource($this->whenLoaded('municipio')),
            'habilidades'            => HabilidadResource::collection($this->whenLoaded('habilidades')),
        ];
    }

    private function resolveImagenPrincipal(): ?string
    {
        if ($this->relationLoaded('imagenes') && $this->imagenes->isNotEmpty()) {
            return $this->imagenes->first()->url;
        }
        return $this->imagen;
    }
}

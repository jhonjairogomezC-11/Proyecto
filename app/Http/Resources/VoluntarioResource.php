<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VoluntarioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'               => $this->id,
            'usuario'          => new UsuarioResource($this->whenLoaded('usuario')),
            'tipo_documento'   => $this->tipo_documento instanceof \BackedEnum ? $this->tipo_documento->value : $this->tipo_documento,
            'numero_documento' => $this->numero_documento,
            'fecha_nacimiento' => $this->fecha_nacimiento,
            'genero'           => $this->genero instanceof \BackedEnum ? $this->genero->value : $this->genero,
            'disponibilidad'   => $this->disponibilidad instanceof \BackedEnum ? $this->disponibilidad->value : $this->disponibilidad,
            'experiencia'         => $this->experiencia,
            'foto_perfil'         => $this->foto_perfil ? (str_starts_with($this->foto_perfil, 'http') ? $this->foto_perfil : url('storage/' . $this->foto_perfil)) : null,
            'documento_identidad' => $this->documento_identidad ? (str_starts_with($this->documento_identidad, 'http') ? $this->documento_identidad : url('storage/' . $this->documento_identidad)) : null,
            'esta_verificado'     => (bool) $this->esta_verificado,
            'municipio'        => new MunicipioResource($this->whenLoaded('municipio')),
            'habilidades'      => HabilidadResource::collection($this->whenLoaded('habilidades')),
            'intereses'        => InteresResource::collection($this->whenLoaded('intereses')),
        ];
    }
}

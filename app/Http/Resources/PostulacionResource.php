<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostulacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'estado'               => $this->estado instanceof \BackedEnum ? $this->estado->value : $this->estado,
            'mensaje_voluntario'   => $this->mensaje_voluntario,
            'motivo_rechazo'       => $this->motivo_rechazo,
            'calificacion'         => $this->calificacion,
            'comentario_fundacion' => $this->comentario_fundacion,
            'fecha_postulacion'    => $this->fecha_postulacion,
            'fecha_respuesta'      => $this->fecha_respuesta,
            'fecha_confirmacion'   => $this->fecha_confirmacion,
            'publicacion'          => new PublicacionResource($this->whenLoaded('publicacion')),
            'voluntario'           => new VoluntarioResource($this->whenLoaded('voluntario')),
        ];
    }
}

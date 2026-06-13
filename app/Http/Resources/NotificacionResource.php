<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificacionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'tipo'           => $this->tipo,
            'mensaje'        => $this->mensaje,
            'objeto_tipo'    => $this->objeto_tipo,
            'objeto_id'      => $this->objeto_id,
            'leida'          => $this->leida,
            'fecha_lectura'  => $this->fecha_lectura,
            'fecha_creacion' => $this->fecha_creacion,
        ];
    }
}

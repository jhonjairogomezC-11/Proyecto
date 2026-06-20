<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UsuarioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'               => $this->id,
            'nombre'           => $this->nombre,
            'email'            => $this->email,
            // Forzar string para que el frontend no reciba {value: "ROL"} sino "ROL"
            'rol'              => $this->rol instanceof \BackedEnum ? $this->rol->value : $this->rol,
            'estado'           => $this->estado instanceof \BackedEnum ? $this->estado->value : $this->estado,
            'telefono'         => $this->telefono,
            'email_verificado' => $this->email_verificado,
            'fecha_registro'   => $this->fecha_registro,
        ];
    }
}

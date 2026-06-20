<?php

namespace App\Events;

use App\Models\Publicacion;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NuevaPublicacion implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Publicacion $publicacion)
    {
        $this->publicacion->load(['fundacion', 'categoria', 'municipio.departamento']);
    }

    public function broadcastOn(): array
    {
        // Canal público — todos los voluntarios pueden escuchar nuevas convocatorias
        return [new Channel('convocatorias')];
    }

    public function broadcastAs(): string
    {
        return 'NuevaPublicacion';
    }

    public function broadcastWith(): array
    {
        return [
            'publicacion_id' => $this->publicacion->id,
            'titulo'         => $this->publicacion->titulo,
            'fundacion'      => $this->publicacion->fundacion?->nombre,
            'categoria'      => $this->publicacion->categoria?->nombre,
            'municipio'      => $this->publicacion->municipio?->nombre,
            'modalidad'      => $this->publicacion->modalidad instanceof \BackedEnum
                ? $this->publicacion->modalidad->value
                : $this->publicacion->modalidad,
            'dificultad'     => $this->publicacion->dificultad instanceof \BackedEnum
                ? $this->publicacion->dificultad->value
                : $this->publicacion->dificultad,
            'cupo_maximo'    => $this->publicacion->cupo_maximo,
            'fecha_inicio'   => $this->publicacion->fecha_inicio?->toDateString(),
            'urgente'        => $this->publicacion->urgente,
            'fecha'          => now()->toISOString(),
        ];
    }
}

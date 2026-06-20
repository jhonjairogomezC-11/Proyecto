<?php

namespace App\Events;

use App\Models\Postulacion;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PostulacionCreada implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Postulacion $postulacion)
    {
        $this->postulacion->load(['voluntario.usuario', 'publicacion']);
    }

    public function broadcastOn(): array
    {
        $fundacionId = $this->postulacion->publicacion?->fundacion_id;
        return [
            new PrivateChannel("fundacion.{$fundacionId}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'PostulacionCreada';
    }

    public function broadcastWith(): array
    {
        return [
            'postulacion_id'  => $this->postulacion->id,
            'publicacion_id'  => $this->postulacion->publicacion_id,
            'publicacion'     => $this->postulacion->publicacion?->titulo,
            'voluntario'      => $this->postulacion->voluntario?->usuario?->nombre,
            'estado'          => $this->postulacion->estado instanceof \BackedEnum
                ? $this->postulacion->estado->value
                : $this->postulacion->estado,
            'fecha'           => now()->toISOString(),
        ];
    }
}

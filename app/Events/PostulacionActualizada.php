<?php

namespace App\Events;

use App\Models\Postulacion;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class PostulacionActualizada implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Postulacion $postulacion,
        public string $evento  // 'cancelada' | 'respondida' | 'asistencia'
    ) {
        $this->postulacion->load(['voluntario.usuario', 'publicacion.fundacion']);
    }

    public function broadcastOn(): array
    {
        $voluntarioUserId = $this->postulacion->voluntario?->usuario_id;
        $fundacionId      = $this->postulacion->publicacion?->fundacion_id;

        $canales = [];

        // Notificar al voluntario cuando la fundación responde
        if (in_array($this->evento, ['respondida', 'asistencia']) && $voluntarioUserId) {
            $canales[] = new PrivateChannel("usuario.{$voluntarioUserId}");
        }

        // Notificar a la fundación cuando el voluntario cancela
        if ($this->evento === 'cancelada' && $fundacionId) {
            $canales[] = new PrivateChannel("fundacion.{$fundacionId}");
        }

        return $canales ?: [new PrivateChannel("sistema")];
    }

    public function broadcastAs(): string
    {
        return 'PostulacionActualizada';
    }

    public function broadcastWith(): array
    {
        return [
            'postulacion_id' => $this->postulacion->id,
            'publicacion_id' => $this->postulacion->publicacion_id,
            'publicacion'    => $this->postulacion->publicacion?->titulo,
            'evento'         => $this->evento,
            'estado'         => $this->postulacion->estado instanceof \BackedEnum
                ? $this->postulacion->estado->value
                : $this->postulacion->estado,
            'voluntario'     => $this->postulacion->voluntario?->usuario?->nombre,
            'cupos_restantes'=> $this->calcularCuposRestantes(),
            'fecha'          => now()->toISOString(),
        ];
    }

    private function calcularCuposRestantes(): int
    {
        $pub = $this->postulacion->publicacion;
        if (!$pub) return 0;
        $aceptadas = \App\Models\Postulacion::where('publicacion_id', $pub->id)
            ->where('estado', 'ACEPTADO')->count();
        return max(0, $pub->cupo_maximo - $aceptadas);
    }
}

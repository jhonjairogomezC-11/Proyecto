<?php

namespace App\Services;

use App\Enums\EstadoPostulacion;
use App\Enums\EstadoPublicacion;
use App\Models\Notificacion;
use App\Models\Postulacion;
use App\Models\Publicacion;
use App\Models\Voluntario;
use Illuminate\Validation\ValidationException;

class PostulacionService
{
    public function postular(Voluntario $voluntario, string $publicacionId, ?string $mensaje): Postulacion
    {
        $publicacion = Publicacion::findOrFail($publicacionId);

        if (!in_array($publicacion->estado, [EstadoPublicacion::PUBLICADA, EstadoPublicacion::CERRADA])) {
            throw ValidationException::withMessages(['publicacion_id' => 'La publicación no está disponible.']);
        }

        $existente = Postulacion::where('publicacion_id', $publicacionId)
            ->where('voluntario_id', $voluntario->id)
            ->first();

        if ($existente) {
            throw ValidationException::withMessages(['publicacion_id' => 'Ya estás postulado a esta actividad.']);
        }

        return Postulacion::create([
            'publicacion_id'     => $publicacionId,
            'voluntario_id'      => $voluntario->id,
            'mensaje_voluntario' => $mensaje,
            'estado'             => EstadoPostulacion::PENDIENTE,
        ]);
    }

    public function responder(Postulacion $postulacion, string $estado, ?string $motivo): Postulacion
    {
        if ($postulacion->estado !== EstadoPostulacion::PENDIENTE) {
            throw ValidationException::withMessages(['estado' => 'Solo se pueden responder postulaciones PENDIENTES.']);
        }

        if ($estado === EstadoPostulacion::RECHAZADO->value && !$motivo) {
            throw ValidationException::withMessages(['motivo_rechazo' => 'El motivo es obligatorio al rechazar.']);
        }

        $postulacion->update([
            'estado'          => EstadoPostulacion::from($estado),
            'motivo_rechazo'  => $motivo,
            'fecha_respuesta' => now(),
        ]);

        if ($postulacion->estado === EstadoPostulacion::ACEPTADO) {
            $this->verificarYCerrarCupo($postulacion->publicacion_id);
        }

        $this->notificarCambioEstado($postulacion->fresh(['publicacion.fundacion.usuario', 'voluntario.usuario']));

        return $postulacion->fresh();
    }

    public function retirar(Postulacion $postulacion): Postulacion
    {
        if (in_array($postulacion->estado, [EstadoPostulacion::ASISTIO, EstadoPostulacion::NO_ASISTIO])) {
            throw ValidationException::withMessages(['estado' => 'No puedes retirar una postulación ya confirmada.']);
        }

        $postulacion->update(['estado' => EstadoPostulacion::RETIRADO]);

        $this->notificarCambioEstado($postulacion->fresh(['publicacion.fundacion.usuario', 'voluntario.usuario']));

        return $postulacion->fresh();
    }

    public function confirmarAsistencia(Postulacion $postulacion, bool $asistio, ?int $calificacion, ?string $comentario): Postulacion
    {
        if ($postulacion->estado !== EstadoPostulacion::ACEPTADO) {
            throw ValidationException::withMessages(['estado' => 'Solo se puede confirmar asistencia de postulaciones ACEPTADAS.']);
        }

        $postulacion->update([
            'estado'               => $asistio ? EstadoPostulacion::ASISTIO : EstadoPostulacion::NO_ASISTIO,
            'calificacion'         => $asistio ? $calificacion : null,
            'comentario_fundacion' => $comentario,
            'fecha_confirmacion'   => now(),
        ]);

        return $postulacion->fresh();
    }

    private function verificarYCerrarCupo(string $publicacionId): void
    {
        $publicacion  = Publicacion::find($publicacionId);
        $cuposTomados = Postulacion::where('publicacion_id', $publicacionId)
            ->where('estado', EstadoPostulacion::ACEPTADO)
            ->count();

        if ($cuposTomados >= $publicacion->cupo_maximo) {
            $publicacion->update(['estado' => EstadoPublicacion::CERRADA]);
        }
    }

    private function notificarCambioEstado(Postulacion $postulacion): void
    {
        $usuarioVoluntario = $postulacion->voluntario->usuario;
        $usuarioFundacion  = $postulacion->publicacion->fundacion->usuario;
        $titulo            = $postulacion->publicacion->titulo;

        $datos = match ($postulacion->estado) {
            EstadoPostulacion::ACEPTADO  => [
                'usuario_id' => $usuarioVoluntario->id,
                'tipo'       => 'POSTULACION_ACEPTADA',
                'mensaje'    => "{$usuarioFundacion->nombre} aceptó tu postulación para \"{$titulo}\".",
            ],
            EstadoPostulacion::RECHAZADO => [
                'usuario_id' => $usuarioVoluntario->id,
                'tipo'       => 'POSTULACION_RECHAZADA',
                'mensaje'    => "{$usuarioFundacion->nombre} rechazó tu postulación para \"{$titulo}\".",
            ],
            EstadoPostulacion::RETIRADO  => [
                'usuario_id' => $usuarioFundacion->id,
                'tipo'       => 'POSTULACION_RETIRADA',
                'mensaje'    => "{$usuarioVoluntario->nombre} retiró su postulación de \"{$titulo}\".",
            ],
            default => null,
        };

        if ($datos) {
            Notificacion::create($datos + ['objeto_tipo' => 'POSTULACION', 'objeto_id' => $postulacion->id]);
        }
    }
}

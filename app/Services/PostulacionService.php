<?php

namespace App\Services;

use App\Enums\EstadoPostulacion;
use App\Enums\EstadoPublicacion;
use App\Models\Notificacion;
use App\Models\Postulacion;
use App\Models\Publicacion;
use App\Models\Voluntario;
use Illuminate\Support\Facades\App;
use Illuminate\Validation\ValidationException;

class PostulacionService
{
    public function postular(Voluntario $voluntario, string $publicacionId, ?string $mensaje): Postulacion
    {
        $publicacion = Publicacion::findOrFail($publicacionId);

        // Solo se puede postular a publicaciones activas (no CERRADA, CANCELADA, etc.)
        if ($publicacion->estado !== EstadoPublicacion::PUBLICADA) {
            throw ValidationException::withMessages([
                'publicacion_id' => 'Esta convocatoria no está disponible para postulaciones.',
            ]);
        }

        // Verificar si existe una postulación activa (no retirada ni rechazada)
        $existenteActiva = Postulacion::where('publicacion_id', $publicacionId)
            ->where('voluntario_id', $voluntario->id)
            ->whereNotIn('estado', [
                EstadoPostulacion::RETIRADO->value,
                EstadoPostulacion::RECHAZADO->value,
            ])
            ->first();

        if ($existenteActiva) {
            throw ValidationException::withMessages([
                'publicacion_id' => 'Ya tienes una postulación activa para esta convocatoria.',
            ]);
        }

        // Eliminar postulaciones anteriores RETIRADAS o RECHAZADAS para permitir nueva postulación limpia
        Postulacion::where('publicacion_id', $publicacionId)
            ->where('voluntario_id', $voluntario->id)
            ->whereIn('estado', [
                EstadoPostulacion::RETIRADO->value,
                EstadoPostulacion::RECHAZADO->value,
            ])
            ->delete();

        return Postulacion::create([
            'publicacion_id'      => $publicacionId,
            'voluntario_id'       => $voluntario->id,
            'mensaje_voluntario'  => $mensaje,
            'estado'              => EstadoPostulacion::PENDIENTE,
            'fecha_actualizacion' => now(),
        ]);
    }

    public function responder(Postulacion $postulacion, string $estado, ?string $motivo): Postulacion
    {
        if ($postulacion->estado !== EstadoPostulacion::PENDIENTE) {
            throw ValidationException::withMessages([
                'estado' => 'Solo se pueden responder postulaciones PENDIENTES.',
            ]);
        }

        $nuevoEstado = EstadoPostulacion::from($estado);

        if ($nuevoEstado === EstadoPostulacion::RECHAZADO && !$motivo) {
            throw ValidationException::withMessages([
                'motivo_rechazo' => 'El motivo es obligatorio al rechazar una postulación.',
            ]);
        }

        $postulacion->update([
            'estado'              => $nuevoEstado,
            'motivo_rechazo'      => $motivo,
            'fecha_respuesta'     => now(),
            'fecha_actualizacion' => now(),
        ]);

        if ($nuevoEstado === EstadoPostulacion::ACEPTADO) {
            $this->verificarYCerrarCupo($postulacion->publicacion_id);
        }

        $this->notificarCambioEstado(
            $postulacion->fresh(['publicacion.fundacion.usuario', 'voluntario.usuario'])
        );

        return $postulacion->fresh();
    }

    public function retirar(Postulacion $postulacion): Postulacion
    {
        if (in_array($postulacion->estado, [
            EstadoPostulacion::ASISTIO,
            EstadoPostulacion::NO_ASISTIO,
        ])) {
            throw ValidationException::withMessages([
                'estado' => 'No puedes retirar una postulación cuya asistencia ya fue confirmada.',
            ]);
        }

        $eraAceptado = $postulacion->estado === EstadoPostulacion::ACEPTADO;

        $postulacion->update([
            'estado'              => EstadoPostulacion::RETIRADO,
            'fecha_actualizacion' => now(),
        ]);

        // Si el voluntario tenía cupo reservado y la publicación quedó CERRADA → reabrirla
        if ($eraAceptado) {
            $publicacion = $postulacion->publicacion;
            if ($publicacion && $publicacion->estado === EstadoPublicacion::CERRADA) {
                $publicacion->update([
                    'estado'              => EstadoPublicacion::PUBLICADA,
                    'fecha_actualizacion' => now(),
                ]);
            }
        }

        $this->notificarCambioEstado(
            $postulacion->fresh(['publicacion.fundacion.usuario', 'voluntario.usuario'])
        );

        return $postulacion->fresh();
    }

    public function confirmarAsistencia(
        Postulacion $postulacion,
        bool $asistio,
        ?int $calificacion,
        ?string $comentario
    ): Postulacion {
        if ($postulacion->estado !== EstadoPostulacion::ACEPTADO) {
            throw ValidationException::withMessages([
                'estado' => 'Solo se puede confirmar asistencia de postulaciones ACEPTADAS.',
            ]);
        }

        $postulacion->update([
            'estado'               => $asistio ? EstadoPostulacion::ASISTIO : EstadoPostulacion::NO_ASISTIO,
            'calificacion'         => $asistio ? $calificacion : null,
            'comentario_fundacion' => $comentario,
            'fecha_confirmacion'   => now(),
            'fecha_actualizacion'  => now(),
        ]);

        // Acreditar puntos y evaluar logros cuando el voluntario asistió
        if ($asistio) {
            try {
                $postulacionFresh = $postulacion->fresh();
                $postulacionFresh->load(['publicacion', 'voluntario']);
                App::make(PuntoService::class)->acreditar($postulacionFresh);
            } catch (\Throwable) {
                // No bloquear la confirmación si falla la gamificación
            }
        }

        return $postulacion->fresh();
    }

    // ── Privados ──────────────────────────────────────────────

    private function verificarYCerrarCupo(string $publicacionId): void
    {
        $publicacion  = Publicacion::lockForUpdate()->find($publicacionId);
        $cuposTomados = Postulacion::where('publicacion_id', $publicacionId)
            ->where('estado', EstadoPostulacion::ACEPTADO->value)
            ->count();

        if ($publicacion && $cuposTomados >= $publicacion->cupo_maximo) {
            $publicacion->update([
                'estado'              => EstadoPublicacion::CERRADA,
                'fecha_actualizacion' => now(),
            ]);
        }
    }

    private function notificarCambioEstado(Postulacion $postulacion): void
    {
        $usuarioVoluntario = $postulacion->voluntario?->usuario;
        $usuarioFundacion  = $postulacion->publicacion?->fundacion?->usuario;
        $titulo            = $postulacion->publicacion?->titulo ?? 'la actividad';

        if (!$usuarioVoluntario || !$usuarioFundacion) return;

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
            Notificacion::create(array_merge($datos, [
                'objeto_tipo' => 'POSTULACION',
                'objeto_id'   => $postulacion->id,
            ]));
        }
    }
}

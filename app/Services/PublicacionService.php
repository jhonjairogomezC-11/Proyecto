<?php

namespace App\Services;

use App\Enums\EstadoPublicacion;
use App\Enums\EstadoVerificacion;
use App\Models\Fundacion;
use App\Models\Publicacion;
use Illuminate\Validation\ValidationException;

class PublicacionService
{
    public function crear(Fundacion $fundacion, array $data): Publicacion
    {
        if ($fundacion->estado_verificacion !== EstadoVerificacion::APROBADA) {
            throw ValidationException::withMessages(['fundacion' => 'Solo fundaciones APROBADAS pueden crear publicaciones.']);
        }

        $publicacion = Publicacion::create(array_merge($data, [
            'fundacion_id' => $fundacion->id,
            'estado'       => EstadoPublicacion::BORRADOR,
        ]));

        if (!empty($data['habilidades'])) {
            $publicacion->habilidades()->sync($data['habilidades']);
        }

        return $publicacion->load(['categoria', 'municipio.departamento', 'habilidades']);
    }

    public function actualizar(Publicacion $publicacion, array $data): Publicacion
    {
        $publicacion->update($data);

        if (array_key_exists('habilidades', $data)) {
            $publicacion->habilidades()->sync($data['habilidades'] ?? []);
        }

        return $publicacion->fresh(['categoria', 'municipio.departamento', 'habilidades']);
    }

    public function publicar(Publicacion $publicacion): Publicacion
    {
        if ($publicacion->estado !== EstadoPublicacion::BORRADOR) {
            throw ValidationException::withMessages(['estado' => 'Solo se pueden enviar a revisión convocatorias en estado BORRADOR.']);
        }

        // Pasa a PENDIENTE_APROBACION — el admin debe aprobarla para que sea visible
        $publicacion->update([
            'estado'            => EstadoPublicacion::PENDIENTE_APROBACION,
            'fecha_actualizacion' => now(),
        ]);

        return $publicacion->fresh();
    }

    public function cancelar(Publicacion $publicacion): Publicacion
    {
        if (in_array($publicacion->estado, [EstadoPublicacion::CANCELADA, EstadoPublicacion::FINALIZADA])) {
            throw ValidationException::withMessages(['estado' => 'La publicación ya está cancelada o finalizada.']);
        }

        $publicacion->update(['estado' => EstadoPublicacion::CANCELADA]);

        return $publicacion->fresh();
    }

    /** Admin aprueba una publicación pendiente → queda PUBLICADA y visible */
    public function aprobar(Publicacion $publicacion): Publicacion
    {
        if ($publicacion->estado !== EstadoPublicacion::PENDIENTE_APROBACION) {
            throw ValidationException::withMessages(['estado' => 'Solo se pueden aprobar publicaciones PENDIENTES DE APROBACIÓN.']);
        }

        $publicacion->update([
            'estado'            => EstadoPublicacion::PUBLICADA,
            'fecha_publicacion' => now(),
            'fecha_actualizacion' => now(),
        ]);

        // Notificar a la fundación
        $fundacion = $publicacion->fundacion;
        if ($fundacion) {
            \App\Models\Notificacion::create([
                'usuario_id'  => $fundacion->usuario_id,
                'tipo'        => 'ACTIVIDAD_MODIFICADA',
                'mensaje'     => "Tu convocatoria \"{$publicacion->titulo}\" fue aprobada y ya es visible para los voluntarios.",
                'objeto_tipo' => 'PUBLICACION',
                'objeto_id'   => $publicacion->id,
            ]);
        }

        // WebSocket: broadcast a todos los voluntarios
        try {
            event(new \App\Events\NuevaPublicacion($publicacion->fresh(['fundacion', 'categoria', 'municipio.departamento'])));
        } catch (\Throwable) {}

        return $publicacion->fresh();
    }

    /** Admin rechaza una publicación pendiente → vuelve a BORRADOR con motivo */
    public function rechazarPublicacion(Publicacion $publicacion, string $motivo): Publicacion
    {
        if ($publicacion->estado !== EstadoPublicacion::PENDIENTE_APROBACION) {
            throw ValidationException::withMessages(['estado' => 'Solo se pueden rechazar publicaciones PENDIENTES DE APROBACIÓN.']);
        }

        $publicacion->update([
            'estado'              => EstadoPublicacion::BORRADOR,
            'motivo_ocultamiento' => $motivo,
            'fecha_actualizacion' => now(),
        ]);

        // Notificar a la fundación
        $fundacion = $publicacion->fundacion;
        if ($fundacion) {
            \App\Models\Notificacion::create([
                'usuario_id'  => $fundacion->usuario_id,
                'tipo'        => 'ACTIVIDAD_MODIFICADA',
                'mensaje'     => "Tu convocatoria \"{$publicacion->titulo}\" fue devuelta para correcciones. Motivo: {$motivo}",
                'objeto_tipo' => 'PUBLICACION',
                'objeto_id'   => $publicacion->id,
            ]);
        }

        return $publicacion->fresh();
    }
}

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
            throw ValidationException::withMessages(['estado' => 'Solo se pueden publicar convocatorias en estado BORRADOR.']);
        }

        $publicacion->update([
            'estado'           => EstadoPublicacion::PUBLICADA,
            'fecha_publicacion' => now(),
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
}

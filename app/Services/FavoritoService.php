<?php

namespace App\Services;

use App\Enums\TipoFavorito;
use App\Models\Fundacion;
use App\Models\Publicacion;
use App\Models\Voluntario;
use App\Models\VoluntarioFavorito;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

class FavoritoService
{
    public function listar(Voluntario $voluntario, ?string $tipo = null): Collection
    {
        $query = VoluntarioFavorito::where('voluntario_id', $voluntario->id)
            ->with([
                'publicacion.fundacion',
                'publicacion.categoria',
                'publicacion.municipio.departamento',
                'publicacion.imagenes',
                'fundacion.municipio',
            ])
            ->orderByDesc('fecha_creacion');

        if ($tipo) {
            $query->where('tipo', $tipo);
        }

        return $query->get();
    }

    public function idsPorTipo(Voluntario $voluntario): array
    {
        $favoritos = VoluntarioFavorito::where('voluntario_id', $voluntario->id)->get();

        return [
            'publicaciones' => $favoritos->where('tipo', TipoFavorito::PUBLICACION->value)->pluck('publicacion_id')->filter()->values(),
            'fundaciones'   => $favoritos->where('tipo', TipoFavorito::FUNDACION->value)->pluck('fundacion_id')->filter()->values(),
        ];
    }

    public function agregarPublicacion(Voluntario $voluntario, string $publicacionId): VoluntarioFavorito
    {
        $publicacion = Publicacion::where('id', $publicacionId)
            ->where('estado', 'PUBLICADA')
            ->firstOrFail();

        $existente = VoluntarioFavorito::where('voluntario_id', $voluntario->id)
            ->where('publicacion_id', $publicacion->id)
            ->first();

        if ($existente) {
            return $existente->load(['publicacion.fundacion', 'publicacion.imagenes']);
        }

        return VoluntarioFavorito::create([
            'voluntario_id'  => $voluntario->id,
            'tipo'           => TipoFavorito::PUBLICACION->value,
            'publicacion_id' => $publicacion->id,
        ])->load(['publicacion.fundacion', 'publicacion.imagenes']);
    }

    public function agregarFundacion(Voluntario $voluntario, string $fundacionId): VoluntarioFavorito
    {
        $fundacion = Fundacion::where('id', $fundacionId)
            ->where('estado_verificacion', 'APROBADA')
            ->firstOrFail();

        $existente = VoluntarioFavorito::where('voluntario_id', $voluntario->id)
            ->where('fundacion_id', $fundacion->id)
            ->first();

        if ($existente) {
            return $existente->load('fundacion');
        }

        return VoluntarioFavorito::create([
            'voluntario_id' => $voluntario->id,
            'tipo'          => TipoFavorito::FUNDACION->value,
            'fundacion_id'  => $fundacion->id,
        ])->load('fundacion');
    }

    public function quitar(Voluntario $voluntario, VoluntarioFavorito $favorito): void
    {
        if ($favorito->voluntario_id !== $voluntario->id) {
            throw ValidationException::withMessages(['favorito' => 'No autorizado.']);
        }

        $favorito->delete();
    }

    public function togglePublicacion(Voluntario $voluntario, string $publicacionId): array
    {
        $favorito = VoluntarioFavorito::where('voluntario_id', $voluntario->id)
            ->where('publicacion_id', $publicacionId)
            ->first();

        if ($favorito) {
            $favorito->delete();
            return ['favorito' => false];
        }

        $this->agregarPublicacion($voluntario, $publicacionId);
        return ['favorito' => true];
    }
}

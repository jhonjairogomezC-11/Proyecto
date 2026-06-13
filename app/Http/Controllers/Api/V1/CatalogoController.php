<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\AreaImpactoResource;
use App\Http\Resources\HabilidadResource;
use App\Http\Resources\InteresResource;
use App\Http\Resources\MunicipioResource;
use App\Models\AreaImpacto;
use App\Models\Departamento;
use App\Models\Habilidad;
use App\Models\Interes;
use App\Models\Municipio;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogoController extends Controller
{
    public function departamentos(): JsonResponse
    {
        return response()->json(Departamento::orderBy('nombre')->get(['id', 'nombre']));
    }

    public function municipios(Request $request): JsonResponse
    {
        $query = Municipio::with('departamento')->orderBy('nombre');

        if ($request->filled('departamento_id')) {
            $query->where('departamento_id', $request->departamento_id);
        }

        return response()->json(MunicipioResource::collection($query->get()));
    }

    public function habilidades(): JsonResponse
    {
        return response()->json(HabilidadResource::collection(Habilidad::orderBy('nombre')->get()));
    }

    public function intereses(): JsonResponse
    {
        return response()->json(InteresResource::collection(Interes::orderBy('nombre')->get()));
    }

    public function areasImpacto(): JsonResponse
    {
        return response()->json(AreaImpactoResource::collection(AreaImpacto::orderBy('nombre')->get()));
    }
}

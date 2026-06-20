<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Voluntario\StoreVoluntarioRequest;
use App\Http\Requests\Voluntario\UpdateVoluntarioRequest;
use App\Http\Resources\VoluntarioResource;
use App\Services\VoluntarioDashboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoluntarioController extends Controller
{
    public function __construct(private VoluntarioDashboardService $dashboardService) {}

    public function show(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()
            ->with(['municipio.departamento', 'habilidades', 'intereses'])
            ->firstOrFail();

        return response()->json(new VoluntarioResource($voluntario));
    }

    public function store(StoreVoluntarioRequest $request): JsonResponse
    {
        $usuario = $request->user();

        if ($usuario->voluntario) {
            return response()->json(['message' => 'Ya tienes un perfil de voluntario.'], 422);
        }

        $data       = $request->validated();
        $voluntario = $usuario->voluntario()->create($data);

        if (!empty($data['habilidades'])) {
            $voluntario->habilidades()->sync($data['habilidades']);
        }
        if (!empty($data['intereses'])) {
            $voluntario->intereses()->sync($data['intereses']);
        }

        return response()->json(new VoluntarioResource($voluntario->load(['municipio.departamento', 'habilidades', 'intereses'])), 201);
    }

    public function update(UpdateVoluntarioRequest $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        $data       = $request->validated();

        $voluntario->update($data);

        if (array_key_exists('habilidades', $data)) {
            $voluntario->habilidades()->sync($data['habilidades'] ?? []);
        }
        if (array_key_exists('intereses', $data)) {
            $voluntario->intereses()->sync($data['intereses'] ?? []);
        }

        return response()->json(new VoluntarioResource($voluntario->fresh(['municipio.departamento', 'habilidades', 'intereses'])));
    }

    /** GET /api/v1/voluntario/dashboard */
    public function dashboard(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        return response()->json($this->dashboardService->resumen($voluntario));
    }
}

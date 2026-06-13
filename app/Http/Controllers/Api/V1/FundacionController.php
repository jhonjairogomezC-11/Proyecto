<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Fundacion\StoreFundacionRequest;
use App\Http\Requests\Fundacion\UpdateFundacionRequest;
use App\Http\Resources\FundacionResource;
use App\Models\Fundacion;
use App\Services\FundacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FundacionController extends Controller
{
    public function __construct(private FundacionService $fundacionService) {}

    public function index(): JsonResponse
    {
        $fundaciones = Fundacion::with(['municipio.departamento', 'areas'])
            ->whereIn('estado_verificacion', ['APROBADA'])
            ->paginate(15);

        return response()->json(FundacionResource::collection($fundaciones)->response()->getData(true));
    }

    public function show(Fundacion $fundacion): JsonResponse
    {
        return response()->json(new FundacionResource($fundacion->load(['municipio.departamento', 'areas'])));
    }

    public function store(StoreFundacionRequest $request): JsonResponse
    {
        $usuario = $request->user();

        if ($usuario->fundacion) {
            return response()->json(['message' => 'Ya tienes una fundación registrada.'], 422);
        }

        $data      = $request->validated();
        $fundacion = $usuario->fundacion()->create($data);

        if (!empty($data['areas'])) {
            $fundacion->areas()->sync($data['areas']);
        }

        return response()->json(new FundacionResource($fundacion->load(['municipio.departamento', 'areas'])), 201);
    }

    public function update(UpdateFundacionRequest $request, Fundacion $fundacion): JsonResponse
    {
        $this->authorize('update', $fundacion);

        $data = $request->validated();
        $fundacion->update($data);

        if (array_key_exists('areas', $data)) {
            $fundacion->areas()->sync($data['areas'] ?? []);
        }

        return response()->json(new FundacionResource($fundacion->fresh(['municipio.departamento', 'areas'])));
    }

    public function miPerfil(Request $request): JsonResponse
    {
        $fundacion = $request->user()->fundacion()
            ->with(['municipio.departamento', 'areas'])
            ->firstOrFail();

        return response()->json(new FundacionResource($fundacion));
    }
}

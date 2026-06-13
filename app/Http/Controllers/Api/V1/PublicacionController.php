<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Publicacion\StorePublicacionRequest;
use App\Http\Requests\Publicacion\UpdatePublicacionRequest;
use App\Http\Resources\PublicacionResource;
use App\Models\Publicacion;
use App\Services\PublicacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicacionController extends Controller
{
    public function __construct(private PublicacionService $publicacionService) {}

    public function index(Request $request): JsonResponse
    {
        $query = Publicacion::with(['fundacion', 'categoria', 'municipio.departamento', 'habilidades'])
            ->where('estado', 'PUBLICADA')
            ->where('oculta_por_admin', false);

        if ($request->filled('categoria_id')) {
            $query->where('categoria_id', $request->categoria_id);
        }
        if ($request->filled('modalidad')) {
            $query->where('modalidad', $request->modalidad);
        }
        if ($request->filled('municipio_id')) {
            $query->where('municipio_id', $request->municipio_id);
        }

        $publicaciones = $query->orderBy('fecha_inicio')->paginate(15);

        return response()->json(PublicacionResource::collection($publicaciones)->response()->getData(true));
    }

    public function show(Publicacion $publicacion): JsonResponse
    {
        return response()->json(
            new PublicacionResource($publicacion->load(['fundacion', 'categoria', 'municipio.departamento', 'habilidades']))
        );
    }

    public function store(StorePublicacionRequest $request): JsonResponse
    {
        $fundacion   = $request->user()->fundacion()->firstOrFail();
        $publicacion = $this->publicacionService->crear($fundacion, $request->validated());

        return response()->json(new PublicacionResource($publicacion), 201);
    }

    public function update(UpdatePublicacionRequest $request, Publicacion $publicacion): JsonResponse
    {
        $this->authorize('update', $publicacion);

        $publicacion = $this->publicacionService->actualizar($publicacion, $request->validated());

        return response()->json(new PublicacionResource($publicacion));
    }

    public function publicar(Request $request, Publicacion $publicacion): JsonResponse
    {
        $this->authorize('update', $publicacion);

        $publicacion = $this->publicacionService->publicar($publicacion);

        return response()->json(new PublicacionResource($publicacion));
    }

    public function cancelar(Request $request, Publicacion $publicacion): JsonResponse
    {
        $this->authorize('update', $publicacion);

        $publicacion = $this->publicacionService->cancelar($publicacion);

        return response()->json(new PublicacionResource($publicacion));
    }

    public function misFundacion(Request $request): JsonResponse
    {
        $fundacion    = $request->user()->fundacion()->firstOrFail();
        $publicaciones = Publicacion::with(['categoria', 'municipio.departamento'])
            ->where('fundacion_id', $fundacion->id)
            ->orderByDesc('fecha_creacion')
            ->paginate(15);

        return response()->json(PublicacionResource::collection($publicaciones)->response()->getData(true));
    }
}

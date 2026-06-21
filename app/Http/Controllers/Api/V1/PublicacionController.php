<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Publicacion\StorePublicacionRequest;
use App\Http\Requests\Publicacion\UpdatePublicacionRequest;
use App\Http\Resources\PublicacionResource;
use App\Models\Publicacion;
use App\Models\PublicacionImagen;
use App\Services\PublicacionImagenService;
use App\Services\PublicacionService;
use App\Support\PaginationHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicacionController extends Controller
{
    public function __construct(
        private PublicacionService $publicacionService,
        private PublicacionImagenService $imagenService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Publicacion::with(['fundacion', 'categoria', 'municipio.departamento', 'habilidades', 'imagenes'])
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
        if ($request->filled('buscar')) {
            $term = '%' . $request->buscar . '%';
            $query->where(function ($q) use ($term) {
                $q->where('titulo', 'ilike', $term)
                  ->orWhere('descripcion', 'ilike', $term)
                  ->orWhereHas('fundacion', fn ($f) => $f->where('nombre', 'ilike', $term))
                  ->orWhereHas('municipio', fn ($m) => $m->where('nombre', 'ilike', $term));
            });
        }

        $publicaciones = $query->orderBy('fecha_inicio')
            ->paginate(PaginationHelper::perPage($request, 15));

        return response()->json(PublicacionResource::collection($publicaciones)->response()->getData(true));
    }

    public function show(Publicacion $publicacion): JsonResponse
    {
        return response()->json(
            new PublicacionResource($publicacion->load(['fundacion', 'categoria', 'municipio.departamento', 'habilidades', 'imagenes']))
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
        $publicaciones = Publicacion::with(['categoria', 'municipio.departamento', 'imagenes'])
            ->where('fundacion_id', $fundacion->id)
            ->orderByDesc('fecha_creacion')
            ->paginate(PaginationHelper::perPage($request, 15));

        return response()->json(PublicacionResource::collection($publicaciones)->response()->getData(true));
    }

    public function subirImagenes(Request $request, Publicacion $publicacion): JsonResponse
    {
        $this->authorize('update', $publicacion);

        $request->validate([
            'imagenes'   => ['required', 'array', 'min:1'],
            'imagenes.*' => ['required', 'image', 'max:5120'],
        ]);

        $this->imagenService->subir($publicacion, $request->file('imagenes'));

        return response()->json(
            new PublicacionResource($publicacion->fresh(['categoria', 'municipio.departamento', 'habilidades', 'imagenes']))
        );
    }

    public function eliminarImagen(Request $request, Publicacion $publicacion, PublicacionImagen $imagen): JsonResponse
    {
        $this->authorize('update', $publicacion);
        $this->imagenService->eliminar($publicacion, $imagen);

        return response()->json(
            new PublicacionResource($publicacion->fresh(['categoria', 'municipio.departamento', 'habilidades', 'imagenes']))
        );
    }
}

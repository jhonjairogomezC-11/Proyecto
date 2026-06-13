<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Postulacion\StorePostulacionRequest;
use App\Http\Requests\Postulacion\UpdatePostulacionRequest;
use App\Http\Resources\PostulacionResource;
use App\Models\Postulacion;
use App\Services\PostulacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PostulacionController extends Controller
{
    public function __construct(private PostulacionService $postulacionService) {}

    public function store(StorePostulacionRequest $request): JsonResponse
    {
        $voluntario  = $request->user()->voluntario()->firstOrFail();
        $postulacion = $this->postulacionService->postular(
            $voluntario,
            $request->publicacion_id,
            $request->mensaje_voluntario
        );

        return response()->json(new PostulacionResource($postulacion->load(['publicacion', 'voluntario'])), 201);
    }

    public function misPostulaciones(Request $request): JsonResponse
    {
        $voluntario   = $request->user()->voluntario()->firstOrFail();
        $postulaciones = Postulacion::with(['publicacion.fundacion', 'publicacion.municipio.departamento'])
            ->where('voluntario_id', $voluntario->id)
            ->orderByDesc('fecha_postulacion')
            ->paginate(15);

        return response()->json(PostulacionResource::collection($postulaciones)->response()->getData(true));
    }

    public function postulacionesDeFundacion(Request $request, string $publicacionId): JsonResponse
    {
        $fundacion = $request->user()->fundacion()->firstOrFail();

        $postulaciones = Postulacion::with(['voluntario.usuario', 'voluntario.municipio.departamento'])
            ->whereHas('publicacion', fn($q) => $q->where('fundacion_id', $fundacion->id))
            ->where('publicacion_id', $publicacionId)
            ->paginate(15);

        return response()->json(PostulacionResource::collection($postulaciones)->response()->getData(true));
    }

    public function responder(UpdatePostulacionRequest $request, Postulacion $postulacion): JsonResponse
    {
        $fundacion = $request->user()->fundacion()->firstOrFail();

        if ($postulacion->publicacion->fundacion_id !== $fundacion->id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $postulacion = $this->postulacionService->responder(
            $postulacion,
            $request->estado,
            $request->motivo_rechazo
        );

        return response()->json(new PostulacionResource($postulacion));
    }

    public function retirar(Request $request, Postulacion $postulacion): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();

        if ($postulacion->voluntario_id !== $voluntario->id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $postulacion = $this->postulacionService->retirar($postulacion);

        return response()->json(new PostulacionResource($postulacion));
    }

    public function confirmarAsistencia(Request $request, Postulacion $postulacion): JsonResponse
    {
        $fundacion = $request->user()->fundacion()->firstOrFail();

        if ($postulacion->publicacion->fundacion_id !== $fundacion->id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $request->validate([
            'asistio'              => ['required', 'boolean'],
            'calificacion'         => ['required_if:asistio,true', 'nullable', 'integer', 'between:1,5'],
            'comentario_fundacion' => ['nullable', 'string', 'max:1000'],
        ]);

        $postulacion = $this->postulacionService->confirmarAsistencia(
            $postulacion,
            $request->boolean('asistio'),
            $request->calificacion,
            $request->comentario_fundacion
        );

        return response()->json(new PostulacionResource($postulacion));
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PublicacionResource;
use App\Models\Publicacion;
use App\Services\PublicacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPublicacionController extends Controller
{
    public function __construct(private PublicacionService $service) {}

    /** GET /api/v1/admin/publicaciones — lista pendientes de aprobación */
    public function index(Request $request): JsonResponse
    {
        $query = Publicacion::with(['fundacion', 'categoria', 'municipio.departamento']);

        $estado = $request->get('estado', 'PENDIENTE_APROBACION');
        $query->where('estado', $estado);

        if ($request->filled('fundacion')) {
            $query->whereHas('fundacion', fn ($q) =>
                $q->where('nombre', 'ilike', '%' . $request->fundacion . '%')
            );
        }

        $publicaciones = $query->orderByDesc('fecha_actualizacion')->paginate(20);

        return response()->json(
            PublicacionResource::collection($publicaciones)->response()->getData(true)
        );
    }

    /** PUT /api/v1/admin/publicaciones/{publicacion}/aprobar */
    public function aprobar(Publicacion $publicacion): JsonResponse
    {
        $pub = $this->service->aprobar($publicacion);
        return response()->json(new PublicacionResource($pub));
    }

    /** PUT /api/v1/admin/publicaciones/{publicacion}/rechazar */
    public function rechazar(Request $request, Publicacion $publicacion): JsonResponse
    {
        $request->validate([
            'motivo' => ['required', 'string', 'min:10', 'max:500'],
        ]);

        $pub = $this->service->rechazarPublicacion($publicacion, $request->motivo);
        return response()->json(new PublicacionResource($pub));
    }
}

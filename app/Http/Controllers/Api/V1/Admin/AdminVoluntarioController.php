<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\VoluntarioResource;
use App\Models\Voluntario;
use App\Services\AdminVoluntarioService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminVoluntarioController extends Controller
{
    public function __construct(private AdminVoluntarioService $service) {}

    /** GET /api/v1/admin/voluntarios */
    public function index(Request $request): JsonResponse
    {
        $query = Voluntario::with(['usuario', 'municipio.departamento']);

        if ($request->filled('nombre')) {
            $query->whereHas('usuario', fn ($q) =>
                $q->where('nombre', 'ilike', '%' . $request->nombre . '%')
            );
        }

        if ($request->filled('estado')) {
            $query->whereHas('usuario', fn ($q) =>
                $q->where('estado', $request->estado)
            );
        }

        if ($request->filled('municipio_id')) {
            $query->where('municipio_id', $request->municipio_id);
        }

        $voluntarios = $query->orderByDesc('fecha_creacion')->paginate(20);

        return response()->json(
            VoluntarioResource::collection($voluntarios)->response()->getData(true)
        );
    }

    /** GET /api/v1/admin/voluntarios/{voluntario} */
    public function show(Voluntario $voluntario): JsonResponse
    {
        return response()->json($this->service->perfilCompleto($voluntario));
    }

    /** PUT /api/v1/admin/voluntarios/{voluntario}/suspender */
    public function suspender(Request $request, Voluntario $voluntario): JsonResponse
    {
        $request->validate([
            'motivo'        => ['required', 'string', 'max:500'],
            'duracion_dias' => ['nullable', 'integer', 'min:1', 'max:365'],
        ]);

        $admin      = $request->user()->adminPerfil()->firstOrFail();
        $voluntario = $this->service->suspender(
            $admin,
            $voluntario,
            $request->motivo,
            $request->duracion_dias
        );

        return response()->json(new VoluntarioResource($voluntario));
    }

    /** PUT /api/v1/admin/voluntarios/{voluntario}/bloquear */
    public function bloquear(Request $request, Voluntario $voluntario): JsonResponse
    {
        $request->validate([
            'motivo' => ['required', 'string', 'max:500'],
        ]);

        $admin      = $request->user()->adminPerfil()->firstOrFail();
        $voluntario = $this->service->bloquear($admin, $voluntario, $request->motivo);

        return response()->json(new VoluntarioResource($voluntario));
    }

    /** PUT /api/v1/admin/voluntarios/{voluntario}/reactivar */
    public function reactivar(Request $request, Voluntario $voluntario): JsonResponse
    {
        $admin      = $request->user()->adminPerfil()->firstOrFail();
        $voluntario = $this->service->reactivar($admin, $voluntario);

        return response()->json(new VoluntarioResource($voluntario));
    }

    /** POST /api/v1/admin/voluntarios/{voluntario}/advertencias */
    public function advertencia(Request $request, Voluntario $voluntario): JsonResponse
    {
        $request->validate([
            'motivo' => ['required', 'string', 'max:500'],
        ]);

        $admin  = $request->user()->adminPerfil()->firstOrFail();
        $result = $this->service->emitirAdvertencia($admin, $voluntario, $request->motivo);

        return response()->json([
            'message'       => 'Advertencia emitida correctamente.',
            'advertencia'   => $result['advertencia'],
            'total_activas' => $result['total_activas'],
        ], 201);
    }

    /** GET /api/v1/admin/voluntarios/{voluntario}/historial */
    public function historial(Voluntario $voluntario): JsonResponse
    {
        return response()->json($this->service->historial($voluntario));
    }
}

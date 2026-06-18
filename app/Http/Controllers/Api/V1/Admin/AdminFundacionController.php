<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\FundacionResource;
use App\Models\Fundacion;
use App\Services\AdminFundacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminFundacionController extends Controller
{
    public function __construct(private AdminFundacionService $service) {}

    /** GET /api/v1/admin/fundaciones */
    public function index(Request $request): JsonResponse
    {
        $query = Fundacion::with(['municipio.departamento', 'usuario', 'areas']);

        if ($request->filled('estado')) {
            $query->where('estado_verificacion', $request->estado);
        }

        if ($request->filled('nombre')) {
            $query->where('nombre', 'ilike', '%' . $request->nombre . '%');
        }

        $fundaciones = $query->orderByDesc('fecha_creacion')->paginate(20);

        return response()->json(
            FundacionResource::collection($fundaciones)->response()->getData(true)
        );
    }

    /** GET /api/v1/admin/fundaciones/{fundacion} */
    public function show(Fundacion $fundacion): JsonResponse
    {
        return response()->json(
            new FundacionResource($fundacion->load(['municipio.departamento', 'areas', 'usuario']))
        );
    }

    /** PUT /api/v1/admin/fundaciones/{fundacion}/aprobar */
    public function aprobar(Request $request, Fundacion $fundacion): JsonResponse
    {
        $admin     = $request->user()->adminPerfil()->firstOrFail();
        $fundacion = $this->service->aprobar($admin, $fundacion);
        return response()->json(new FundacionResource($fundacion));
    }

    /** PUT /api/v1/admin/fundaciones/{fundacion}/rechazar */
    public function rechazar(Request $request, Fundacion $fundacion): JsonResponse
    {
        $request->validate([
            'motivo' => ['required', 'string', 'min:10', 'max:500'],
        ]);
        $admin     = $request->user()->adminPerfil()->firstOrFail();
        $fundacion = $this->service->rechazar($admin, $fundacion, $request->motivo);
        return response()->json(new FundacionResource($fundacion));
    }

    /** PUT /api/v1/admin/fundaciones/{fundacion}/suspender */
    public function suspender(Request $request, Fundacion $fundacion): JsonResponse
    {
        $request->validate([
            'motivo' => ['required', 'string', 'max:500'],
        ]);
        $admin     = $request->user()->adminPerfil()->firstOrFail();
        $fundacion = $this->service->suspender($admin, $fundacion, $request->motivo);
        return response()->json(new FundacionResource($fundacion));
    }

    /** PUT /api/v1/admin/fundaciones/{fundacion}/reactivar */
    public function reactivar(Request $request, Fundacion $fundacion): JsonResponse
    {
        $admin     = $request->user()->adminPerfil()->firstOrFail();
        $fundacion = $this->service->reactivar($admin, $fundacion);
        return response()->json(new FundacionResource($fundacion));
    }

    /** GET /api/v1/admin/fundaciones/{fundacion}/historial */
    public function historial(Fundacion $fundacion): JsonResponse
    {
        return response()->json($this->service->historial($fundacion));
    }

    /** POST /api/v1/admin/fundaciones/{fundacion}/documentos */
    public function subirDocumento(Request $request, Fundacion $fundacion): JsonResponse
    {
        $request->validate([
            'tipo_documento' => ['required', 'string', 'in:camara_comercio,id_representante,certificado'],
            'archivo'        => ['required', 'file', 'mimes:pdf,jpg,jpeg,png', 'max:10240'],
        ]);

        $doc = $this->service->subirDocumento($fundacion, $request->tipo_documento, $request->file('archivo'));

        return response()->json($doc, 201);
    }

    /** GET /api/v1/admin/fundaciones/{fundacion}/documentos */
    public function documentos(Fundacion $fundacion): JsonResponse
    {
        return response()->json($this->service->listarDocumentos($fundacion));
    }
}

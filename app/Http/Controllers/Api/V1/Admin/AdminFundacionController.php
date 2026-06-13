<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\GestionarFundacionRequest;
use App\Http\Resources\FundacionResource;
use App\Models\Fundacion;
use App\Services\FundacionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminFundacionController extends Controller
{
    public function __construct(private FundacionService $fundacionService) {}

    public function index(Request $request): JsonResponse
    {
        $query = Fundacion::with(['municipio.departamento', 'usuario']);

        if ($request->filled('estado')) {
            $query->where('estado_verificacion', $request->estado);
        }

        $fundaciones = $query->orderByDesc('fecha_creacion')->paginate(15);

        return response()->json(FundacionResource::collection($fundaciones)->response()->getData(true));
    }

    public function gestionar(GestionarFundacionRequest $request, Fundacion $fundacion): JsonResponse
    {
        $admin = $request->user()->adminPerfil()->firstOrFail();

        $fundacion = $this->fundacionService->gestionar(
            $admin,
            $fundacion,
            $request->estado,
            $request->motivo
        );

        return response()->json(new FundacionResource($fundacion));
    }
}

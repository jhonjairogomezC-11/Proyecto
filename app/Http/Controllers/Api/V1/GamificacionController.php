<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\PuntoService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GamificacionController extends Controller
{
    public function __construct(private PuntoService $puntoService) {}

    /** GET /api/v1/voluntario/puntos */
    public function misPuntos(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        return response()->json($this->puntoService->resumenPuntos($voluntario));
    }

    /** GET /api/v1/voluntario/logros */
    public function misLogros(Request $request): JsonResponse
    {
        $voluntario = $request->user()->voluntario()->firstOrFail();
        return response()->json($this->puntoService->resumenLogros($voluntario));
    }

    /** GET /api/v1/ranking */
    public function ranking(Request $request): JsonResponse
    {
        $top = min(50, max(1, (int) $request->get('top', 10)));
        $voluntarioId = null;

        // Si el usuario está autenticado y es voluntario, incluir su posición
        if ($request->user() && $request->user()->voluntario) {
            $voluntarioId = $request->user()->voluntario->id;
        }

        return response()->json($this->puntoService->ranking($top, $voluntarioId));
    }
}

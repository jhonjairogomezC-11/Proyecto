<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificacionResource;
use App\Models\Notificacion;
use App\Support\PaginationHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificacionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notificaciones = Notificacion::where('usuario_id', $request->user()->id)
            ->orderByDesc('fecha_creacion')
            ->paginate(PaginationHelper::perPage($request, 20));

        return response()->json(NotificacionResource::collection($notificaciones)->response()->getData(true));
    }

    public function marcarLeida(Request $request, Notificacion $notificacion): JsonResponse
    {
        if ($notificacion->usuario_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $notificacion->update(['leida' => true, 'fecha_lectura' => now()]);

        return response()->json(new NotificacionResource($notificacion));
    }

    public function marcarTodasLeidas(Request $request): JsonResponse
    {
        $afectadas = Notificacion::where('usuario_id', $request->user()->id)
            ->where('leida', false)
            ->update(['leida' => true, 'fecha_lectura' => now()]);

        return response()->json(['message' => "{$afectadas} notificaciones marcadas como leídas."]);
    }

    public function noLeidas(Request $request): JsonResponse
    {
        $total = Notificacion::where('usuario_id', $request->user()->id)
            ->where('leida', false)
            ->count();

        return response()->json(['total' => $total]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreReporteRequest;
use App\Models\AdminAccion;
use App\Models\Reporte;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminReporteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Reporte::with('reportante');

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        return response()->json($query->orderByDesc('fecha_creacion')->paginate(15));
    }

    public function store(StoreReporteRequest $request): JsonResponse
    {
        $reporte = Reporte::create(array_merge($request->validated(), [
            'reportante_id' => $request->user()->id,
        ]));

        return response()->json($reporte, 201);
    }

    public function resolver(Request $request, Reporte $reporte): JsonResponse
    {
        $request->validate([
            'estado'     => ['required', 'in:RESUELTO,DESESTIMADO'],
            'resolucion' => ['required', 'string', 'max:1000'],
        ]);

        if (!in_array($reporte->estado->value, ['PENDIENTE', 'EN_REVISION'])) {
            return response()->json(['message' => 'El reporte ya fue resuelto.'], 422);
        }

        $admin = $request->user()->adminPerfil()->firstOrFail();

        $reporte->update([
            'estado'            => $request->estado,
            'resolucion'        => $request->resolucion,
            'fecha_resolucion'  => now(),
            'admin_asignado_id' => $admin->id,
            'fecha_asignacion'  => $reporte->fecha_asignacion ?? now(),
        ]);

        AdminAccion::create([
            'admin_id'    => $admin->id,
            'tipo'        => $request->estado === 'RESUELTO' ? 'REPORTE_RESUELTO' : 'REPORTE_DESESTIMADO',
            'objeto_tipo' => 'REPORTE',
            'objeto_id'   => $reporte->id,
            'motivo'      => $request->resolucion,
        ]);

        return response()->json($reporte->fresh());
    }
}

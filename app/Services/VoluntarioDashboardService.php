<?php

namespace App\Services;

use App\Http\Resources\PostulacionResource;
use App\Models\Postulacion;
use App\Models\Voluntario;
use Carbon\Carbon;

class VoluntarioDashboardService
{
    public function __construct(
        private PuntoService $puntoService,
        private NivelVoluntarioService $nivelService,
    ) {}

    public function resumen(Voluntario $voluntario): array
    {
        $ahora       = Carbon::now();
        $inicioSemana = $ahora->copy()->startOfWeek();
        $inicioMes    = $ahora->copy()->startOfMonth();

        $completadasQuery = $voluntario->postulaciones()->where('estado', 'ASISTIO');

        $actividadesCompletadas = [
            'total'       => (clone $completadasQuery)->count(),
            'esta_semana' => (clone $completadasQuery)->where('fecha_confirmacion', '>=', $inicioSemana)->count(),
            'este_mes'    => (clone $completadasQuery)->where('fecha_confirmacion', '>=', $inicioMes)->count(),
        ];

        $puntosData = $this->puntoService->resumenPuntos($voluntario, 5);
        $puntos     = $puntosData['total_historico'] ?? 0;
        $nivel      = $this->nivelService->progresoNivel($puntos);

        $logrosData = $this->puntoService->resumenLogros($voluntario);
        $logroProximo = collect($logrosData['pendientes'])
            ->sortByDesc('porcentaje')
            ->first();

        $rankingData = $this->puntoService->ranking(50, $voluntario->id);
        $miPosicion  = $rankingData['mi_posicion']
            ?? $rankingData['top']->firstWhere('voluntario_id', $voluntario->id);

        $totalRanking = $rankingData['total'] ?: 1;
        $posicion     = $miPosicion['posicion'] ?? null;
        $topPercent   = $posicion ? round((1 - ($posicion - 1) / $totalRanking) * 100, 1) : null;

        // Próximas actividades: aceptadas con fecha futura o en curso
        $proximas = Postulacion::with(['publicacion.fundacion', 'publicacion.municipio', 'publicacion.imagenes'])
            ->where('voluntario_id', $voluntario->id)
            ->whereIn('estado', ['PENDIENTE', 'ACEPTADO'])
            ->whereHas('publicacion', fn ($q) => $q->where('fecha_fin', '>=', $ahora->toDateString()))
            ->join('publicaciones', 'publicaciones.id', '=', 'postulaciones.publicacion_id')
            ->orderBy('publicaciones.fecha_inicio')
            ->select('postulaciones.*')
            ->limit(3)
            ->get();

        $postulacionesResumen = [
            'pendientes'  => $voluntario->postulaciones()->where('estado', 'PENDIENTE')->count(),
            'aceptadas'   => $voluntario->postulaciones()->where('estado', 'ACEPTADO')->count(),
            'rechazadas'  => $voluntario->postulaciones()->where('estado', 'RECHAZADO')->count(),
            'completadas' => $actividadesCompletadas['total'],
        ];

        // Meta mensual de participación (5 actividades/mes como referencia)
        $metaMensual = 5;
        $partMes     = $actividadesCompletadas['este_mes'];

        return [
            'perfil_completo'        => true,
            'actividades_completadas'=> $actividadesCompletadas,
            'puntos'                 => [
                'saldo'           => $puntosData['saldo'],
                'total_historico' => $puntos,
            ],
            'nivel'                  => $nivel,
            'logros'                 => [
                'desbloqueados' => count($logrosData['obtenidos']),
                'recientes'     => collect($logrosData['obtenidos'])->take(3)->values()->all(),
            ],
            'logro_proximo'          => $logroProximo,
            'ranking'                => [
                'posicion'    => $posicion,
                'total'       => $totalRanking,
                'top_percent' => $topPercent,
            ],
            'proximas_actividades'   => PostulacionResource::collection($proximas)->resolve(),
            'postulaciones_resumen'  => $postulacionesResumen,
            'progreso_mensual'       => [
                'completadas' => $partMes,
                'meta'        => $metaMensual,
                'faltan'      => max(0, $metaMensual - $partMes),
                'porcentaje'  => min(100, round($partMes / $metaMensual * 100)),
            ],
            'transacciones_recientes'=> $puntosData['transacciones'],
        ];
    }
}

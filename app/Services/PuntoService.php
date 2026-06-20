<?php

namespace App\Services;

use App\Enums\DificultadTipo;
use App\Models\Logro;
use App\Models\Postulacion;
use App\Models\TransaccionPuntos;
use App\Models\Voluntario;
use App\Models\VoluntarioLogro;
use App\Models\VoluntarioPuntos;
use Illuminate\Support\Facades\DB;

class PuntoService
{
    /**
     * Acreditar puntos cuando una postulación pasa a ASISTIO.
     * Calcula puntos base + bonos y evalúa logros nuevos.
     */
    public function acreditar(Postulacion $postulacion): TransaccionPuntos
    {
        $voluntario  = $postulacion->voluntario;
        $publicacion = $postulacion->publicacion;

        // ── 1. Puntos base por dificultad ─────────────────────
        $dificultad = $publicacion->dificultad instanceof DificultadTipo
            ? $publicacion->dificultad
            : DificultadTipo::tryFrom($publicacion->dificultad ?? 'MEDIA') ?? DificultadTipo::MEDIA;

        $puntosBase = $dificultad->puntosBase();

        // ── 2. Bonos adicionales ──────────────────────────────
        $bonus = 0;
        $motivoBonus = [];

        // Bono por actividad urgente (+50% del base)
        if ($publicacion->urgente) {
            $bonoUrgente = (int) round($puntosBase * 0.5);
            $bonus      += $bonoUrgente;
            $motivoBonus[] = "urgente +{$bonoUrgente}";
        }

        // Bono por duración: si dura más de 3 días → +10 pts extra
        $diasDuracion = 0;
        if ($publicacion->fecha_inicio && $publicacion->fecha_fin) {
            $diasDuracion = $publicacion->fecha_inicio->diffInDays($publicacion->fecha_fin);
        }
        if ($diasDuracion >= 3) {
            $bonoDuracion = min(50, (int) ($diasDuracion * 2)); // máximo 50 pts de bono por duración
            $bonus       += $bonoDuracion;
            $motivoBonus[] = "duración {$diasDuracion}d +{$bonoDuracion}";
        }

        // Bono por modalidad PRESENCIAL (+5 pts — requiere desplazamiento)
        if ($publicacion->modalidad?->value === 'PRESENCIAL' || $publicacion->modalidad === 'PRESENCIAL') {
            $bonus        += 5;
            $motivoBonus[] = 'presencial +5';
        }

        // Bono por actividad MUY_DIFICIL (+25 pts adicionales sobre base)
        if ($dificultad === DificultadTipo::MUY_DIFICIL) {
            $bonus        += 25;
            $motivoBonus[] = 'muy_difícil +25';
        }

        $puntosTotal = $puntosBase + $bonus;
        $motivo = "Participación: {$publicacion->titulo} ({$dificultad->label()})";
        if ($motivoBonus) {
            $motivo .= ' [Bonos: ' . implode(', ', $motivoBonus) . ']';
        }

        // ── 3. Registrar transacción y actualizar saldo ───────
        DB::transaction(function () use ($voluntario, $postulacion, $puntosBase, $bonus, $puntosTotal, $motivo) {
            TransaccionPuntos::create([
                'voluntario_id'  => $voluntario->id,
                'postulacion_id' => $postulacion->id,
                'puntos_base'    => $puntosBase,
                'puntos_bonus'   => $bonus,
                'puntos_total'   => $puntosTotal,
                'motivo'         => $motivo,
            ]);

            // Upsert seguro para PostgreSQL
            DB::statement("
                INSERT INTO voluntario_puntos (voluntario_id, saldo, total_historico, fecha_actualizacion)
                VALUES (?, ?, ?, NOW())
                ON CONFLICT (voluntario_id) DO UPDATE
                SET saldo = voluntario_puntos.saldo + EXCLUDED.saldo,
                    total_historico = voluntario_puntos.total_historico + EXCLUDED.total_historico,
                    fecha_actualizacion = NOW()
            ", [$voluntario->id, $puntosTotal, $puntosTotal]);
        });

        // ── 4. Evaluar y otorgar logros nuevos ────────────────
        $this->evaluarLogros($voluntario);

        return TransaccionPuntos::where('voluntario_id', $voluntario->id)
            ->latest('fecha')
            ->first();
    }

    /**
     * Evalúa y otorga todos los logros que el voluntario aún no tiene
     * pero ya cumplió las condiciones.
     */
    public function evaluarLogros(Voluntario $voluntario): array
    {
        $logrosObtenidos = [];
        $logros = Logro::where('activo', true)->get();
        $yaObtenidos = VoluntarioLogro::where('voluntario_id', $voluntario->id)
            ->pluck('logro_id')->toArray();

        // Stats del voluntario
        $totalParticipaciones = $voluntario->postulaciones()
            ->where('estado', 'ASISTIO')->count();

        $puntos = VoluntarioPuntos::where('voluntario_id', $voluntario->id)
            ->value('total_historico') ?? 0;

        $participacionesDificiles = $voluntario->postulaciones()
            ->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('dificultad', 'DIFICIL'))
            ->count();

        $participacionesMuyDificiles = $voluntario->postulaciones()
            ->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('dificultad', 'MUY_DIFICIL'))
            ->count();

        $participacionesUrgentes = $voluntario->postulaciones()
            ->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('urgente', true))
            ->count();

        foreach ($logros as $logro) {
            if (in_array($logro->id, $yaObtenidos)) continue;

            $cumple = match ($logro->tipo) {
                'participaciones' => $totalParticipaciones >= $logro->umbral,
                'puntos'          => $puntos >= $logro->umbral,
                'dificultad'      => match ($logro->codigo) {
                    'VALIENTE' => $participacionesDificiles >= $logro->umbral,
                    'HEROE'    => $participacionesMuyDificiles >= $logro->umbral,
                    default    => false,
                },
                'urgente'         => $participacionesUrgentes >= $logro->umbral,
                default           => false,
            };

            if ($cumple) {
                VoluntarioLogro::create([
                    'voluntario_id'   => $voluntario->id,
                    'logro_id'        => $logro->id,
                    'fecha_obtencion' => now(),
                ]);
                $logrosObtenidos[] = $logro;
            }
        }

        return $logrosObtenidos;
    }

    /**
     * Retorna el saldo y las últimas N transacciones del voluntario.
     */
    public function resumenPuntos(Voluntario $voluntario, int $limit = 10): array
    {
        $saldo = VoluntarioPuntos::firstOrCreate(
            ['voluntario_id' => $voluntario->id],
            ['saldo' => 0, 'total_historico' => 0]
        );

        $transacciones = TransaccionPuntos::where('voluntario_id', $voluntario->id)
            ->orderByDesc('fecha')
            ->limit($limit)
            ->get();

        return [
            'saldo'            => $saldo->saldo,
            'total_historico'  => $saldo->total_historico,
            'transacciones'    => $transacciones,
        ];
    }

    /**
     * Retorna los logros obtenidos y los pendientes con progreso.
     */
    public function resumenLogros(Voluntario $voluntario): array
    {
        $obtenidos = VoluntarioLogro::where('voluntario_id', $voluntario->id)
            ->with('logro')
            ->orderByDesc('fecha_obtencion')
            ->get();

        $idsObtenidos = $obtenidos->pluck('logro_id')->toArray();

        // Stats para calcular progreso
        $totalPart   = $voluntario->postulaciones()->where('estado', 'ASISTIO')->count();
        $totalPuntos = VoluntarioPuntos::where('voluntario_id', $voluntario->id)->value('total_historico') ?? 0;
        $partDificil = $voluntario->postulaciones()->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('dificultad', 'DIFICIL'))->count();
        $partMuyDif  = $voluntario->postulaciones()->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('dificultad', 'MUY_DIFICIL'))->count();
        $partUrgente = $voluntario->postulaciones()->where('estado', 'ASISTIO')
            ->whereHas('publicacion', fn ($q) => $q->where('urgente', true))->count();

        $pendientes = Logro::where('activo', true)
            ->whereNotIn('id', $idsObtenidos)
            ->get()
            ->map(function (Logro $logro) use ($totalPart, $totalPuntos, $partDificil, $partMuyDif, $partUrgente) {
                $progreso = match ($logro->tipo) {
                    'participaciones' => $totalPart,
                    'puntos'          => $totalPuntos,
                    'dificultad'      => $logro->codigo === 'VALIENTE' ? $partDificil : $partMuyDif,
                    'urgente'         => $partUrgente,
                    default           => 0,
                };
                return [
                    'id'          => $logro->id,
                    'codigo'      => $logro->codigo,
                    'nombre'      => $logro->nombre,
                    'descripcion' => $logro->descripcion,
                    'icono'       => $logro->icono,
                    'progreso'    => $progreso,
                    'umbral'      => $logro->umbral,
                    'porcentaje'  => $logro->umbral > 0 ? min(100, round($progreso / $logro->umbral * 100)) : 0,
                ];
            });

        return [
            'obtenidos'  => $obtenidos->map(fn ($vl) => [
                'id'              => $vl->logro->id,
                'codigo'          => $vl->logro->codigo,
                'nombre'          => $vl->logro->nombre,
                'descripcion'     => $vl->logro->descripcion,
                'icono'           => $vl->logro->icono,
                'fecha_obtencion' => $vl->fecha_obtencion,
            ]),
            'pendientes' => $pendientes,
        ];
    }

    /**
     * Ranking global: Top N + posición del voluntario actual.
     */
    public function ranking(int $top = 10, ?string $voluntarioId = null): array
    {
        $lista = DB::table('voluntario_puntos as vp')
            ->join('voluntarios as v', 'v.id', '=', 'vp.voluntario_id')
            ->join('usuarios as u', 'u.id', '=', 'v.usuario_id')
            ->leftJoin('municipios as m', 'm.id', '=', 'v.municipio_id')
            ->select([
                'vp.voluntario_id',
                'u.nombre',
                'm.nombre as municipio',
                'vp.saldo as puntos',
                'vp.total_historico',
                DB::raw("(SELECT COUNT(*) FROM postulaciones p WHERE p.voluntario_id = vp.voluntario_id AND p.estado = 'ASISTIO') as participaciones"),
            ])
            ->where('vp.total_historico', '>', 0)
            ->orderByDesc('vp.total_historico')
            ->orderByDesc('participaciones')
            ->get();

        // Asignar posiciones
        $ranking = $lista->map(function ($row, $idx) {
            return [
                'posicion'       => $idx + 1,
                'voluntario_id'  => $row->voluntario_id,
                'nombre'         => $row->nombre,
                'municipio'      => $row->municipio,
                'puntos'         => $row->total_historico,
                'participaciones'=> (int) $row->participaciones,
            ];
        });

        $topLista = $ranking->take($top)->values();

        // Posición del voluntario actual
        $miPosicion = null;
        if ($voluntarioId) {
            $miPosicion = $ranking->firstWhere('voluntario_id', $voluntarioId);
        }

        return [
            'top'         => $topLista,
            'mi_posicion' => $miPosicion,
            'total'       => $ranking->count(),
        ];
    }
}

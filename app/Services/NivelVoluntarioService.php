<?php

namespace App\Services;

class NivelVoluntarioService
{
    /** Niveles de gamificación basados en puntos históricos */
    private const NIVELES = [
        ['codigo' => 'BRONCE',   'nombre' => 'Bronce',   'min' => 0,    'color' => '#cd7f32'],
        ['codigo' => 'PLATA',    'nombre' => 'Plata',    'min' => 1000, 'color' => '#94a3b8'],
        ['codigo' => 'ORO',      'nombre' => 'Oro',      'min' => 2500, 'color' => '#eab308'],
        ['codigo' => 'PLATINO',  'nombre' => 'Platino',  'min' => 5000, 'color' => '#8b5cf6'],
        ['codigo' => 'DIAMANTE', 'nombre' => 'Diamante', 'min' => 10000, 'color' => '#06b6d4'],
    ];

    public function nivelActual(int $puntos): array
    {
        $actual = self::NIVELES[0];
        foreach (self::NIVELES as $nivel) {
            if ($puntos >= $nivel['min']) {
                $actual = $nivel;
            }
        }
        return $actual;
    }

    public function siguienteNivel(int $puntos): ?array
    {
        foreach (self::NIVELES as $i => $nivel) {
            if ($puntos < $nivel['min']) {
                return $nivel;
            }
        }
        return null;
    }

    public function progresoNivel(int $puntos): array
    {
        $actual    = $this->nivelActual($puntos);
        $siguiente = $this->siguienteNivel($puntos);

        if (!$siguiente) {
            return [
                'nivel_actual'    => $actual,
                'nivel_siguiente' => null,
                'puntos_actuales' => $puntos,
                'puntos_faltan'   => 0,
                'umbral_actual'   => $actual['min'],
                'umbral_siguiente'=> null,
                'porcentaje'      => 100,
            ];
        }

        $rango     = $siguiente['min'] - $actual['min'];
        $progreso  = $puntos - $actual['min'];
        $porcentaje = $rango > 0 ? min(100, round($progreso / $rango * 100)) : 0;

        return [
            'nivel_actual'     => $actual,
            'nivel_siguiente'  => $siguiente,
            'puntos_actuales'  => $puntos,
            'puntos_faltan'    => max(0, $siguiente['min'] - $puntos),
            'umbral_actual'    => $actual['min'],
            'umbral_siguiente' => $siguiente['min'],
            'porcentaje'       => $porcentaje,
        ];
    }
}

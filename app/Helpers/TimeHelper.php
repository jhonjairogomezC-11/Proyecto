<?php

namespace App\Helpers;

use Carbon\Carbon;

class TimeHelper
{
    const TIMEZONE_COLOMBIA = 'America/Bogota';

    /**
     * Retorna el momento actual en UTC (para guardar en BD)
     */
    public static function nowUtc(): Carbon
    {
        return Carbon::now('UTC');
    }

    /**
     * Convierte un Carbon/string UTC a hora Colombia para mostrar
     */
    public static function toColombia($datetime): ?Carbon
    {
        if (!$datetime) return null;
        $carbon = $datetime instanceof Carbon ? $datetime : Carbon::parse($datetime, 'UTC');
        return $carbon->setTimezone(self::TIMEZONE_COLOMBIA);
    }

    /**
     * Formatea a string legible en hora Colombia
     */
    public static function formatColombia($datetime, string $format = 'd/m/Y H:i'): string
    {
        $converted = self::toColombia($datetime);
        return $converted ? $converted->format($format) : '';
    }
}

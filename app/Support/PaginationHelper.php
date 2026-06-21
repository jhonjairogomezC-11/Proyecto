<?php

namespace App\Support;

use Illuminate\Http\Request;

class PaginationHelper
{
    /**
     * Resuelve per_page desde query con default y tope máximo.
     */
    public static function perPage(Request $request, int $default = 15, int $max = 50): int
    {
        $perPage = (int) $request->get('per_page', $default);

        return max(1, min($max, $perPage ?: $default));
    }
}

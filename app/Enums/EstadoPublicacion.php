<?php

namespace App\Enums;

enum EstadoPublicacion: string
{
    case BORRADOR   = 'BORRADOR';
    case PUBLICADA  = 'PUBLICADA';
    case CERRADA    = 'CERRADA';
    case CANCELADA  = 'CANCELADA';
    case COMPLETADA = 'COMPLETADA';
    case FINALIZADA = 'FINALIZADA';
}

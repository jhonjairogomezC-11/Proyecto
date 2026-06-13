<?php

namespace App\Enums;

enum EstadoReporte: string
{
    case PENDIENTE   = 'PENDIENTE';
    case EN_REVISION = 'EN_REVISION';
    case RESUELTO    = 'RESUELTO';
    case DESESTIMADO = 'DESESTIMADO';
}

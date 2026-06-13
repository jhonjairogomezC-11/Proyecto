<?php

namespace App\Enums;

enum EstadoVerificacion: string
{
    case PENDIENTE  = 'PENDIENTE';
    case APROBADA   = 'APROBADA';
    case RECHAZADA  = 'RECHAZADA';
    case SUSPENDIDA = 'SUSPENDIDA';
}

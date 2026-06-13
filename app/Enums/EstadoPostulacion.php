<?php

namespace App\Enums;

enum EstadoPostulacion: string
{
    case PENDIENTE   = 'PENDIENTE';
    case ACEPTADO    = 'ACEPTADO';
    case RECHAZADO   = 'RECHAZADO';
    case RETIRADO    = 'RETIRADO';
    case ASISTIO     = 'ASISTIO';
    case NO_ASISTIO  = 'NO_ASISTIO';
}

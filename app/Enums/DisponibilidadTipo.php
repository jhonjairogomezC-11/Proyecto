<?php

namespace App\Enums;

enum DisponibilidadTipo: string
{
    case ENTRE_SEMANA    = 'ENTRE_SEMANA';
    case FINES_DE_SEMANA = 'FINES_DE_SEMANA';
    case FLEXIBLE        = 'FLEXIBLE';
}

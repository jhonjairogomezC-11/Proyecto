<?php

namespace App\Enums;

enum EstadoUsuario: string
{
    case ACTIVO    = 'ACTIVO';
    case BLOQUEADO = 'BLOQUEADO';
    case SUSPENDIDO = 'SUSPENDIDO';
}

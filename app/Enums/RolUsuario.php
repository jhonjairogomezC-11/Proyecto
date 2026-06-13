<?php

namespace App\Enums;

enum RolUsuario: string
{
    case VOLUNTARIO = 'VOLUNTARIO';
    case FUNDACION  = 'FUNDACION';
    case ADMIN      = 'ADMIN';
}

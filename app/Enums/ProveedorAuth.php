<?php

namespace App\Enums;

enum ProveedorAuth: string
{
    case LOCAL  = 'LOCAL';
    case GOOGLE = 'GOOGLE';
}

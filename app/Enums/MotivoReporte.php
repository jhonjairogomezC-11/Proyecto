<?php

namespace App\Enums;

enum MotivoReporte: string
{
    case INFORMACION_FALSA     = 'INFORMACION_FALSA';
    case CONTENIDO_INAPROPIADO = 'CONTENIDO_INAPROPIADO';
    case ACTIVIDAD_SOSPECHOSA  = 'ACTIVIDAD_SOSPECHOSA';
    case PERFIL_SOSPECHOSO     = 'PERFIL_SOSPECHOSO';
    case OTRO                  = 'OTRO';
}

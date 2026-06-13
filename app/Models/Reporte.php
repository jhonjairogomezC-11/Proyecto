<?php

namespace App\Models;

use App\Enums\EstadoReporte;
use App\Enums\MotivoReporte;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Reporte extends Model
{
    use HasUuid;

    protected $table        = 'reportes';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'reportante_id', 'objeto_tipo', 'objeto_id', 'motivo', 'detalle',
        'estado', 'admin_asignado_id', 'resolucion',
    ];

    protected $casts = [
        'motivo'           => MotivoReporte::class,
        'estado'           => EstadoReporte::class,
        'fecha_asignacion' => 'datetime',
        'fecha_resolucion' => 'datetime',
        'fecha_creacion'   => 'datetime',
    ];

    public function reportante()
    {
        return $this->belongsTo(Usuario::class, 'reportante_id');
    }

    public function adminAsignado()
    {
        return $this->belongsTo(AdminPerfil::class, 'admin_asignado_id');
    }
}

<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class HistorialEstadoFundacion extends Model
{
    use HasUuid;

    protected $table      = 'historial_estados_fundacion';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'fundacion_id', 'estado_anterior', 'estado_nuevo', 'motivo', 'admin_id',
    ];

    protected $casts = [
        'fecha' => 'datetime',
    ];

    public function fundacion()
    {
        return $this->belongsTo(Fundacion::class, 'fundacion_id');
    }

    public function admin()
    {
        return $this->belongsTo(AdminPerfil::class, 'admin_id');
    }
}

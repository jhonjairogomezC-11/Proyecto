<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class HistorialEstadoVoluntario extends Model
{
    use HasUuid;

    protected $table      = 'historial_estados_voluntario';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'usuario_id', 'estado_anterior', 'estado_nuevo', 'motivo', 'duracion_dias', 'admin_id',
    ];

    protected $casts = [
        'fecha'         => 'datetime',
        'duracion_dias' => 'integer',
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }

    public function admin()
    {
        return $this->belongsTo(AdminPerfil::class, 'admin_id');
    }
}

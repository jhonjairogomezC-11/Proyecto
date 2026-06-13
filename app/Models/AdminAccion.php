<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class AdminAccion extends Model
{
    use HasUuid;

    protected $table        = 'admin_acciones';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'admin_id', 'tipo', 'objeto_tipo', 'objeto_id',
        'objeto_descripcion', 'detalle_anterior', 'detalle_nuevo', 'motivo',
    ];

    protected $casts = [
        'detalle_anterior' => 'array',
        'detalle_nuevo'    => 'array',
        'fecha_accion'     => 'datetime',
    ];

    public function admin()
    {
        return $this->belongsTo(AdminPerfil::class, 'admin_id');
    }
}

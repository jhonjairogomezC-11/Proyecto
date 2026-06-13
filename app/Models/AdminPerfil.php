<?php

namespace App\Models;

use App\Enums\NivelAdmin;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class AdminPerfil extends Model
{
    use HasUuid;

    protected $table        = 'admin_perfiles';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'usuario_id', 'nivel', 'permisos', 'creado_por', 'activo', 'cargo', 'notas_internas',
    ];

    protected $casts = [
        'nivel'               => NivelAdmin::class,
        'permisos'            => 'array',
        'activo'              => 'boolean',
        'fecha_creacion'      => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }

    public function creadoPor()
    {
        return $this->belongsTo(AdminPerfil::class, 'creado_por');
    }

    public function acciones()
    {
        return $this->hasMany(AdminAccion::class, 'admin_id');
    }
}

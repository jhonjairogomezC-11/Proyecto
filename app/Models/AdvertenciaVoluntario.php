<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class AdvertenciaVoluntario extends Model
{
    use HasUuid;

    protected $table      = 'advertencias_voluntario';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'voluntario_id', 'admin_id', 'motivo', 'activa',
    ];

    protected $casts = [
        'activa' => 'boolean',
        'fecha'  => 'datetime',
    ];

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }

    public function admin()
    {
        return $this->belongsTo(AdminPerfil::class, 'admin_id');
    }
}

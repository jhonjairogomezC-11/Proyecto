<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class TransaccionPuntos extends Model
{
    use HasUuid;

    protected $table      = 'transacciones_puntos';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'voluntario_id', 'postulacion_id', 'puntos_base',
        'puntos_bonus', 'puntos_total', 'motivo',
    ];

    protected $casts = [
        'puntos_base'   => 'integer',
        'puntos_bonus'  => 'integer',
        'puntos_total'  => 'integer',
        'fecha'         => 'datetime',
    ];

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }

    public function postulacion()
    {
        return $this->belongsTo(Postulacion::class, 'postulacion_id');
    }
}

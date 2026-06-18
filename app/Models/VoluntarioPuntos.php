<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VoluntarioPuntos extends Model
{
    protected $table      = 'voluntario_puntos';
    protected $primaryKey = 'voluntario_id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = ['voluntario_id', 'saldo', 'total_historico'];

    protected $casts = [
        'saldo'             => 'integer',
        'total_historico'   => 'integer',
        'fecha_actualizacion' => 'datetime',
    ];

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }
}

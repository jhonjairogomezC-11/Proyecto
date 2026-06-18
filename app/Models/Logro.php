<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Logro extends Model
{
    protected $table    = 'logros';
    public    $timestamps = false;

    protected $fillable = ['codigo', 'nombre', 'descripcion', 'icono', 'tipo', 'umbral', 'activo'];

    protected $casts = [
        'activo'  => 'boolean',
        'umbral'  => 'integer',
    ];

    public function voluntarios()
    {
        return $this->belongsToMany(Voluntario::class, 'voluntario_logros', 'logro_id', 'voluntario_id')
                    ->withPivot('fecha_obtencion');
    }
}

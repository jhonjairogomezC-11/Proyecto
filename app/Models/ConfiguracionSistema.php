<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ConfiguracionSistema extends Model
{
    protected $table      = 'configuracion_sistema';
    protected $primaryKey = 'clave';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'clave', 'valor_texto', 'valor_int', 'valor_decimal', 'valor_bool',
        'descripcion', 'modulo',
    ];

    protected $casts = [
        'valor_bool'          => 'boolean',
        'valor_decimal'       => 'float',
        'fecha_actualizacion' => 'datetime',
    ];
}

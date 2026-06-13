<?php

namespace App\Models;

use App\Enums\TipoNotificacion;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class Notificacion extends Model
{
    use HasUuid;

    protected $table        = 'notificaciones';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'usuario_id', 'tipo', 'mensaje', 'objeto_tipo', 'objeto_id', 'leida',
    ];

    protected $casts = [
        'tipo'           => TipoNotificacion::class,
        'leida'          => 'boolean',
        'fecha_lectura'  => 'datetime',
        'fecha_creacion' => 'datetime',
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
}

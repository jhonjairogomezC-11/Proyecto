<?php

namespace App\Models;

use App\Enums\EstadoPostulacion;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Postulacion extends Model
{
    use HasFactory, HasUuid;

    protected $table        = 'postulaciones';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'publicacion_id', 'voluntario_id', 'estado', 'mensaje_voluntario',
        'motivo_rechazo', 'calificacion', 'comentario_fundacion',
    ];

    protected $casts = [
        'estado'              => EstadoPostulacion::class,
        'fecha_respuesta'     => 'datetime',
        'fecha_confirmacion'  => 'datetime',
        'fecha_postulacion'   => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function publicacion()
    {
        return $this->belongsTo(Publicacion::class, 'publicacion_id');
    }

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }
}

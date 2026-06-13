<?php

namespace App\Models;

use App\Enums\EstadoPublicacion;
use App\Enums\ModalidadTipo;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Publicacion extends Model
{
    use HasFactory, HasUuid;

    protected $table        = 'publicaciones';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'fundacion_id', 'titulo', 'descripcion', 'categoria_id', 'modalidad',
        'municipio_id', 'direccion_exacta', 'enlace_virtual', 'fecha_inicio', 'fecha_fin',
        'hora_inicio', 'hora_fin', 'cupo_maximo', 'edad_minima', 'edad_maxima',
        'requisitos_adicionales', 'imagen', 'contacto_nombre', 'contacto_email',
        'contacto_telefono', 'estado', 'oculta_por_admin', 'motivo_ocultamiento',
    ];

    protected $casts = [
        'modalidad'           => ModalidadTipo::class,
        'estado'              => EstadoPublicacion::class,
        'fecha_inicio'        => 'date',
        'fecha_fin'           => 'date',
        'oculta_por_admin'    => 'boolean',
        'fecha_publicacion'   => 'datetime',
        'fecha_ocultamiento'  => 'datetime',
        'fecha_creacion'      => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function fundacion()
    {
        return $this->belongsTo(Fundacion::class, 'fundacion_id');
    }

    public function categoria()
    {
        return $this->belongsTo(AreaImpacto::class, 'categoria_id');
    }

    public function municipio()
    {
        return $this->belongsTo(Municipio::class, 'municipio_id');
    }

    public function habilidades()
    {
        return $this->belongsToMany(Habilidad::class, 'publicacion_habilidades', 'publicacion_id', 'habilidad_id');
    }

    public function postulaciones()
    {
        return $this->hasMany(Postulacion::class, 'publicacion_id');
    }
}

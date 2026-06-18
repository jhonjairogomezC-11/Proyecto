<?php

namespace App\Models;

use App\Enums\EstadoVerificacion;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Fundacion extends Model
{
    use HasFactory, HasUuid;

    protected $table        = 'fundaciones';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'usuario_id', 'nombre', 'nit', 'representante_legal', 'correo_institucional',
        'telefono', 'direccion', 'municipio_id', 'pagina_web', 'descripcion',
        'documento_legal', 'logo', 'estado_verificacion', 'motivo_rechazo',
    ];

    protected $casts = [
        'estado_verificacion' => EstadoVerificacion::class,
        'fecha_verificacion'  => 'datetime',
        'fecha_creacion'      => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }

    public function municipio()
    {
        return $this->belongsTo(Municipio::class, 'municipio_id');
    }

    public function areas()
    {
        return $this->belongsToMany(AreaImpacto::class, 'fundacion_areas', 'fundacion_id', 'area_id');
    }

    public function publicaciones()
    {
        return $this->hasMany(Publicacion::class, 'fundacion_id');
    }

    public function documentos()
    {
        return $this->hasMany(FundacionDocumento::class, 'fundacion_id');
    }

    public function historialEstados()
    {
        return $this->hasMany(HistorialEstadoFundacion::class, 'fundacion_id')
                    ->orderByDesc('fecha');
    }
}

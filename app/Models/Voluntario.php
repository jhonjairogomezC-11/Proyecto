<?php

namespace App\Models;

use App\Enums\DisponibilidadTipo;
use App\Enums\GeneroTipo;
use App\Enums\TipoDocumento;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Voluntario extends Model
{
    use HasFactory, HasUuid;

    protected $table        = 'voluntarios';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'usuario_id', 'tipo_documento', 'numero_documento', 'fecha_nacimiento',
        'genero', 'municipio_id', 'disponibilidad', 'experiencia', 'foto_perfil',
    ];

    protected $casts = [
        'tipo_documento'      => TipoDocumento::class,
        'genero'              => GeneroTipo::class,
        'disponibilidad'      => DisponibilidadTipo::class,
        'fecha_nacimiento'    => 'date',
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

    public function habilidades()
    {
        return $this->belongsToMany(Habilidad::class, 'voluntario_habilidades', 'voluntario_id', 'habilidad_id');
    }

    public function intereses()
    {
        return $this->belongsToMany(Interes::class, 'voluntario_intereses', 'voluntario_id', 'interes_id');
    }

    public function postulaciones()
    {
        return $this->hasMany(Postulacion::class, 'voluntario_id');
    }

    public function advertencias()
    {
        return $this->hasMany(AdvertenciaVoluntario::class, 'voluntario_id');
    }

    public function historialEstados()
    {
        return $this->hasMany(HistorialEstadoVoluntario::class, 'usuario_id', 'usuario_id')
                    ->orderByDesc('fecha');
    }

    public function puntos()
    {
        return $this->hasOne(VoluntarioPuntos::class, 'voluntario_id');
    }

    public function transaccionesPuntos()
    {
        return $this->hasMany(TransaccionPuntos::class, 'voluntario_id')
                    ->orderByDesc('fecha');
    }

    public function logros()
    {
        return $this->belongsToMany(Logro::class, 'voluntario_logros', 'voluntario_id', 'logro_id')
                    ->withPivot('fecha_obtencion')
                    ->orderByPivot('fecha_obtencion', 'desc');
    }

    public function favoritos()
    {
        return $this->hasMany(VoluntarioFavorito::class, 'voluntario_id');
    }

    public function calificacionPromedio(): float
    {
        return round(
            $this->postulaciones()
                 ->whereNotNull('calificacion')
                 ->avg('calificacion') ?? 0,
            1
        );
    }
}

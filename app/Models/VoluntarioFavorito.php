<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class VoluntarioFavorito extends Model
{
    use HasUuid;

    protected $table      = 'voluntario_favoritos';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = ['voluntario_id', 'tipo', 'publicacion_id', 'fundacion_id'];

    protected $casts = [
        'fecha_creacion' => 'datetime',
    ];

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }

    public function publicacion()
    {
        return $this->belongsTo(Publicacion::class, 'publicacion_id');
    }

    public function fundacion()
    {
        return $this->belongsTo(Fundacion::class, 'fundacion_id');
    }
}

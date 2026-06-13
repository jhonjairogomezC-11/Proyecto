<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Habilidad extends Model
{
    protected $table  = 'habilidades';
    public    $timestamps = false;
    protected $fillable = ['nombre'];

    public function voluntarios()
    {
        return $this->belongsToMany(Voluntario::class, 'voluntario_habilidades', 'habilidad_id', 'voluntario_id');
    }

    public function publicaciones()
    {
        return $this->belongsToMany(Publicacion::class, 'publicacion_habilidades', 'habilidad_id', 'publicacion_id');
    }
}

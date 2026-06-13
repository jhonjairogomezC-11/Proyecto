<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AreaImpacto extends Model
{
    protected $table  = 'areas_impacto';
    public    $timestamps = false;
    protected $fillable = ['nombre'];

    public function fundaciones()
    {
        return $this->belongsToMany(Fundacion::class, 'fundacion_areas', 'area_id', 'fundacion_id');
    }

    public function publicaciones()
    {
        return $this->hasMany(Publicacion::class, 'categoria_id');
    }
}

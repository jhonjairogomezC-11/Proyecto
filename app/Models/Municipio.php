<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Municipio extends Model
{
    protected $table = 'municipios';
    public    $timestamps = false;
    protected $fillable   = ['nombre', 'departamento_id'];

    public function departamento()
    {
        return $this->belongsTo(Departamento::class, 'departamento_id');
    }

    public function voluntarios()
    {
        return $this->hasMany(Voluntario::class, 'municipio_id');
    }

    public function fundaciones()
    {
        return $this->hasMany(Fundacion::class, 'municipio_id');
    }

    public function publicaciones()
    {
        return $this->hasMany(Publicacion::class, 'municipio_id');
    }
}

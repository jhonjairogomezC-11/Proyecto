<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Interes extends Model
{
    protected $table  = 'intereses';
    public    $timestamps = false;
    protected $fillable = ['nombre'];

    public function voluntarios()
    {
        return $this->belongsToMany(Voluntario::class, 'voluntario_intereses', 'interes_id', 'voluntario_id');
    }
}

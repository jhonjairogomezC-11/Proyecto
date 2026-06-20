<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class PublicacionImagen extends Model
{
    use HasUuid;

    protected $table      = 'publicacion_imagenes';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = ['publicacion_id', 'ruta', 'orden'];

    protected $casts = [
        'fecha_creacion' => 'datetime',
    ];

    public function publicacion()
    {
        return $this->belongsTo(Publicacion::class, 'publicacion_id');
    }

    public function getUrlAttribute(): string
    {
        return '/storage/' . ltrim($this->ruta, '/');
    }
}

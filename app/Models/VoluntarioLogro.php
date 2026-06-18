<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class VoluntarioLogro extends Model
{
    use HasUuid;

    protected $table    = 'voluntario_logros';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType  = 'string';
    public    $timestamps = false;

    protected $fillable = ['voluntario_id', 'logro_id', 'fecha_obtencion'];

    protected $casts = [
        'fecha_obtencion' => 'datetime',
    ];

    public function logro()
    {
        return $this->belongsTo(Logro::class, 'logro_id');
    }

    public function voluntario()
    {
        return $this->belongsTo(Voluntario::class, 'voluntario_id');
    }
}

<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class FundacionDocumento extends Model
{
    use HasUuid;

    protected $table      = 'fundacion_documentos';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'fundacion_id', 'tipo_documento', 'nombre_original', 'ruta_archivo', 'validado',
    ];

    protected $casts = [
        'validado'      => 'boolean',
        'fecha_subida'  => 'datetime',
    ];

    public function fundacion()
    {
        return $this->belongsTo(Fundacion::class, 'fundacion_id');
    }
}

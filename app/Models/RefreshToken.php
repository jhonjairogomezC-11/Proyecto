<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class RefreshToken extends Model
{
    use HasUuid;

    protected $table      = 'refresh_tokens';
    protected $primaryKey = 'id';
    public    $incrementing = false;
    protected $keyType    = 'string';
    public    $timestamps = false;

    protected $fillable = [
        'usuario_id', 'token', 'expiracion', 'usado', 'ip_solicitud', 'user_agent',
    ];

    protected $casts = [
        'usado'          => 'boolean',
        'expiracion'     => 'datetime',
        'fecha_uso'      => 'datetime',
        'fecha_creacion' => 'datetime',
    ];

    public function usuario()
    {
        return $this->belongsTo(Usuario::class, 'usuario_id');
    }
}

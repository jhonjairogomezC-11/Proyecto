<?php

namespace App\Models;

use App\Enums\EstadoUsuario;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Usuario extends Authenticatable
{
    use HasApiTokens, HasFactory, HasUuid, Notifiable;

    protected $table        = 'usuarios';
    protected $primaryKey   = 'id';
    public    $incrementing = false;
    protected $keyType      = 'string';
    public    $timestamps   = false;

    protected $fillable = [
        'nombre', 'email', 'password_hash', 'provider', 'provider_id',
        'telefono', 'rol', 'estado', 'email_verificado',
        'fecha_registro', 'fecha_actualizacion',
    ];

    protected $hidden = ['password_hash'];

    protected $casts = [
        'rol'                 => RolUsuario::class,
        'estado'              => EstadoUsuario::class,
        'provider'            => ProveedorAuth::class,
        'email_verificado'    => 'boolean',
        'fecha_registro'      => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function getAuthPassword(): string
    {
        return $this->password_hash ?? '';
    }

    public function voluntario()
    {
        return $this->hasOne(Voluntario::class, 'usuario_id');
    }

    public function fundacion()
    {
        return $this->hasOne(Fundacion::class, 'usuario_id');
    }

    public function adminPerfil()
    {
        return $this->hasOne(AdminPerfil::class, 'usuario_id');
    }

    public function notificaciones()
    {
        return $this->hasMany(Notificacion::class, 'usuario_id');
    }

    public function reportes()
    {
        return $this->hasMany(Reporte::class, 'reportante_id');
    }
}

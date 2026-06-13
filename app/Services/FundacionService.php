<?php

namespace App\Services;

use App\Enums\EstadoVerificacion;
use App\Enums\EstadoUsuario;
use App\Models\AdminAccion;
use App\Models\AdminPerfil;
use App\Models\Fundacion;
use App\Models\Notificacion;
use Illuminate\Validation\ValidationException;

class FundacionService
{
    public function gestionar(AdminPerfil $admin, Fundacion $fundacion, string $estado, ?string $motivo): Fundacion
    {
        $nuevoEstado = EstadoVerificacion::from($estado);

        if (in_array($nuevoEstado, [EstadoVerificacion::RECHAZADA, EstadoVerificacion::SUSPENDIDA]) && !$motivo) {
            throw ValidationException::withMessages(['motivo' => 'El motivo es obligatorio para rechazar o suspender.']);
        }

        $estadoAnterior = $fundacion->estado_verificacion;

        $fundacion->update([
            'estado_verificacion' => $nuevoEstado,
            'fecha_verificacion'  => now(),
            'motivo_rechazo'      => in_array($nuevoEstado, [EstadoVerificacion::RECHAZADA, EstadoVerificacion::SUSPENDIDA])
                ? $motivo : null,
        ]);

        $estadoUsuario = in_array($nuevoEstado, [EstadoVerificacion::RECHAZADA, EstadoVerificacion::SUSPENDIDA])
            ? EstadoUsuario::SUSPENDIDO
            : EstadoUsuario::ACTIVO;

        $fundacion->usuario()->update(['estado' => $estadoUsuario]);

        $mensaje = match ($nuevoEstado) {
            EstadoVerificacion::APROBADA   => "Tu fundación \"{$fundacion->nombre}\" fue aprobada. Ya puedes publicar actividades.",
            EstadoVerificacion::RECHAZADA  => "Tu fundación \"{$fundacion->nombre}\" fue rechazada. Motivo: {$motivo}",
            EstadoVerificacion::SUSPENDIDA => "Tu fundación \"{$fundacion->nombre}\" fue suspendida. Motivo: {$motivo}",
            default                        => "El estado de tu fundación \"{$fundacion->nombre}\" fue actualizado.",
        };

        $tipoNotif = match ($nuevoEstado) {
            EstadoVerificacion::APROBADA   => 'FUNDACION_APROBADA',
            EstadoVerificacion::RECHAZADA  => 'FUNDACION_RECHAZADA',
            EstadoVerificacion::SUSPENDIDA => 'FUNDACION_SUSPENDIDA',
            default                        => 'FUNDACION_REACTIVADA',
        };

        Notificacion::create([
            'usuario_id'  => $fundacion->usuario_id,
            'tipo'        => $tipoNotif,
            'mensaje'     => $mensaje,
            'objeto_tipo' => 'FUNDACION',
            'objeto_id'   => $fundacion->id,
        ]);

        $tipoAccion = match ($nuevoEstado) {
            EstadoVerificacion::APROBADA   => 'FUNDACION_APROBADA',
            EstadoVerificacion::RECHAZADA  => 'FUNDACION_RECHAZADA',
            EstadoVerificacion::SUSPENDIDA => 'FUNDACION_SUSPENDIDA',
            default                        => 'FUNDACION_REACTIVADA',
        };

        AdminAccion::create([
            'admin_id'           => $admin->id,
            'tipo'               => $tipoAccion,
            'objeto_tipo'        => 'FUNDACION',
            'objeto_id'          => $fundacion->id,
            'objeto_descripcion' => $fundacion->nombre,
            'detalle_anterior'   => ['estado_verificacion' => $estadoAnterior],
            'detalle_nuevo'      => ['estado_verificacion' => $nuevoEstado],
            'motivo'             => $motivo,
        ]);

        return $fundacion->fresh();
    }
}

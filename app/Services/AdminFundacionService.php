<?php

namespace App\Services;

use App\Enums\EstadoUsuario;
use App\Enums\EstadoVerificacion;
use App\Models\AdminAccion;
use App\Models\AdminPerfil;
use App\Models\Fundacion;
use App\Models\FundacionDocumento;
use App\Models\HistorialEstadoFundacion;
use App\Models\Notificacion;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;

class AdminFundacionService
{
    /** Aprobar una fundación */
    public function aprobar(AdminPerfil $admin, Fundacion $fundacion): Fundacion
    {
        return $this->cambiarEstado($admin, $fundacion, EstadoVerificacion::APROBADA, null);
    }

    /** Rechazar una fundación (motivo obligatorio) */
    public function rechazar(AdminPerfil $admin, Fundacion $fundacion, string $motivo): Fundacion
    {
        if (strlen(trim($motivo)) < 10) {
            throw ValidationException::withMessages([
                'motivo' => 'El motivo debe tener al menos 10 caracteres.',
            ]);
        }
        return $this->cambiarEstado($admin, $fundacion, EstadoVerificacion::RECHAZADA, $motivo);
    }

    /** Suspender una fundación (motivo obligatorio) */
    public function suspender(AdminPerfil $admin, Fundacion $fundacion, string $motivo): Fundacion
    {
        if (!trim($motivo)) {
            throw ValidationException::withMessages(['motivo' => 'El motivo es obligatorio.']);
        }
        return $this->cambiarEstado($admin, $fundacion, EstadoVerificacion::SUSPENDIDA, $motivo);
    }

    /** Reactivar una fundación suspendida o rechazada */
    public function reactivar(AdminPerfil $admin, Fundacion $fundacion): Fundacion
    {
        if (!in_array($fundacion->estado_verificacion, [
            EstadoVerificacion::SUSPENDIDA,
            EstadoVerificacion::RECHAZADA,
        ])) {
            throw ValidationException::withMessages([
                'estado' => 'Solo se pueden reactivar fundaciones SUSPENDIDAS o RECHAZADAS.',
            ]);
        }
        return $this->cambiarEstado($admin, $fundacion, EstadoVerificacion::APROBADA, null);
    }

    /** Subir un documento de la fundación */
    public function subirDocumento(
        Fundacion $fundacion,
        string $tipoDocumento,
        \Illuminate\Http\UploadedFile $archivo
    ): FundacionDocumento {
        $tipos = ['camara_comercio', 'id_representante', 'certificado'];
        if (!in_array($tipoDocumento, $tipos)) {
            throw ValidationException::withMessages([
                'tipo_documento' => 'Tipo de documento inválido. Válidos: ' . implode(', ', $tipos),
            ]);
        }

        $ruta = $archivo->store("fundaciones/{$fundacion->id}/documentos", 'local');

        return FundacionDocumento::create([
            'fundacion_id'   => $fundacion->id,
            'tipo_documento' => $tipoDocumento,
            'nombre_original'=> $archivo->getClientOriginalName(),
            'ruta_archivo'   => $ruta,
            'validado'       => false,
        ]);
    }

    /** Listar documentos de una fundación con URL temporal */
    public function listarDocumentos(Fundacion $fundacion): array
    {
        return $fundacion->documentos->map(function (FundacionDocumento $doc) {
            return [
                'id'              => $doc->id,
                'tipo_documento'  => $doc->tipo_documento,
                'nombre_original' => $doc->nombre_original,
                'validado'        => $doc->validado,
                'fecha_subida'    => $doc->fecha_subida,
                'url'             => Storage::temporaryUrl($doc->ruta_archivo, now()->addMinutes(60)),
            ];
        })->toArray();
    }

    /** Obtener historial de estados de una fundación */
    public function historial(Fundacion $fundacion): \Illuminate\Database\Eloquent\Collection
    {
        return $fundacion->historialEstados()
            ->with('admin.usuario:id,nombre')
            ->get();
    }

    // ── Privado ───────────────────────────────────────────────

    private function cambiarEstado(
        AdminPerfil $admin,
        Fundacion $fundacion,
        EstadoVerificacion $nuevoEstado,
        ?string $motivo
    ): Fundacion {
        $estadoAnterior = $fundacion->estado_verificacion;

        // Actualizar fundación
        $fundacion->update([
            'estado_verificacion' => $nuevoEstado,
            'fecha_verificacion'  => now(),
            'motivo_rechazo'      => in_array($nuevoEstado, [
                EstadoVerificacion::RECHAZADA,
                EstadoVerificacion::SUSPENDIDA,
            ]) ? $motivo : null,
        ]);

        // Actualizar estado del usuario asociado
        $estadoUsuario = in_array($nuevoEstado, [
            EstadoVerificacion::RECHAZADA,
            EstadoVerificacion::SUSPENDIDA,
        ]) ? EstadoUsuario::SUSPENDIDO : EstadoUsuario::ACTIVO;

        $fundacion->usuario()->update(['estado' => $estadoUsuario]);

        // Registrar en historial
        HistorialEstadoFundacion::create([
            'fundacion_id'    => $fundacion->id,
            'estado_anterior' => $estadoAnterior instanceof \BackedEnum
                ? $estadoAnterior->value : $estadoAnterior,
            'estado_nuevo'    => $nuevoEstado->value,
            'motivo'          => $motivo,
            'admin_id'        => $admin->id,
        ]);

        // Notificar a la fundación
        $mensaje = match ($nuevoEstado) {
            EstadoVerificacion::APROBADA   => "Tu fundación \"{$fundacion->nombre}\" fue aprobada. Ya puedes publicar actividades.",
            EstadoVerificacion::RECHAZADA  => "Tu fundación \"{$fundacion->nombre}\" fue rechazada. Motivo: {$motivo}",
            EstadoVerificacion::SUSPENDIDA => "Tu fundación \"{$fundacion->nombre}\" fue suspendida. Motivo: {$motivo}",
            default                        => "El estado de tu fundación \"{$fundacion->nombre}\" fue actualizado a {$nuevoEstado->value}.",
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

        // Registrar acción admin para auditoría
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
            'detalle_anterior'   => ['estado_verificacion' => $estadoAnterior instanceof \BackedEnum
                ? $estadoAnterior->value : $estadoAnterior],
            'detalle_nuevo'      => ['estado_verificacion' => $nuevoEstado->value],
            'motivo'             => $motivo,
        ]);

        return $fundacion->fresh(['municipio.departamento', 'areas', 'usuario']);
    }
}

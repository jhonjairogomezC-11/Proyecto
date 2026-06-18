<?php

namespace App\Services;

use App\Enums\EstadoUsuario;
use App\Models\AdminAccion;
use App\Models\AdminPerfil;
use App\Models\AdvertenciaVoluntario;
use App\Models\HistorialEstadoVoluntario;
use App\Models\Notificacion;
use App\Models\Voluntario;
use Illuminate\Validation\ValidationException;

class AdminVoluntarioService
{
    /** Suspender un voluntario */
    public function suspender(
        AdminPerfil $admin,
        Voluntario $voluntario,
        string $motivo,
        ?int $duracionDias = null
    ): Voluntario {
        if (!trim($motivo)) {
            throw ValidationException::withMessages(['motivo' => 'El motivo es obligatorio.']);
        }

        return $this->cambiarEstado($admin, $voluntario, EstadoUsuario::SUSPENDIDO, $motivo, $duracionDias);
    }

    /** Bloquear un voluntario */
    public function bloquear(AdminPerfil $admin, Voluntario $voluntario, string $motivo): Voluntario
    {
        if (!trim($motivo)) {
            throw ValidationException::withMessages(['motivo' => 'El motivo es obligatorio.']);
        }

        return $this->cambiarEstado($admin, $voluntario, EstadoUsuario::BLOQUEADO, $motivo, null);
    }

    /** Reactivar un voluntario suspendido o bloqueado */
    public function reactivar(AdminPerfil $admin, Voluntario $voluntario): Voluntario
    {
        $estadoActual = $voluntario->usuario->estado;

        if ($estadoActual === EstadoUsuario::ACTIVO) {
            throw ValidationException::withMessages([
                'estado' => 'El voluntario ya está activo.',
            ]);
        }

        return $this->cambiarEstado($admin, $voluntario, EstadoUsuario::ACTIVO, 'Reactivación por administrador', null);
    }

    /** Emitir una advertencia */
    public function emitirAdvertencia(
        AdminPerfil $admin,
        Voluntario $voluntario,
        string $motivo
    ): array {
        if (!trim($motivo)) {
            throw ValidationException::withMessages(['motivo' => 'El motivo de la advertencia es obligatorio.']);
        }

        $advertencia = AdvertenciaVoluntario::create([
            'voluntario_id' => $voluntario->id,
            'admin_id'      => $admin->id,
            'motivo'        => $motivo,
            'activa'        => true,
        ]);

        $totalActivas = AdvertenciaVoluntario::where('voluntario_id', $voluntario->id)
            ->where('activa', true)
            ->count();

        // Notificar al voluntario
        Notificacion::create([
            'usuario_id'  => $voluntario->usuario_id,
            'tipo'        => 'RECORDATORIO_ACTIVIDAD',
            'mensaje'     => "Has recibido una advertencia del administrador: {$motivo}",
            'objeto_tipo' => 'VOLUNTARIO',
            'objeto_id'   => $voluntario->id,
        ]);

        AdminAccion::create([
            'admin_id'           => $admin->id,
            'tipo'               => 'USUARIO_EDITADO',
            'objeto_tipo'        => 'VOLUNTARIO',
            'objeto_id'          => $voluntario->id,
            'objeto_descripcion' => $voluntario->usuario->nombre ?? '',
            'motivo'             => "Advertencia emitida: {$motivo}",
        ]);

        return [
            'advertencia'      => $advertencia,
            'total_activas'    => $totalActivas,
        ];
    }

    /** Historial de participaciones y sanciones */
    public function historial(Voluntario $voluntario): array
    {
        $participaciones = $voluntario->postulaciones()
            ->with('publicacion:id,titulo,fecha_inicio,fecha_fin')
            ->whereIn('estado', ['ASISTIO', 'NO_ASISTIO', 'ACEPTADO', 'RECHAZADO', 'RETIRADO'])
            ->orderByDesc('fecha_postulacion')
            ->get()
            ->map(fn ($p) => [
                'tipo'           => 'PARTICIPACION',
                'fecha'          => $p->fecha_postulacion,
                'estado'         => $p->estado,
                'publicacion'    => $p->publicacion?->titulo,
                'calificacion'   => $p->calificacion,
            ]);

        $sanciones = HistorialEstadoVoluntario::where('usuario_id', $voluntario->usuario_id)
            ->with('admin.usuario:id,nombre')
            ->orderByDesc('fecha')
            ->get()
            ->map(fn ($h) => [
                'tipo'            => 'SANCION',
                'fecha'           => $h->fecha,
                'estado_anterior' => $h->estado_anterior,
                'estado_nuevo'    => $h->estado_nuevo,
                'motivo'          => $h->motivo,
                'admin'           => $h->admin?->usuario?->nombre,
                'duracion_dias'   => $h->duracion_dias,
            ]);

        $advertencias = $voluntario->advertencias()
            ->with('admin.usuario:id,nombre')
            ->orderByDesc('fecha')
            ->get()
            ->map(fn ($a) => [
                'tipo'   => 'ADVERTENCIA',
                'fecha'  => $a->fecha,
                'motivo' => $a->motivo,
                'activa' => $a->activa,
                'admin'  => $a->admin?->usuario?->nombre,
            ]);

        return collect($participaciones)
            ->concat($sanciones)
            ->concat($advertencias)
            ->sortByDesc('fecha')
            ->values()
            ->toArray();
    }

    /** Perfil completo para el admin */
    public function perfilCompleto(Voluntario $voluntario): array
    {
        $voluntario->load([
            'usuario',
            'municipio.departamento',
            'habilidades',
            'intereses',
        ]);

        return [
            'id'                   => $voluntario->id,
            'usuario'              => [
                'id'              => $voluntario->usuario->id,
                'nombre'          => $voluntario->usuario->nombre,
                'email'           => $voluntario->usuario->email,
                'telefono'        => $voluntario->usuario->telefono,
                'estado'          => $voluntario->usuario->estado,
                'email_verificado'=> $voluntario->usuario->email_verificado,
                'fecha_registro'  => $voluntario->usuario->fecha_registro,
            ],
            'tipo_documento'       => $voluntario->tipo_documento,
            'numero_documento'     => $voluntario->numero_documento,
            'fecha_nacimiento'     => $voluntario->fecha_nacimiento,
            'genero'               => $voluntario->genero,
            'disponibilidad'       => $voluntario->disponibilidad,
            'experiencia'          => $voluntario->experiencia,
            'municipio'            => $voluntario->municipio?->nombre,
            'departamento'         => $voluntario->municipio?->departamento?->nombre,
            'habilidades'          => $voluntario->habilidades->pluck('nombre'),
            'intereses'            => $voluntario->intereses->pluck('nombre'),
            'total_participaciones'=> $voluntario->postulaciones()->where('estado', 'ASISTIO')->count(),
            'calificacion_promedio'=> $voluntario->calificacionPromedio(),
            'advertencias_activas' => $voluntario->advertencias()->where('activa', true)->count(),
        ];
    }

    // ── Privado ───────────────────────────────────────────────

    private function cambiarEstado(
        AdminPerfil $admin,
        Voluntario $voluntario,
        EstadoUsuario $nuevoEstado,
        string $motivo,
        ?int $duracionDias
    ): Voluntario {
        $estadoAnterior = $voluntario->usuario->estado;

        $voluntario->usuario()->update(['estado' => $nuevoEstado]);

        // Registrar en historial
        HistorialEstadoVoluntario::create([
            'usuario_id'      => $voluntario->usuario_id,
            'estado_anterior' => $estadoAnterior instanceof \BackedEnum
                ? $estadoAnterior->value : $estadoAnterior,
            'estado_nuevo'    => $nuevoEstado->value,
            'motivo'          => $motivo,
            'duracion_dias'   => $duracionDias,
            'admin_id'        => $admin->id,
        ]);

        // Notificar al voluntario
        $mensajeNotif = match ($nuevoEstado) {
            EstadoUsuario::SUSPENDIDO => "Tu cuenta ha sido suspendida. Motivo: {$motivo}",
            EstadoUsuario::BLOQUEADO  => "Tu cuenta ha sido bloqueada. Motivo: {$motivo}",
            EstadoUsuario::ACTIVO     => 'Tu cuenta ha sido reactivada. Ya puedes acceder a la plataforma.',
        };

        Notificacion::create([
            'usuario_id'  => $voluntario->usuario_id,
            'tipo'        => 'RECORDATORIO_ACTIVIDAD',
            'mensaje'     => $mensajeNotif,
            'objeto_tipo' => 'VOLUNTARIO',
            'objeto_id'   => $voluntario->id,
        ]);

        // Auditoría
        $tipoAccion = match ($nuevoEstado) {
            EstadoUsuario::SUSPENDIDO => 'USUARIO_SUSPENDIDO',
            EstadoUsuario::BLOQUEADO  => 'USUARIO_BLOQUEADO',
            EstadoUsuario::ACTIVO     => 'USUARIO_REACTIVADO',
        };

        AdminAccion::create([
            'admin_id'           => $admin->id,
            'tipo'               => $tipoAccion,
            'objeto_tipo'        => 'VOLUNTARIO',
            'objeto_id'          => $voluntario->id,
            'objeto_descripcion' => $voluntario->usuario->nombre ?? '',
            'detalle_anterior'   => ['estado' => $estadoAnterior instanceof \BackedEnum
                ? $estadoAnterior->value : $estadoAnterior],
            'detalle_nuevo'      => ['estado' => $nuevoEstado->value],
            'motivo'             => $motivo,
        ]);

        return $voluntario->fresh(['usuario', 'municipio.departamento']);
    }
}

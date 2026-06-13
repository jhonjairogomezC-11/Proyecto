<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE tipo_notificacion AS ENUM (
            'NUEVA_POSTULACION','POSTULACION_RETIRADA','VOLUNTARIO_ASISTIO','VOLUNTARIO_NO_ASISTIO',
            'POSTULACION_ACEPTADA','POSTULACION_RECHAZADA','ACTIVIDAD_CANCELADA','ACTIVIDAD_MODIFICADA',
            'FUNDACION_APROBADA','FUNDACION_RECHAZADA','FUNDACION_SUSPENDIDA','FUNDACION_REACTIVADA',
            'RECORDATORIO_ACTIVIDAD'
        ); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('notificaciones', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->constrained('usuarios')->cascadeOnDelete();
            $table->string('tipo', 40);
            $table->text('mensaje');
            $table->string('objeto_tipo', 30)->nullable();
            $table->uuid('objeto_id')->nullable();
            $table->boolean('leida')->default(false);
            $table->timestamp('fecha_lectura')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
        });

        DB::statement('ALTER TABLE notificaciones ALTER COLUMN tipo DROP DEFAULT');
        DB::statement('ALTER TABLE notificaciones ALTER COLUMN tipo TYPE tipo_notificacion USING tipo::tipo_notificacion');
        DB::statement('CREATE INDEX idx_notif_usuario ON notificaciones(usuario_id, leida, fecha_creacion DESC)');
    }

    public function down(): void
    {
        Schema::dropIfExists('notificaciones');
        DB::statement('DROP TYPE IF EXISTS tipo_notificacion');
    }
};

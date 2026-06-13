<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE nivel_admin AS ENUM ('SUPER','OPERATIVO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE tipo_accion_admin AS ENUM (
            'USUARIO_SUSPENDIDO','USUARIO_BLOQUEADO','USUARIO_REACTIVADO','USUARIO_ELIMINADO','USUARIO_EDITADO',
            'FUNDACION_APROBADA','FUNDACION_RECHAZADA','FUNDACION_SUSPENDIDA','FUNDACION_REACTIVADA',
            'PUBLICACION_OCULTADA','PUBLICACION_RESTAURADA','PUBLICACION_ELIMINADA','PUBLICACION_ESTADO_CAMBIADO',
            'POSTULACION_INTERVENIDA','REPORTE_RESUELTO','REPORTE_DESESTIMADO',
            'PUNTOS_AJUSTADOS','LOGRO_ASIGNADO','ADMIN_CREADO','ADMIN_DESACTIVADO','ADMIN_PERMISOS_ACTUALIZADOS'
        ); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE estado_reporte AS ENUM ('PENDIENTE','EN_REVISION','RESUELTO','DESESTIMADO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE motivo_reporte AS ENUM ('INFORMACION_FALSA','CONTENIDO_INAPROPIADO','ACTIVIDAD_SOSPECHOSA','PERFIL_SOSPECHOSO','OTRO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('admin_perfiles', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->unique()->constrained('usuarios')->cascadeOnDelete();
            $table->string('nivel', 20)->default('OPERATIVO');
            $table->jsonb('permisos')->nullable();
            $table->uuid('creado_por')->nullable();
            $table->boolean('activo')->default(true);
            $table->string('cargo', 100)->nullable();
            $table->text('notas_internas')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement('ALTER TABLE admin_perfiles ALTER COLUMN nivel DROP DEFAULT');
        DB::statement('ALTER TABLE admin_perfiles ALTER COLUMN nivel TYPE nivel_admin USING nivel::nivel_admin');
        DB::statement("ALTER TABLE admin_perfiles ALTER COLUMN nivel SET DEFAULT 'OPERATIVO'");
        DB::statement('ALTER TABLE admin_perfiles ADD CONSTRAINT fk_admin_creado_por FOREIGN KEY (creado_por) REFERENCES admin_perfiles(id) ON DELETE SET NULL');
        DB::statement('CREATE INDEX idx_admin_usuario ON admin_perfiles(usuario_id)');
        DB::statement('CREATE INDEX idx_admin_activo ON admin_perfiles(activo) WHERE activo = TRUE');
        DB::statement('CREATE INDEX idx_admin_nivel ON admin_perfiles(nivel)');

        Schema::create('admin_acciones', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('admin_id')->constrained('admin_perfiles')->restrictOnDelete();
            $table->string('tipo', 40);
            $table->string('objeto_tipo', 30)->nullable();
            $table->uuid('objeto_id')->nullable();
            $table->text('objeto_descripcion')->nullable();
            $table->jsonb('detalle_anterior')->nullable();
            $table->jsonb('detalle_nuevo')->nullable();
            $table->text('motivo')->nullable();
            $table->timestamp('fecha_accion')->useCurrent();
        });

        DB::statement('ALTER TABLE admin_acciones ALTER COLUMN tipo DROP DEFAULT');
        DB::statement('ALTER TABLE admin_acciones ALTER COLUMN tipo TYPE tipo_accion_admin USING tipo::tipo_accion_admin');
        DB::statement('CREATE INDEX idx_admin_acc_admin ON admin_acciones(admin_id)');
        DB::statement('CREATE INDEX idx_admin_acc_tipo ON admin_acciones(tipo)');
        DB::statement('CREATE INDEX idx_admin_acc_objeto ON admin_acciones(objeto_tipo, objeto_id)');
        DB::statement('CREATE INDEX idx_admin_acc_fecha ON admin_acciones(fecha_accion DESC)');

        Schema::create('reportes', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('reportante_id')->constrained('usuarios')->cascadeOnDelete();
            $table->string('objeto_tipo', 30);
            $table->uuid('objeto_id');
            $table->string('motivo', 30);
            $table->text('detalle')->nullable();
            $table->string('estado', 20)->default('PENDIENTE');
            $table->uuid('admin_asignado_id')->nullable();
            $table->timestamp('fecha_asignacion')->nullable();
            $table->text('resolucion')->nullable();
            $table->timestamp('fecha_resolucion')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
        });

        DB::statement('ALTER TABLE reportes ALTER COLUMN motivo DROP DEFAULT');
        DB::statement('ALTER TABLE reportes ALTER COLUMN estado DROP DEFAULT');
        DB::statement('ALTER TABLE reportes ALTER COLUMN motivo TYPE motivo_reporte USING motivo::motivo_reporte');
        DB::statement('ALTER TABLE reportes ALTER COLUMN estado TYPE estado_reporte USING estado::estado_reporte');
        DB::statement("ALTER TABLE reportes ALTER COLUMN estado SET DEFAULT 'PENDIENTE'");
        DB::statement('ALTER TABLE reportes ADD CONSTRAINT fk_reporte_admin FOREIGN KEY (admin_asignado_id) REFERENCES admin_perfiles(id) ON DELETE SET NULL');
        DB::statement('CREATE INDEX idx_reporte_estado ON reportes(estado)');
        DB::statement('CREATE INDEX idx_reporte_objeto ON reportes(objeto_tipo, objeto_id)');
        DB::statement('CREATE INDEX idx_reporte_admin ON reportes(admin_asignado_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('reportes');
        Schema::dropIfExists('admin_acciones');
        Schema::dropIfExists('admin_perfiles');
        DB::statement('DROP TYPE IF EXISTS motivo_reporte');
        DB::statement('DROP TYPE IF EXISTS estado_reporte');
        DB::statement('DROP TYPE IF EXISTS tipo_accion_admin');
        DB::statement('DROP TYPE IF EXISTS nivel_admin');
    }
};

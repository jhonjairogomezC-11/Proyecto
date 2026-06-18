<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Documentos de fundaciones ──────────────────────────
        Schema::create('fundacion_documentos', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('fundacion_id')->constrained('fundaciones')->cascadeOnDelete();
            $table->string('tipo_documento', 60); // camara_comercio | id_representante | certificado
            $table->string('nombre_original', 300);
            $table->text('ruta_archivo');
            $table->boolean('validado')->default(false);
            $table->timestamp('fecha_subida')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_fund_docs_fundacion ON fundacion_documentos(fundacion_id)');
        DB::statement('CREATE INDEX idx_fund_docs_tipo ON fundacion_documentos(tipo_documento)');

        // ── Historial de estados de fundaciones ────────────────
        Schema::create('historial_estados_fundacion', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('fundacion_id')->constrained('fundaciones')->cascadeOnDelete();
            $table->string('estado_anterior', 20);
            $table->string('estado_nuevo', 20);
            $table->text('motivo')->nullable();
            $table->foreignUuid('admin_id')->constrained('admin_perfiles')->restrictOnDelete();
            $table->timestamp('fecha')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_hist_fund_fundacion ON historial_estados_fundacion(fundacion_id)');
        DB::statement('CREATE INDEX idx_hist_fund_fecha ON historial_estados_fundacion(fecha DESC)');

        // ── Advertencias a voluntarios ─────────────────────────
        Schema::create('advertencias_voluntario', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->foreignUuid('admin_id')->constrained('admin_perfiles')->restrictOnDelete();
            $table->text('motivo');
            $table->boolean('activa')->default(true);
            $table->timestamp('fecha')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_adv_voluntario ON advertencias_voluntario(voluntario_id)');
        DB::statement('CREATE INDEX idx_adv_activa ON advertencias_voluntario(activa) WHERE activa = TRUE');

        // ── Historial de estados de voluntarios ────────────────
        Schema::create('historial_estados_voluntario', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->constrained('usuarios')->cascadeOnDelete();
            $table->string('estado_anterior', 20);
            $table->string('estado_nuevo', 20);
            $table->text('motivo')->nullable();
            $table->integer('duracion_dias')->nullable(); // para suspensiones temporales
            $table->foreignUuid('admin_id')->constrained('admin_perfiles')->restrictOnDelete();
            $table->timestamp('fecha')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_hist_vol_usuario ON historial_estados_voluntario(usuario_id)');
        DB::statement('CREATE INDEX idx_hist_vol_fecha ON historial_estados_voluntario(fecha DESC)');
    }

    public function down(): void
    {
        Schema::dropIfExists('historial_estados_voluntario');
        Schema::dropIfExists('advertencias_voluntario');
        Schema::dropIfExists('historial_estados_fundacion');
        Schema::dropIfExists('fundacion_documentos');
    }
};

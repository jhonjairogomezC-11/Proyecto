<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE estado_postulacion AS ENUM ('PENDIENTE','ACEPTADO','RECHAZADO','RETIRADO','ASISTIO','NO_ASISTIO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('postulaciones', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('publicacion_id')->constrained('publicaciones')->cascadeOnDelete();
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->string('estado', 20)->default('PENDIENTE');
            $table->text('mensaje_voluntario')->nullable();
            $table->text('motivo_rechazo')->nullable();
            $table->timestamp('fecha_respuesta')->nullable();
            $table->timestamp('fecha_confirmacion')->nullable();
            $table->smallInteger('calificacion')->nullable();
            $table->text('comentario_fundacion')->nullable();
            $table->timestamp('fecha_postulacion')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
            $table->unique(['publicacion_id', 'voluntario_id']);
        });

        DB::statement('ALTER TABLE postulaciones ALTER COLUMN estado DROP DEFAULT');
        DB::statement('ALTER TABLE postulaciones ALTER COLUMN estado TYPE estado_postulacion USING estado::estado_postulacion');
        DB::statement("ALTER TABLE postulaciones ALTER COLUMN estado SET DEFAULT 'PENDIENTE'");
        DB::statement('ALTER TABLE postulaciones ADD CONSTRAINT chk_calificacion_valida CHECK (calificacion IS NULL OR calificacion BETWEEN 1 AND 5)');
        DB::statement("ALTER TABLE postulaciones ADD CONSTRAINT chk_calificacion_solo_si_asistio CHECK (calificacion IS NULL OR estado = 'ASISTIO')");

        DB::statement('CREATE INDEX idx_post_publicacion ON postulaciones(publicacion_id)');
        DB::statement('CREATE INDEX idx_post_voluntario ON postulaciones(voluntario_id)');
        DB::statement('CREATE INDEX idx_post_estado ON postulaciones(estado)');
        DB::statement('CREATE INDEX idx_post_voluntario_estado ON postulaciones(voluntario_id, estado)');
        DB::statement('CREATE INDEX idx_post_publicacion_estado ON postulaciones(publicacion_id, estado)');
    }

    public function down(): void
    {
        Schema::dropIfExists('postulaciones');
        DB::statement('DROP TYPE IF EXISTS estado_postulacion');
    }
};

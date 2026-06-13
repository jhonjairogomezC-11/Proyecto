<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE modalidad_tipo AS ENUM ('PRESENCIAL','VIRTUAL','HIBRIDA'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE estado_publicacion AS ENUM ('BORRADOR','PUBLICADA','CERRADA','CANCELADA','COMPLETADA','FINALIZADA'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('publicaciones', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('fundacion_id')->constrained('fundaciones')->cascadeOnDelete();
            $table->string('titulo', 200);
            $table->text('descripcion');
            $table->unsignedInteger('categoria_id');
            $table->foreign('categoria_id')->references('id')->on('areas_impacto')->restrictOnDelete();
            $table->string('modalidad', 20);
            $table->unsignedInteger('municipio_id')->nullable();
            $table->foreign('municipio_id')->references('id')->on('municipios')->restrictOnDelete();
            $table->string('direccion_exacta', 200)->nullable();
            $table->text('enlace_virtual')->nullable();
            $table->date('fecha_inicio');
            $table->date('fecha_fin');
            $table->time('hora_inicio')->nullable();
            $table->time('hora_fin')->nullable();
            $table->integer('cupo_maximo')->default(1);
            $table->integer('edad_minima')->nullable();
            $table->integer('edad_maxima')->nullable();
            $table->text('requisitos_adicionales')->nullable();
            $table->string('imagen', 500)->nullable();
            $table->string('contacto_nombre', 150)->nullable();
            $table->string('contacto_email', 150)->nullable();
            $table->string('contacto_telefono', 20)->nullable();
            $table->string('estado', 20)->default('BORRADOR');
            $table->boolean('oculta_por_admin')->default(false);
            $table->text('motivo_ocultamiento')->nullable();
            $table->timestamp('fecha_ocultamiento')->nullable();
            $table->timestamp('fecha_publicacion')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement('ALTER TABLE publicaciones ALTER COLUMN modalidad DROP DEFAULT');
        DB::statement('ALTER TABLE publicaciones ALTER COLUMN estado DROP DEFAULT');
        DB::statement('ALTER TABLE publicaciones ALTER COLUMN modalidad TYPE modalidad_tipo USING modalidad::modalidad_tipo');
        DB::statement('ALTER TABLE publicaciones ALTER COLUMN estado TYPE estado_publicacion USING estado::estado_publicacion');
        DB::statement("ALTER TABLE publicaciones ALTER COLUMN estado SET DEFAULT 'BORRADOR'");
        DB::statement('ALTER TABLE publicaciones ADD CONSTRAINT chk_fechas_validas CHECK (fecha_fin >= fecha_inicio)');
        DB::statement('ALTER TABLE publicaciones ADD CONSTRAINT chk_cupo_valido CHECK (cupo_maximo >= 1)');
        DB::statement('ALTER TABLE publicaciones ADD CONSTRAINT chk_edades_validas CHECK (edad_minima IS NULL OR edad_maxima IS NULL OR edad_maxima >= edad_minima)');
        DB::statement("ALTER TABLE publicaciones ADD CONSTRAINT chk_ubicacion_presencial CHECK (modalidad = 'VIRTUAL' OR (modalidad IN ('PRESENCIAL','HIBRIDA') AND municipio_id IS NOT NULL))");

        DB::statement('CREATE INDEX idx_pub_fundacion ON publicaciones(fundacion_id)');
        DB::statement('CREATE INDEX idx_pub_estado ON publicaciones(estado)');
        DB::statement('CREATE INDEX idx_pub_categoria ON publicaciones(categoria_id)');
        DB::statement('CREATE INDEX idx_pub_municipio ON publicaciones(municipio_id)');
        DB::statement('CREATE INDEX idx_pub_fecha_inicio ON publicaciones(fecha_inicio)');
        DB::statement('CREATE INDEX idx_pub_modalidad ON publicaciones(modalidad)');
        DB::statement('CREATE INDEX idx_pub_estado_fecha ON publicaciones(estado, fecha_inicio)');

        Schema::create('publicacion_habilidades', function (Blueprint $table) {
            $table->foreignUuid('publicacion_id')->constrained('publicaciones')->cascadeOnDelete();
            $table->unsignedInteger('habilidad_id');
            $table->foreign('habilidad_id')->references('id')->on('habilidades')->cascadeOnDelete();
            $table->primary(['publicacion_id', 'habilidad_id']);
        });

        DB::statement('CREATE INDEX idx_pub_habilidades ON publicacion_habilidades(publicacion_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('publicacion_habilidades');
        Schema::dropIfExists('publicaciones');
        DB::statement('DROP TYPE IF EXISTS estado_publicacion');
        DB::statement('DROP TYPE IF EXISTS modalidad_tipo');
    }
};

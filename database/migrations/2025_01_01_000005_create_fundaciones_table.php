<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE estado_verificacion AS ENUM ('PENDIENTE','APROBADA','RECHAZADA','SUSPENDIDA'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('areas_impacto', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100)->unique();
        });

        Schema::create('fundaciones', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->unique()->constrained('usuarios')->cascadeOnDelete();
            $table->string('nombre', 150);
            $table->string('nit', 20)->unique();
            $table->string('representante_legal', 150);
            $table->string('correo_institucional', 150)->nullable();
            $table->string('telefono', 20);
            $table->string('direccion', 200);
            $table->unsignedInteger('municipio_id');
            $table->foreign('municipio_id')->references('id')->on('municipios')->restrictOnDelete();
            $table->string('pagina_web', 255)->nullable();
            $table->text('descripcion');
            $table->text('documento_legal');
            $table->string('logo', 500)->nullable();
            $table->string('estado_verificacion', 20)->default('PENDIENTE');
            $table->timestamp('fecha_verificacion')->nullable();
            $table->text('motivo_rechazo')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement('ALTER TABLE fundaciones ALTER COLUMN estado_verificacion DROP DEFAULT');
        DB::statement('ALTER TABLE fundaciones ALTER COLUMN estado_verificacion TYPE estado_verificacion USING estado_verificacion::estado_verificacion');
        DB::statement("ALTER TABLE fundaciones ALTER COLUMN estado_verificacion SET DEFAULT 'PENDIENTE'");
        DB::statement("ALTER TABLE fundaciones ADD CONSTRAINT chk_nit_formato CHECK (nit ~ '^\\d{7,10}-\\d$')");
        DB::statement("ALTER TABLE fundaciones ADD CONSTRAINT chk_correo_si_aprobada CHECK (estado_verificacion != 'APROBADA' OR correo_institucional IS NOT NULL)");

        DB::statement('CREATE INDEX idx_fundacion_usuario ON fundaciones(usuario_id)');
        DB::statement('CREATE INDEX idx_fundacion_nit ON fundaciones(nit)');
        DB::statement('CREATE INDEX idx_fundacion_municipio ON fundaciones(municipio_id)');
        DB::statement('CREATE INDEX idx_fundacion_estado ON fundaciones(estado_verificacion)');
        DB::statement('CREATE UNIQUE INDEX idx_fundacion_correo_unique ON fundaciones(correo_institucional) WHERE correo_institucional IS NOT NULL');

        Schema::create('fundacion_areas', function (Blueprint $table) {
            $table->foreignUuid('fundacion_id')->constrained('fundaciones')->cascadeOnDelete();
            $table->unsignedInteger('area_id');
            $table->foreign('area_id')->references('id')->on('areas_impacto')->cascadeOnDelete();
            $table->primary(['fundacion_id', 'area_id']);
        });

        DB::statement('CREATE INDEX idx_fundacion_areas ON fundacion_areas(fundacion_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('fundacion_areas');
        Schema::dropIfExists('fundaciones');
        Schema::dropIfExists('areas_impacto');
        DB::statement('DROP TYPE IF EXISTS estado_verificacion');
    }
};

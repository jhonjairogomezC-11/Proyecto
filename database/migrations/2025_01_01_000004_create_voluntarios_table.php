<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("DO \$\$ BEGIN CREATE TYPE tipo_documento AS ENUM ('CC','TI','CE','PASAPORTE'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE genero_tipo AS ENUM ('MASCULINO','FEMENINO','OTRO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE disponibilidad_tipo AS ENUM ('ENTRE_SEMANA','FINES_DE_SEMANA','FLEXIBLE'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('voluntarios', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->unique()->constrained('usuarios')->cascadeOnDelete();
            $table->string('tipo_documento', 20);
            $table->string('numero_documento', 30)->unique();
            $table->date('fecha_nacimiento');
            $table->string('genero', 20);
            $table->unsignedInteger('municipio_id');
            $table->foreign('municipio_id')->references('id')->on('municipios')->restrictOnDelete();
            $table->string('disponibilidad', 20);
            $table->text('experiencia')->nullable();
            $table->string('foto_perfil', 500)->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement('ALTER TABLE voluntarios ALTER COLUMN tipo_documento DROP DEFAULT');
        DB::statement('ALTER TABLE voluntarios ALTER COLUMN genero DROP DEFAULT');
        DB::statement('ALTER TABLE voluntarios ALTER COLUMN disponibilidad DROP DEFAULT');

        DB::statement('ALTER TABLE voluntarios ALTER COLUMN tipo_documento TYPE tipo_documento USING tipo_documento::tipo_documento');
        DB::statement('ALTER TABLE voluntarios ALTER COLUMN genero TYPE genero_tipo USING genero::genero_tipo');
        DB::statement('ALTER TABLE voluntarios ALTER COLUMN disponibilidad TYPE disponibilidad_tipo USING disponibilidad::disponibilidad_tipo');
        DB::statement("ALTER TABLE voluntarios ADD CONSTRAINT chk_edad_minima CHECK (fecha_nacimiento <= (CURRENT_DATE - INTERVAL '14 years'))");

        DB::statement('CREATE INDEX idx_voluntario_usuario ON voluntarios(usuario_id)');
        DB::statement('CREATE INDEX idx_voluntario_municipio ON voluntarios(municipio_id)');

        Schema::create('habilidades', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100)->unique();
        });

        Schema::create('intereses', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100)->unique();
        });

        Schema::create('voluntario_habilidades', function (Blueprint $table) {
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->unsignedInteger('habilidad_id');
            $table->foreign('habilidad_id')->references('id')->on('habilidades')->cascadeOnDelete();
            $table->primary(['voluntario_id', 'habilidad_id']);
        });

        Schema::create('voluntario_intereses', function (Blueprint $table) {
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->unsignedInteger('interes_id');
            $table->foreign('interes_id')->references('id')->on('intereses')->cascadeOnDelete();
            $table->primary(['voluntario_id', 'interes_id']);
        });

        DB::statement('CREATE INDEX idx_vol_hab ON voluntario_habilidades(voluntario_id)');
        DB::statement('CREATE INDEX idx_vol_int ON voluntario_intereses(voluntario_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('voluntario_intereses');
        Schema::dropIfExists('voluntario_habilidades');
        Schema::dropIfExists('intereses');
        Schema::dropIfExists('habilidades');
        Schema::dropIfExists('voluntarios');
        DB::statement('DROP TYPE IF EXISTS disponibilidad_tipo');
        DB::statement('DROP TYPE IF EXISTS genero_tipo');
        DB::statement('DROP TYPE IF EXISTS tipo_documento');
    }
};

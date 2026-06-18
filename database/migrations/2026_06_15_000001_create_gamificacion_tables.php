<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Nivel de dificultad para publicaciones ─────────────
        DB::statement("DO \$\$ BEGIN
            CREATE TYPE dificultad_tipo AS ENUM ('FACIL','MEDIA','DIFICIL','MUY_DIFICIL');
        EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        // ── Añadir dificultad y urgente a publicaciones ────────
        Schema::table('publicaciones', function (Blueprint $table) {
            $table->string('dificultad', 15)->default('MEDIA')->after('cupo_maximo');
            $table->boolean('urgente')->default(false)->after('dificultad');
        });

        DB::statement("ALTER TABLE publicaciones ALTER COLUMN dificultad DROP DEFAULT");
        DB::statement("ALTER TABLE publicaciones ALTER COLUMN dificultad TYPE dificultad_tipo USING dificultad::dificultad_tipo");
        DB::statement("ALTER TABLE publicaciones ALTER COLUMN dificultad SET DEFAULT 'MEDIA'");

        // ── Saldo de puntos por voluntario ─────────────────────
        Schema::create('voluntario_puntos', function (Blueprint $table) {
            $table->foreignUuid('voluntario_id')->primary()->constrained('voluntarios')->cascadeOnDelete();
            $table->integer('saldo')->default(0);
            $table->integer('total_historico')->default(0);
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        // ── Historial de transacciones de puntos ───────────────
        Schema::create('transacciones_puntos', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->foreignUuid('postulacion_id')->nullable()->constrained('postulaciones')->nullOnDelete();
            $table->integer('puntos_base');
            $table->integer('puntos_bonus')->default(0);
            $table->integer('puntos_total');
            $table->string('motivo', 200);
            $table->timestamp('fecha')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_trans_voluntario ON transacciones_puntos(voluntario_id)');
        DB::statement('CREATE INDEX idx_trans_fecha ON transacciones_puntos(fecha DESC)');

        // ── Catálogo de logros ─────────────────────────────────
        Schema::create('logros', function (Blueprint $table) {
            $table->increments('id');
            $table->string('codigo', 50)->unique();   // ej: PRIMER_PASO
            $table->string('nombre', 100);
            $table->text('descripcion');
            $table->string('icono', 10)->default('🏆'); // emoji
            $table->string('tipo', 30);               // participaciones | puntos | dificultad | especial
            $table->integer('umbral')->default(0);    // valor numérico del umbral
            $table->boolean('activo')->default(true);
        });

        // ── Logros obtenidos por voluntarios ───────────────────
        Schema::create('voluntario_logros', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('voluntario_id')->constrained('voluntarios')->cascadeOnDelete();
            $table->unsignedInteger('logro_id');
            $table->foreign('logro_id')->references('id')->on('logros')->restrictOnDelete();
            $table->timestamp('fecha_obtencion')->useCurrent();
            $table->unique(['voluntario_id', 'logro_id']);
        });

        DB::statement('CREATE INDEX idx_vol_logros_voluntario ON voluntario_logros(voluntario_id)');

        // ── Insertar catálogo de logros iniciales ──────────────
        $logros = [
            // Por participaciones
            ['codigo' => 'PRIMER_PASO',        'nombre' => 'Primer Paso',           'descripcion' => 'Participar en 1 convocatoria.',            'icono' => '👣', 'tipo' => 'participaciones', 'umbral' => 1],
            ['codigo' => 'COMPROMETIDO',        'nombre' => 'Comprometido',          'descripcion' => 'Participar en 5 convocatorias.',            'icono' => '🤝', 'tipo' => 'participaciones', 'umbral' => 5],
            ['codigo' => 'VOLUNTARIO_ACTIVO',   'nombre' => 'Voluntario Activo',     'descripcion' => 'Participar en 10 convocatorias.',           'icono' => '⭐', 'tipo' => 'participaciones', 'umbral' => 10],
            ['codigo' => 'IMPACTO_SOCIAL',      'nombre' => 'Impacto Social',        'descripcion' => 'Participar en 25 convocatorias.',           'icono' => '🌟', 'tipo' => 'participaciones', 'umbral' => 25],
            ['codigo' => 'LEYENDA_SOLIDARIA',   'nombre' => 'Leyenda Solidaria',     'descripcion' => 'Participar en 50 convocatorias.',           'icono' => '🏆', 'tipo' => 'participaciones', 'umbral' => 50],
            // Por puntos
            ['codigo' => 'ACUMULADOR',          'nombre' => 'Acumulador',            'descripcion' => 'Acumular 100 puntos.',                      'icono' => '💯', 'tipo' => 'puntos',          'umbral' => 100],
            ['codigo' => 'VETERANO',            'nombre' => 'Veterano',              'descripcion' => 'Acumular 500 puntos.',                      'icono' => '🎖️', 'tipo' => 'puntos',          'umbral' => 500],
            ['codigo' => 'ELITE',               'nombre' => 'Élite',                 'descripcion' => 'Acumular 1000 puntos.',                     'icono' => '💎', 'tipo' => 'puntos',          'umbral' => 1000],
            // Por dificultad
            ['codigo' => 'VALIENTE',            'nombre' => 'Valiente',              'descripcion' => 'Participar en 1 actividad DIFÍCIL.',        'icono' => '💪', 'tipo' => 'dificultad',     'umbral' => 1],
            ['codigo' => 'HEROE',               'nombre' => 'Héroe',                 'descripcion' => 'Participar en 1 actividad MUY DIFÍCIL.',    'icono' => '🦸', 'tipo' => 'dificultad',     'umbral' => 1],
            // Especiales
            ['codigo' => 'URGENTE_RESPONDER',   'nombre' => 'Siempre Presente',      'descripcion' => 'Participar en 3 actividades urgentes.',     'icono' => '🚨', 'tipo' => 'urgente',        'umbral' => 3],
        ];

        foreach ($logros as $logro) {
            DB::table('logros')->insertOrIgnore($logro);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('voluntario_logros');
        Schema::dropIfExists('logros');
        Schema::dropIfExists('transacciones_puntos');
        Schema::dropIfExists('voluntario_puntos');
        Schema::table('publicaciones', function (Blueprint $table) {
            $table->dropColumn(['dificultad', 'urgente']);
        });
        DB::statement('DROP TYPE IF EXISTS dificultad_tipo');
    }
};

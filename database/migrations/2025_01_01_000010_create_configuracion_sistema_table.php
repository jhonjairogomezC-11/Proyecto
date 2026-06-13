<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('configuracion_sistema', function (Blueprint $table) {
            $table->string('clave', 100)->primary();
            $table->text('valor_texto')->nullable();
            $table->integer('valor_int')->nullable();
            $table->decimal('valor_decimal', 10, 4)->nullable();
            $table->boolean('valor_bool')->nullable();
            $table->text('descripcion');
            $table->string('modulo', 50);
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement('CREATE INDEX idx_config_modulo ON configuracion_sistema(modulo)');
    }

    public function down(): void
    {
        Schema::dropIfExists('configuracion_sistema');
    }
};

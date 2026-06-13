<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('departamentos', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100)->unique();
        });

        Schema::create('municipios', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100);
            $table->unsignedInteger('departamento_id');
            $table->foreign('departamento_id')->references('id')->on('departamentos')->restrictOnDelete();
            $table->unique(['nombre', 'departamento_id']);
        });

        DB::statement('CREATE INDEX idx_municipio_departamento ON municipios(departamento_id)');
    }

    public function down(): void
    {
        Schema::dropIfExists('municipios');
        Schema::dropIfExists('departamentos');
    }
};

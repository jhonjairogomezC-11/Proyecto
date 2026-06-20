<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('publicacion_imagenes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('publicacion_id');
            $table->string('ruta', 500);
            $table->unsignedTinyInteger('orden')->default(0);
            $table->timestamp('fecha_creacion')->useCurrent();

            $table->foreign('publicacion_id')->references('id')->on('publicaciones')->cascadeOnDelete();
            $table->index(['publicacion_id', 'orden']);
        });

        Schema::create('voluntario_favoritos', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('voluntario_id');
            $table->string('tipo', 20); // PUBLICACION | FUNDACION
            $table->uuid('publicacion_id')->nullable();
            $table->uuid('fundacion_id')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();

            $table->foreign('voluntario_id')->references('id')->on('voluntarios')->cascadeOnDelete();
            $table->foreign('publicacion_id')->references('id')->on('publicaciones')->cascadeOnDelete();
            $table->foreign('fundacion_id')->references('id')->on('fundaciones')->cascadeOnDelete();

            $table->unique(['voluntario_id', 'publicacion_id'], 'vol_fav_pub_unique');
            $table->unique(['voluntario_id', 'fundacion_id'], 'vol_fav_fund_unique');
            $table->index(['voluntario_id', 'tipo']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('voluntario_favoritos');
        Schema::dropIfExists('publicacion_imagenes');
    }
};

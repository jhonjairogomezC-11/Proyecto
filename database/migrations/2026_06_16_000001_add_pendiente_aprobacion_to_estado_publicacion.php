<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Agregar el nuevo valor al enum de PostgreSQL
        DB::statement("ALTER TYPE estado_publicacion ADD VALUE IF NOT EXISTS 'PENDIENTE_APROBACION' BEFORE 'PUBLICADA'");
    }

    public function down(): void
    {
        // PostgreSQL no permite eliminar valores de un enum sin recrearlo
        // No reversible directamente
    }
};

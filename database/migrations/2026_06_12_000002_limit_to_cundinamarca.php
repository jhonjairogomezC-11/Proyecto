<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Eliminar municipios de departamentos que no son Cundinamarca ni Bogotá
        DB::statement("
            DELETE FROM municipios
            WHERE departamento_id IN (
                SELECT id FROM departamentos
                WHERE nombre NOT IN ('Cundinamarca', 'Bogotá D.C.')
            )
        ");

        // Eliminar los departamentos no cubiertos
        DB::statement("
            DELETE FROM departamentos
            WHERE nombre NOT IN ('Cundinamarca', 'Bogotá D.C.')
        ");
    }

    public function down(): void
    {
        // No se puede revertir esta migración sin re-sembrar
        // Ejecutar: php artisan db:seed --class=CatalogosSeeder
    }
};

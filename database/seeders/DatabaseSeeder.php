<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            CatalogosSeeder::class,
            AdminSeeder::class,
            DemoSeeder::class,
            MassiveDataSeeder::class,  // Datos masivos para simular producción
        ]);
    }
}

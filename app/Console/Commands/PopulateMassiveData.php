<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

class PopulateMassiveData extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'db:populate-massive 
                           {--fresh : Drop all tables and migrate from scratch}
                           {--force : Force the operation to run when in production}';

    /**
     * The console command description.
     */
    protected $description = 'Populate the database with massive realistic data for production simulation';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        if (app()->environment('production') && !$this->option('force')) {
            $this->error('❌ This command cannot run in production without --force flag');
            return 1;
        }

        $this->info('🚀 Starting massive data population...');
        
        if ($this->option('fresh')) {
            $this->warn('⚠️  Dropping all tables and migrating from scratch...');
            if (!$this->confirm('This will delete ALL existing data. Are you sure?')) {
                $this->info('Operation cancelled.');
                return 0;
            }
            
            Artisan::call('migrate:fresh', ['--force' => true]);
            $this->info('✅ Database migrated fresh');
        }

        // Execute seeders
        $this->info('📊 Running catalog seeders...');
        Artisan::call('db:seed', [
            '--class' => 'CatalogosSeeder',
            '--force' => true
        ]);
        
        $this->info('👥 Creating admin users...');
        Artisan::call('db:seed', [
            '--class' => 'AdminSeeder', 
            '--force' => true
        ]);
        
        $this->info('🎭 Creating demo data...');
        Artisan::call('db:seed', [
            '--class' => 'DemoSeeder',
            '--force' => true
        ]);
        
        $this->info('🌊 Creating massive realistic data...');
        Artisan::call('db:seed', [
            '--class' => 'MassiveDataSeeder',
            '--force' => true
        ]);

        // Show statistics
        $this->showStatistics();
        
        $this->info('✅ Massive data population completed successfully!');
        $this->info('');
        $this->info('🔑 Admin Credentials:');
        $this->table(['Email', 'Password', 'Role'], [
            ['maria.rodriguez@voluntapp.co', 'Admin1234!', 'Directora General (SUPER)'],
            ['carlos.martinez@voluntapp.co', 'Coord2024!', 'Coordinador Operaciones (OPERATIVO)'],
            ['ana.hernandez@voluntapp.co', 'Mod2024!', 'Especialista Contenidos (MODERADOR)'],
            ['luis.garcia@voluntapp.co', 'Super2024!', 'Supervisor Calidad (OPERATIVO)'],
            ['patricia.morales@voluntapp.co', 'Region2024!', 'Coordinadora Regional (MODERADOR)'],
            ['admin@voluntapp.co', 'Admin1234!', 'Super Administrador (Legacy)']
        ]);
        
        return 0;
    }

    private function showStatistics(): void
    {
        $this->info('');
        $this->info('📈 Database Statistics:');
        
        $stats = [
            ['Users', DB::table('usuarios')->count()],
            ['Volunteers', DB::table('voluntarios')->count()],
            ['Foundations', DB::table('fundaciones')->count()],
            ['Publications', DB::table('publicaciones')->count()],
            ['Applications', DB::table('postulaciones')->count()],
            ['Admins', DB::table('admin_perfiles')->count()],
        ];
        
        $this->table(['Entity', 'Count'], $stats);
        
        // Status breakdown
        $this->info('');
        $this->info('👤 User Status Breakdown:');
        $userStats = DB::table('usuarios')
            ->select('estado', DB::raw('count(*) as count'))
            ->groupBy('estado')
            ->get()
            ->toArray();
            
        $userStatsFormatted = array_map(function($item) {
            return ['Status' => $item->estado, 'Count' => $item->count];
        }, $userStats);
        
        $this->table(['Status', 'Count'], $userStatsFormatted);
        
        $this->info('');
        $this->info('🏢 Foundation Status Breakdown:');
        $fundStats = DB::table('fundaciones')
            ->select('estado_verificacion', DB::raw('count(*) as count'))
            ->groupBy('estado_verificacion')
            ->get()
            ->toArray();
            
        $fundStatsFormatted = array_map(function($item) {
            return ['Status' => $item->estado_verificacion, 'Count' => $item->count];
        }, $fundStats);
        
        $this->table(['Status', 'Count'], $fundStatsFormatted);
    }
}

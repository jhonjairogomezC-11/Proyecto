<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "🔍 Obteniendo credenciales REALES de la base de datos actual...\n\n";

echo "📋 ADMINISTRADORES (password específico):\n";
$admins = App\Models\Usuario::where('rol', 'ADMIN')->get();
foreach($admins as $admin) {
    echo "✅ {$admin->email}\n";
}

echo "\n👥 VOLUNTARIOS ACTIVOS (password123):\n";
$voluntarios = App\Models\Usuario::where('rol', 'VOLUNTARIO')
    ->where('estado', 'ACTIVO')
    ->limit(10)
    ->get();

foreach($voluntarios as $vol) {
    echo "✅ {$vol->email} - {$vol->nombre}\n";
}

echo "\n🏢 FUNDACIONES APROBADAS (password123):\n";
$fundaciones = App\Models\Usuario::where('rol', 'FUNDACION')
    ->whereHas('fundacion', function($q) {
        $q->where('estado_verificacion', 'APROBADA');
    })
    ->limit(10)
    ->get();

foreach($fundaciones as $fund) {
    $fundacionData = $fund->fundacion;
    echo "✅ {$fund->email} - {$fundacionData->nombre}\n";
}
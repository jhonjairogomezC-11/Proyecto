<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\Hash;

echo "🔍 Verificando credenciales en la base de datos...\n\n";

// Admin principal
echo "📋 ADMINISTRADORES:\n";
$admin = App\Models\Usuario::where('email', 'maria.rodriguez@voluntapp.co')->first();
if ($admin) {
    echo "Email: {$admin->email}\n";
    echo "Password 'Admin1234!' válido: " . (Hash::check('Admin1234!', $admin->password_hash) ? '✅ SI' : '❌ NO') . "\n";
    echo "Rol: {$admin->rol->value}\n";
    echo "Estado: {$admin->estado->value}\n\n";
} else {
    echo "❌ Admin maria.rodriguez@voluntapp.co NO ENCONTRADO\n\n";
}

// Verificar admin legacy
$adminLegacy = App\Models\Usuario::where('email', 'admin@voluntapp.co')->first();
if ($adminLegacy) {
    echo "Email: {$adminLegacy->email}\n";
    echo "Password 'Admin1234!' válido: " . (Hash::check('Admin1234!', $adminLegacy->password_hash) ? '✅ SI' : '❌ NO') . "\n\n";
} else {
    echo "❌ Admin admin@voluntapp.co NO ENCONTRADO\n\n";
}

echo "👥 VOLUNTARIOS:\n";
$voluntario = App\Models\Usuario::where('email', 'luis.lopez1782063718@hotmail.com')->first();
if ($voluntario) {
    echo "Email: {$voluntario->email}\n";
    echo "Password 'password123' válido: " . (Hash::check('password123', $voluntario->password_hash) ? '✅ SI' : '❌ NO') . "\n";
    echo "Rol: {$voluntario->rol->value}\n";
    echo "Estado: {$voluntario->estado->value}\n\n";
} else {
    echo "❌ Voluntario luis.lopez1782063718@hotmail.com NO ENCONTRADO\n\n";
}

echo "🏢 FUNDACIONES:\n";
$fundacion = App\Models\Usuario::where('email', 'cruz.verde.colombia1782064741@yahoo.com')->first();
if ($fundacion) {
    echo "Email: {$fundacion->email}\n";
    echo "Password 'password123' válido: " . (Hash::check('password123', $fundacion->password_hash) ? '✅ SI' : '❌ NO') . "\n";
    echo "Rol: {$fundacion->rol->value}\n";
    echo "Estado: {$fundacion->estado->value}\n\n";
} else {
    echo "❌ Fundación cruz.verde.colombia1782064741@yahoo.com NO ENCONTRADA\n\n";
}

echo "📊 ESTADÍSTICAS:\n";
echo "Total usuarios: " . App\Models\Usuario::count() . "\n";
echo "Admins: " . App\Models\Usuario::where('rol', 'ADMIN')->count() . "\n";
echo "Voluntarios: " . App\Models\Usuario::where('rol', 'VOLUNTARIO')->count() . "\n";
echo "Fundaciones: " . App\Models\Usuario::where('rol', 'FUNDACION')->count() . "\n";
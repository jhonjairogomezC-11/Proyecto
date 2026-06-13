<?php

use Illuminate\Support\Facades\Route;

// La aplicación es SPA — todas las rutas frontend las sirve el index.html del frontend.
// La ruta web raíz retorna un 200 simple para verificación de salud.
Route::get('/', function () {
    return response()->json(['status' => 'ok', 'app' => 'VoluntApp API']);
});

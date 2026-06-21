<?php

use App\Http\Controllers\Api\V1\GamificacionController;
use App\Http\Controllers\Api\V1\Admin\AdminFundacionController;
use App\Http\Controllers\Api\V1\Admin\AdminPublicacionController;
use App\Http\Controllers\Api\V1\Admin\AdminReporteController;
use App\Http\Controllers\Api\V1\Admin\AdminVoluntarioController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\CatalogoController;
use App\Http\Controllers\Api\V1\FavoritoController;
use App\Http\Controllers\Api\V1\FundacionController;
use App\Http\Controllers\Api\V1\NotificacionController;
use App\Http\Controllers\Api\V1\PostulacionController;
use App\Http\Controllers\Api\V1\PublicacionController;
use App\Http\Controllers\Api\V1\VoluntarioController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {

    // ── Rutas públicas ────────────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('register',            [AuthController::class, 'register']);
        Route::post('login',               [AuthController::class, 'login']);
        Route::post('refresh',             [AuthController::class, 'refresh']);
        Route::post('forgot-password',     [AuthController::class, 'forgotPassword']);
        Route::post('reset-password',      [AuthController::class, 'resetPassword']);
        Route::get('verify-email/{token}', [AuthController::class, 'verificarEmail']);
    });

    // Catálogos (sin auth)
    Route::prefix('catalogos')->group(function () {
        Route::get('departamentos', [CatalogoController::class, 'departamentos']);
        Route::get('municipios',    [CatalogoController::class, 'municipios']);
        Route::get('habilidades',   [CatalogoController::class, 'habilidades']);
        Route::get('intereses',     [CatalogoController::class, 'intereses']);
        Route::get('areas-impacto', [CatalogoController::class, 'areasImpacto']);
    });

    // Publicaciones y fundaciones públicas (lectura)
    Route::get('publicaciones',             [PublicacionController::class, 'index']);
    Route::get('publicaciones/{publicacion}', [PublicacionController::class, 'show']);
    Route::get('fundaciones',               [FundacionController::class, 'index']);
    Route::get('fundaciones/{fundacion}',   [FundacionController::class, 'show']);

    // Ranking público (opcional auth para mostrar posición propia)
    Route::get('ranking', [GamificacionController::class, 'ranking']);

    // ── Rutas protegidas con JWT ──────────────────────────────
    Route::middleware('auth:api')->group(function () {

        // Auth
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::post('auth/revoke-refresh', [AuthController::class, 'revokeRefresh']);
        Route::get('auth/me',      [AuthController::class, 'me']);

        // ── Voluntario ────────────────────────────────────────
        Route::middleware('role:VOLUNTARIO')->group(function () {
            Route::prefix('voluntario')->group(function () {
                Route::get('/',       [VoluntarioController::class, 'show']);
                Route::post('/',      [VoluntarioController::class, 'store']);
                Route::put('/',       [VoluntarioController::class, 'update']);
                Route::get('dashboard', [VoluntarioController::class, 'dashboard']);
                Route::get('puntos',  [GamificacionController::class, 'misPuntos']);
                Route::get('logros',  [GamificacionController::class, 'misLogros']);

                Route::get('favoritos',     [FavoritoController::class, 'index']);
                Route::get('favoritos/ids', [FavoritoController::class, 'ids']);
                Route::post('favoritos/publicacion/{publicacion}', [FavoritoController::class, 'togglePublicacion']);
                Route::post('favoritos/fundacion/{fundacion}',     [FavoritoController::class, 'toggleFundacion']);
                Route::delete('favoritos/{favorito}',              [FavoritoController::class, 'destroy']);
            });

            Route::post('postulaciones',                        [PostulacionController::class, 'store']);
            Route::get('mis-postulaciones',                     [PostulacionController::class, 'misPostulaciones']);
            Route::post('postulaciones/{postulacion}/retirar',  [PostulacionController::class, 'retirar']);
        });

        // ── Fundación ─────────────────────────────────────────
        Route::middleware('role:FUNDACION')->group(function () {
            Route::get('mi-fundacion',            [FundacionController::class, 'miPerfil']);
            Route::post('fundaciones',            [FundacionController::class, 'store']);
            Route::put('fundaciones/{fundacion}', [FundacionController::class, 'update']);

            Route::post('publicaciones',                        [PublicacionController::class, 'store']);
            Route::put('publicaciones/{publicacion}',           [PublicacionController::class, 'update']);
            Route::post('publicaciones/{publicacion}/publicar', [PublicacionController::class, 'publicar']);
            Route::post('publicaciones/{publicacion}/cancelar', [PublicacionController::class, 'cancelar']);
            Route::post('publicaciones/{publicacion}/imagenes', [PublicacionController::class, 'subirImagenes']);
            Route::delete('publicaciones/{publicacion}/imagenes/{imagen}', [PublicacionController::class, 'eliminarImagen']);
            Route::get('mis-publicaciones',                     [PublicacionController::class, 'misFundacion']);

            Route::put('postulaciones/{postulacion}/responder',              [PostulacionController::class, 'responder']);
            Route::post('postulaciones/{postulacion}/confirmar-asistencia',  [PostulacionController::class, 'confirmarAsistencia']);
            Route::get('publicaciones/{publicacionId}/postulaciones',        [PostulacionController::class, 'postulacionesDeFundacion']);
        });

        // ── Notificaciones (cualquier usuario autenticado) ────
        Route::prefix('notificaciones')->group(function () {
            Route::get('/',                           [NotificacionController::class, 'index']);
            Route::get('no-leidas',                   [NotificacionController::class, 'noLeidas']);
            Route::post('marcar-todas-leidas',        [NotificacionController::class, 'marcarTodasLeidas']);
            Route::put('{notificacion}/marcar-leida', [NotificacionController::class, 'marcarLeida']);
        });

        // Reportes (cualquier usuario autenticado)
        Route::post('reportes', [AdminReporteController::class, 'store']);

        // ── Admin ─────────────────────────────────────────────
        Route::prefix('admin')->middleware('role:ADMIN')->group(function () {
            // Publicaciones pendientes de aprobación
            Route::get('publicaciones',                             [AdminPublicacionController::class, 'index']);
            Route::put('publicaciones/{publicacion}/aprobar',       [AdminPublicacionController::class, 'aprobar']);
            Route::put('publicaciones/{publicacion}/rechazar',      [AdminPublicacionController::class, 'rechazar']);

            // Fundaciones
            Route::get('fundaciones',                             [AdminFundacionController::class, 'index']);
            Route::get('fundaciones/{fundacion}',                 [AdminFundacionController::class, 'show']);
            Route::put('fundaciones/{fundacion}/aprobar',         [AdminFundacionController::class, 'aprobar']);
            Route::put('fundaciones/{fundacion}/rechazar',        [AdminFundacionController::class, 'rechazar']);
            Route::put('fundaciones/{fundacion}/suspender',       [AdminFundacionController::class, 'suspender']);
            Route::put('fundaciones/{fundacion}/reactivar',       [AdminFundacionController::class, 'reactivar']);
            Route::get('fundaciones/{fundacion}/historial',       [AdminFundacionController::class, 'historial']);
            Route::get('fundaciones/{fundacion}/documentos',      [AdminFundacionController::class, 'documentos']);
            Route::post('fundaciones/{fundacion}/documentos',     [AdminFundacionController::class, 'subirDocumento']);

            // Voluntarios
            Route::get('voluntarios',                             [AdminVoluntarioController::class, 'index']);
            Route::get('voluntarios/{voluntario}',                [AdminVoluntarioController::class, 'show']);
            Route::put('voluntarios/{voluntario}/suspender',      [AdminVoluntarioController::class, 'suspender']);
            Route::put('voluntarios/{voluntario}/bloquear',       [AdminVoluntarioController::class, 'bloquear']);
            Route::put('voluntarios/{voluntario}/reactivar',      [AdminVoluntarioController::class, 'reactivar']);
            Route::post('voluntarios/{voluntario}/advertencias',  [AdminVoluntarioController::class, 'advertencia']);
            Route::get('voluntarios/{voluntario}/historial',      [AdminVoluntarioController::class, 'historial']);

            // Reportes
            Route::get('reportes/dashboard',                [AdminReporteController::class, 'dashboard']);
            Route::get('reportes',                          [AdminReporteController::class, 'index']);
            Route::put('reportes/{reporte}/resolver',       [AdminReporteController::class, 'resolver']);
        });
    });
});

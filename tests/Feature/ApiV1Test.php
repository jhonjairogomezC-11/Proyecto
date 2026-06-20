<?php

use App\Models\AreaImpacto;
use App\Models\Departamento;
use App\Models\Fundacion;
use App\Models\Municipio;
use App\Models\Postulacion;
use App\Models\Publicacion;
use App\Models\Usuario;
use App\Models\Voluntario;
use App\Enums\EstadoUsuario;
use App\Enums\EstadoVerificacion;
use App\Enums\EstadoPublicacion;
use App\Enums\EstadoPostulacion;
use App\Enums\RolUsuario;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use PHPOpenSourceSaver\JWTAuth\Facades\JWTAuth;

uses(RefreshDatabase::class);

/**
 * Helper: autentica con JWT guard para pruebas.
 */
function jwtActingAs(Usuario $usuario): void
{
    test()->actingAs($usuario, 'api');
}

beforeEach(function () {
    $this->seed(\Database\Seeders\CatalogosSeeder::class);
    $this->seed(\Database\Seeders\AdminSeeder::class);
});

// ─────────────────────────────────────────────────────────────
// 1. CATÁLOGOS
// ─────────────────────────────────────────────────────────────
test('se pueden listar departamentos de forma pública', function () {
    $this->getJson('/api/v1/catalogos/departamentos')
         ->assertStatus(200)
         ->assertJsonStructure([['id', 'nombre']]);
});

test('se pueden listar municipios filtrados por departamento', function () {
    $departamento = Departamento::first();
    $this->getJson("/api/v1/catalogos/municipios?departamento_id={$departamento->id}")
         ->assertStatus(200)
         ->assertJsonStructure([['id', 'nombre', 'departamento']]);
});

test('solo se retornan departamentos de Bogota y Cundinamarca', function () {
    $response = $this->getJson('/api/v1/catalogos/departamentos');
    $nombres  = collect($response->json())->pluck('nombre')->toArray();

    expect($nombres)->toContain('Bogotá D.C.')
                    ->toContain('Cundinamarca')
                    ->toHaveCount(2);
});

// ─────────────────────────────────────────────────────────────
// 2. AUTENTICACIÓN — JWT
// ─────────────────────────────────────────────────────────────
test('un usuario se puede registrar como voluntario', function () {
    $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Juan Pérez',
        'email'                 => 'juan@example.com',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'VOLUNTARIO',
        'telefono'              => '3001234567',
    ])->assertStatus(201)
      ->assertJsonStructure(['usuario', 'token', 'refresh_token', 'token_type', 'expires_in']);
});

test('un usuario se puede registrar como fundacion', function () {
    $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Fundación Esperanza',
        'email'                 => 'contacto@esperanza.org',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'FUNDACION',
    ])->assertStatus(201)
      ->assertJsonStructure(['usuario', 'token', 'refresh_token']);
});

test('un usuario no puede registrarse con un email existente', function () {
    Usuario::factory()->create(['email' => 'duplicado@example.com']);

    $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Otro',
        'email'                 => 'duplicado@example.com',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'VOLUNTARIO',
    ])->assertStatus(422)
      ->assertJsonValidationErrors(['email']);
});

test('un usuario puede hacer login con credenciales correctas', function () {
    Usuario::factory()->create([
        'email'         => 'login@example.com',
        'password_hash' => Hash::make('password'),
    ]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => 'login@example.com',
        'password' => 'password',
    ])->assertStatus(200)
      ->assertJsonStructure(['usuario', 'token', 'refresh_token', 'expires_in']);
});

test('un usuario no puede hacer login con credenciales incorrectas', function () {
    Usuario::factory()->create([
        'email'         => 'login@example.com',
        'password_hash' => Hash::make('password'),
    ]);

    $this->postJson('/api/v1/auth/login', [
        'email'    => 'login@example.com',
        'password' => 'incorrecta',
    ])->assertStatus(422)
      ->assertJsonValidationErrors(['email']);
});

test('un usuario autenticado puede consultar su propio perfil', function () {
    $usuario = Usuario::factory()->create();

    $this->actingAs($usuario, 'api')
         ->getJson('/api/v1/auth/me')
         ->assertStatus(200)
         ->assertJsonPath('email', $usuario->email);
});

test('un usuario puede cerrar sesion correctamente', function () {
    $usuario = Usuario::factory()->create();

    $this->actingAs($usuario, 'api')
         ->postJson('/api/v1/auth/logout')
         ->assertStatus(200)
         ->assertJsonPath('message', 'Sesión cerrada correctamente.');
});

// ─────────────────────────────────────────────────────────────
// 3. PERFIL VOLUNTARIO
// ─────────────────────────────────────────────────────────────
test('un usuario con rol voluntario puede crear su perfil de voluntario', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $municipio = Municipio::first();

    $this->actingAs($usuario, 'api')
         ->postJson('/api/v1/voluntario', [
             'tipo_documento'   => 'CC',
             'numero_documento' => '12345678',
             'fecha_nacimiento' => '1995-10-10',
             'genero'           => 'MASCULINO',
             'municipio_id'     => $municipio->id,
             'disponibilidad'   => 'ENTRE_SEMANA',
         ])->assertStatus(201)
           ->assertJsonStructure(['id', 'tipo_documento', 'numero_documento']);
});

test('una fundacion no puede crear un perfil de voluntario', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::FUNDACION]);
    $municipio = Municipio::first();

    $this->actingAs($usuario, 'api')
         ->postJson('/api/v1/voluntario', [
             'tipo_documento'   => 'CC',
             'numero_documento' => '99999999',
             'fecha_nacimiento' => '1990-01-01',
             'genero'           => 'MASCULINO',
             'municipio_id'     => $municipio->id,
             'disponibilidad'   => 'FLEXIBLE',
         ])->assertStatus(403);
});

test('un voluntario puede actualizar su perfil', function () {
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($voluntario->usuario, 'api')
         ->putJson('/api/v1/voluntario', [
             'disponibilidad' => 'FLEXIBLE',
             'experiencia'    => 'Experiencia actualizada.',
         ])->assertStatus(200)
           ->assertJsonPath('disponibilidad', 'FLEXIBLE');
});

// ─────────────────────────────────────────────────────────────
// 4. PERFIL FUNDACIÓN
// ─────────────────────────────────────────────────────────────
test('un usuario con rol fundacion puede crear su perfil de fundacion', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::FUNDACION]);
    $municipio = Municipio::first();

    $this->actingAs($usuario, 'api')
         ->postJson('/api/v1/fundaciones', [
             'nombre'              => 'Fundación Por la Vida',
             'nit'                 => '123456789-0',
             'representante_legal' => 'Gabriel García',
             'telefono'            => '3009876543',
             'direccion'           => 'Calle 100 #15-30',
             'municipio_id'        => $municipio->id,
             'descripcion'         => 'Ayudamos a personas vulnerables.',
             'documento_legal'     => 'rut.pdf',
         ])->assertStatus(201)
           ->assertJsonStructure(['id', 'nombre', 'nit', 'estado_verificacion']);
});

test('un voluntario no puede crear un perfil de fundacion', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $municipio = Municipio::first();

    $this->actingAs($usuario, 'api')
         ->postJson('/api/v1/fundaciones', [
             'nombre'              => 'Fundación Falsa',
             'nit'                 => '123456789-0',
             'representante_legal' => 'Nadie',
             'telefono'            => '3000000000',
             'direccion'           => 'Calle Falsa',
             'municipio_id'        => $municipio->id,
             'descripcion'         => 'Descripción.',
             'documento_legal'     => 'doc.pdf',
         ])->assertStatus(403);
});

test('una fundacion aprobada puede actualizar su perfil', function () {
    $fundacion = Fundacion::factory()->create();

    $this->actingAs($fundacion->usuario, 'api')
         ->putJson("/api/v1/fundaciones/{$fundacion->id}", [
             'representante_legal' => 'Nuevo Representante',
             'telefono'            => '3001112222',
         ])->assertStatus(200)
           ->assertJsonPath('representante_legal', 'Nuevo Representante');
});

// ─────────────────────────────────────────────────────────────
// 5. PUBLICACIONES
// ─────────────────────────────────────────────────────────────
test('una fundacion aprobada puede crear una publicacion en borrador', function () {
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $categoria = AreaImpacto::first();
    $municipio = Municipio::first();

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson('/api/v1/publicaciones', [
             'titulo'       => 'Siembra de Árboles',
             'descripcion'  => 'Actividad de reforestación.',
             'categoria_id' => $categoria->id,
             'modalidad'    => 'PRESENCIAL',
             'municipio_id' => $municipio->id,
             'fecha_inicio' => '2026-07-01',
             'fecha_fin'    => '2026-07-02',
             'cupo_maximo'  => 20,
         ])->assertStatus(201)
           ->assertJsonPath('estado', 'BORRADOR');
});

test('una fundacion pendiente NO puede crear una publicacion', function () {
    $fundacion = Fundacion::factory()->pendiente()->create();
    $categoria = AreaImpacto::first();

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson('/api/v1/publicaciones', [
             'titulo'       => 'Convocatoria Denegada',
             'descripcion'  => 'No debería crearse.',
             'categoria_id' => $categoria->id,
             'modalidad'    => 'VIRTUAL',
             'fecha_inicio' => '2026-07-01',
             'fecha_fin'    => '2026-07-02',
             'cupo_maximo'  => 10,
         ])->assertStatus(422)
           ->assertJsonValidationErrors(['fundacion']);
});

test('una fundacion puede enviar una convocatoria a revision', function () {
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => \App\Enums\EstadoPublicacion::BORRADOR,
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/publicaciones/{$publicacion->id}/publicar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'PENDIENTE_APROBACION');
});

test('admin puede aprobar una publicacion pendiente', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => \App\Enums\EstadoPublicacion::PENDIENTE_APROBACION,
    ]);

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/publicaciones/{$publicacion->id}/aprobar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'PUBLICADA');
});

test('admin puede rechazar una publicacion pendiente', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => \App\Enums\EstadoPublicacion::PENDIENTE_APROBACION,
    ]);

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/publicaciones/{$publicacion->id}/rechazar", [
             'motivo' => 'El contenido no cumple con las políticas de la plataforma.',
         ])->assertStatus(200)
           ->assertJsonPath('estado', 'BORRADOR');
});

test('una fundacion puede cancelar una convocatoria', function () {
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::PUBLICADA,
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/publicaciones/{$publicacion->id}/cancelar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'CANCELADA');
});

// ─────────────────────────────────────────────────────────────
// 6. POSTULACIONES — incluye correcciones Sprint 1
// ─────────────────────────────────────────────────────────────
test('un voluntario puede postularse a una publicacion activa', function () {
    $voluntario  = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create(['estado' => EstadoPublicacion::PUBLICADA]);

    $this->actingAs($voluntario->usuario, 'api')
         ->postJson('/api/v1/postulaciones', [
             'publicacion_id'     => $publicacion->id,
             'mensaje_voluntario' => 'Me interesa la causa.',
         ])->assertStatus(201)
           ->assertJsonPath('estado', 'PENDIENTE');
});

test('un voluntario NO puede postularse a una convocatoria CERRADA', function () {
    $voluntario  = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create(['estado' => EstadoPublicacion::CERRADA]);

    $this->actingAs($voluntario->usuario, 'api')
         ->postJson('/api/v1/postulaciones', [
             'publicacion_id' => $publicacion->id,
         ])->assertStatus(422);
});

test('una fundacion puede aceptar una postulacion y cerrar el cupo', function () {
    $voluntario  = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create();
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::PUBLICADA,
        'cupo_maximo'  => 1,
    ]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => EstadoPostulacion::PENDIENTE,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->putJson("/api/v1/postulaciones/{$postulacion->id}/responder", ['estado' => 'ACEPTADO'])
         ->assertStatus(200)
         ->assertJsonPath('estado', 'ACEPTADO');

    expect($publicacion->fresh()->estado)->toBe(EstadoPublicacion::CERRADA);
});

test('un voluntario puede retirar su postulacion', function () {
    $voluntario  = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create(['estado' => EstadoPublicacion::PUBLICADA]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => EstadoPostulacion::PENDIENTE,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($voluntario->usuario, 'api')
         ->postJson("/api/v1/postulaciones/{$postulacion->id}/retirar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'RETIRADO');
});

test('al retirar una postulacion ACEPTADA la convocatoria CERRADA vuelve a PUBLICADA', function () {
    $voluntario  = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create();
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::CERRADA,
        'cupo_maximo'  => 1,
    ]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => EstadoPostulacion::ACEPTADO,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($voluntario->usuario, 'api')
         ->postJson("/api/v1/postulaciones/{$postulacion->id}/retirar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'RETIRADO');

    expect($publicacion->fresh()->estado)->toBe(EstadoPublicacion::PUBLICADA);
});

test('un voluntario puede volver a postularse tras retirarse', function () {
    $voluntario  = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create(['estado' => EstadoPublicacion::PUBLICADA]);

    // Primera postulación → retirar
    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => EstadoPostulacion::RETIRADO,
        'fecha_actualizacion' => now(),
    ]);

    // Segunda postulación debe funcionar
    $this->actingAs($voluntario->usuario, 'api')
         ->postJson('/api/v1/postulaciones', [
             'publicacion_id' => $publicacion->id,
         ])->assertStatus(201)
           ->assertJsonPath('estado', 'PENDIENTE');
});

test('una fundacion puede registrar asistencia y calificacion', function () {
    $voluntario  = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create();
    $publicacion = Publicacion::factory()->create(['fundacion_id' => $fundacion->id]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => EstadoPostulacion::ACEPTADO,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/postulaciones/{$postulacion->id}/confirmar-asistencia", [
             'asistio'              => true,
             'calificacion'         => 5,
             'comentario_fundacion' => 'Excelente voluntario.',
         ])->assertStatus(200)
           ->assertJsonPath('estado', 'ASISTIO')
           ->assertJsonPath('calificacion', 5);
});

// ─────────────────────────────────────────────────────────────
// 7. NOTIFICACIONES
// ─────────────────────────────────────────────────────────────
test('un usuario puede ver sus notificaciones', function () {
    $usuario = Usuario::factory()->create();
    \App\Models\Notificacion::create([
        'usuario_id' => $usuario->id,
        'tipo'       => 'RECORDATORIO_ACTIVIDAD',
        'mensaje'    => 'Tienes un evento mañana.',
    ]);

    $this->actingAs($usuario, 'api')
         ->getJson('/api/v1/notificaciones')
         ->assertStatus(200)
         ->assertJsonStructure(['data', 'links', 'meta']);
});

// ─────────────────────────────────────────────────────────────
// 8. PANEL ADMIN
// ─────────────────────────────────────────────────────────────
test('un administrador puede aprobar una fundacion pendiente', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->pendiente()->create();

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/aprobar")
         ->assertStatus(200)
         ->assertJsonPath('estado_verificacion', 'APROBADA');
});

test('un voluntario no puede gestionar fundaciones en el panel admin', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $fundacion = Fundacion::factory()->pendiente()->create();

    $this->actingAs($usuario, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/aprobar")
         ->assertStatus(403);
});

// ─────────────────────────────────────────────────────────────
// 9. SPRINT 2 — Gestión admin fundaciones
// ─────────────────────────────────────────────────────────────
test('admin puede rechazar una fundacion con motivo', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->pendiente()->create();

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/rechazar", [
             'motivo' => 'Documentación incompleta y datos inconsistentes.',
         ])->assertStatus(200)
           ->assertJsonPath('estado_verificacion', 'RECHAZADA');
});

test('admin puede suspender una fundacion aprobada', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => \App\Enums\EstadoVerificacion::APROBADA]);

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/suspender", [
             'motivo' => 'Incumplimiento de normas de la plataforma.',
         ])->assertStatus(200)
           ->assertJsonPath('estado_verificacion', 'SUSPENDIDA');
});

test('admin puede reactivar una fundacion suspendida', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => \App\Enums\EstadoVerificacion::SUSPENDIDA]);

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/reactivar")
         ->assertStatus(200)
         ->assertJsonPath('estado_verificacion', 'APROBADA');
});

test('admin puede ver historial de estados de una fundacion', function () {
    $admin     = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->pendiente()->create();

    // Aprobar para generar historial
    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/aprobar");

    $this->actingAs($admin, 'api')
         ->getJson("/api/v1/admin/fundaciones/{$fundacion->id}/historial")
         ->assertStatus(200)
         ->assertJsonStructure([['id', 'estado_anterior', 'estado_nuevo', 'fecha']]);
});

// ─────────────────────────────────────────────────────────────
// 10. SPRINT 2 — Gestión admin voluntarios
// ─────────────────────────────────────────────────────────────
test('admin puede ver lista de voluntarios', function () {
    $admin = Usuario::where('rol', RolUsuario::ADMIN)->first();
    Voluntario::factory()->create();

    $this->actingAs($admin, 'api')
         ->getJson('/api/v1/admin/voluntarios')
         ->assertStatus(200)
         ->assertJsonStructure(['data', 'meta']);
});

test('admin puede ver perfil completo de un voluntario', function () {
    $admin      = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($admin, 'api')
         ->getJson("/api/v1/admin/voluntarios/{$voluntario->id}")
         ->assertStatus(200)
         ->assertJsonStructure(['id', 'usuario', 'total_participaciones', 'calificacion_promedio']);
});

test('admin puede suspender un voluntario', function () {
    $admin      = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/voluntarios/{$voluntario->id}/suspender", [
             'motivo'        => 'Comportamiento inadecuado reportado.',
             'duracion_dias' => 7,
         ])->assertStatus(200);

    expect($voluntario->fresh()->usuario->estado->value)->toBe('SUSPENDIDO');
});

test('admin puede bloquear un voluntario', function () {
    $admin      = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/voluntarios/{$voluntario->id}/bloquear", [
             'motivo' => 'Múltiples incumplimientos graves.',
         ])->assertStatus(200);

    expect($voluntario->fresh()->usuario->estado->value)->toBe('BLOQUEADO');
});

test('admin puede reactivar un voluntario suspendido', function () {
    $admin      = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $voluntario = Voluntario::factory()->create();
    $voluntario->usuario()->update(['estado' => \App\Enums\EstadoUsuario::SUSPENDIDO]);

    $this->actingAs($admin, 'api')
         ->putJson("/api/v1/admin/voluntarios/{$voluntario->id}/reactivar")
         ->assertStatus(200);

    expect($voluntario->fresh()->usuario->estado->value)->toBe('ACTIVO');
});

test('admin puede emitir una advertencia a un voluntario', function () {
    $admin      = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($admin, 'api')
         ->postJson("/api/v1/admin/voluntarios/{$voluntario->id}/advertencias", [
             'motivo' => 'Primera advertencia por comportamiento inadecuado.',
         ])->assertStatus(201)
           ->assertJsonStructure(['message', 'advertencia', 'total_activas'])
           ->assertJsonPath('total_activas', 1);
});

test('voluntario suspendido no puede postularse', function () {
    $voluntario = Voluntario::factory()->create();
    $voluntario->usuario()->update(['estado' => \App\Enums\EstadoUsuario::SUSPENDIDO]);
    $publicacion = Publicacion::factory()->create(['estado' => \App\Enums\EstadoPublicacion::PUBLICADA]);

    // El middleware de auth bloqueará al usuario suspendido
    $this->actingAs($voluntario->usuario, 'api')
         ->postJson('/api/v1/postulaciones', [
             'publicacion_id' => $publicacion->id,
         ])->assertStatus(403);
});

// ─────────────────────────────────────────────────────────────
// 11. SPRINT 3 — Gamificación: puntos, ranking y logros
// ─────────────────────────────────────────────────────────────
test('el ranking es publico y retorna top 10', function () {
    $this->getJson('/api/v1/ranking?top=10')
         ->assertStatus(200)
         ->assertJsonStructure(['top', 'total']);
});

test('voluntario recibe puntos al confirmar asistencia', function () {
    $voluntario  = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => \App\Enums\EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => \App\Enums\EstadoPublicacion::PUBLICADA,
        'fecha_inicio' => now()->addDays(1)->format('Y-m-d'),
        'fecha_fin'    => now()->addDays(3)->format('Y-m-d'),
    ]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => \App\Enums\EstadoPostulacion::ACEPTADO,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/postulaciones/{$postulacion->id}/confirmar-asistencia", [
             'asistio'      => true,
             'calificacion' => 5,
         ])->assertStatus(200)
           ->assertJsonPath('estado', 'ASISTIO');

    // Verificar que se creó saldo de puntos
    $puntos = \App\Models\VoluntarioPuntos::where('voluntario_id', $voluntario->id)->first();
    expect($puntos)->not->toBeNull();
    expect($puntos->total_historico)->toBeGreaterThan(0);
});

test('voluntario puede consultar sus puntos', function () {
    $voluntario = Voluntario::factory()->create();
    \App\Models\VoluntarioPuntos::create([
        'voluntario_id'  => $voluntario->id,
        'saldo'          => 25,
        'total_historico'=> 25,
    ]);

    $this->actingAs($voluntario->usuario, 'api')
         ->getJson('/api/v1/voluntario/puntos')
         ->assertStatus(200)
         ->assertJsonStructure(['saldo', 'total_historico', 'transacciones']);
});

test('voluntario puede consultar sus logros', function () {
    $voluntario = Voluntario::factory()->create();

    $this->actingAs($voluntario->usuario, 'api')
         ->getJson('/api/v1/voluntario/logros')
         ->assertStatus(200)
         ->assertJsonStructure(['obtenidos', 'pendientes']);
});

test('se otorga logro Primer Paso tras primera participacion', function () {
    $voluntario  = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => \App\Enums\EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => \App\Enums\EstadoPublicacion::PUBLICADA,
        'fecha_inicio' => now()->addDays(1)->format('Y-m-d'),
        'fecha_fin'    => now()->addDays(2)->format('Y-m-d'),
    ]);

    $postulacion = Postulacion::create([
        'publicacion_id'      => $publicacion->id,
        'voluntario_id'       => $voluntario->id,
        'estado'              => \App\Enums\EstadoPostulacion::ACEPTADO,
        'fecha_actualizacion' => now(),
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/postulaciones/{$postulacion->id}/confirmar-asistencia", [
             'asistio' => true, 'calificacion' => 4,
         ])->assertStatus(200);

    $tieneLogro = \App\Models\VoluntarioLogro::where('voluntario_id', $voluntario->id)
        ->whereHas('logro', fn ($q) => $q->where('codigo', 'PRIMER_PASO'))
        ->exists();

    expect($tieneLogro)->toBeTrue();
});

test('publicacion con dificultad MUY_DIFICIL otorga mas puntos que FACIL', function () {
    $voluntario1 = Voluntario::factory()->create();
    $voluntario2 = Voluntario::factory()->create();
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => \App\Enums\EstadoVerificacion::APROBADA]);

    $pubFacil = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id, 'estado' => \App\Enums\EstadoPublicacion::PUBLICADA,
        'dificultad' => 'FACIL', 'fecha_inicio' => now()->addDays(1)->format('Y-m-d'), 'fecha_fin' => now()->addDays(1)->format('Y-m-d'),
    ]);
    $pubDificil = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id, 'estado' => \App\Enums\EstadoPublicacion::PUBLICADA,
        'dificultad' => 'MUY_DIFICIL', 'fecha_inicio' => now()->addDays(1)->format('Y-m-d'), 'fecha_fin' => now()->addDays(1)->format('Y-m-d'),
    ]);

    $p1 = Postulacion::create(['publicacion_id' => $pubFacil->id,   'voluntario_id' => $voluntario1->id, 'estado' => \App\Enums\EstadoPostulacion::ACEPTADO, 'fecha_actualizacion' => now()]);
    $p2 = Postulacion::create(['publicacion_id' => $pubDificil->id, 'voluntario_id' => $voluntario2->id, 'estado' => \App\Enums\EstadoPostulacion::ACEPTADO, 'fecha_actualizacion' => now()]);

    $this->actingAs($fundacion->usuario, 'api')->postJson("/api/v1/postulaciones/{$p1->id}/confirmar-asistencia", ['asistio' => true, 'calificacion' => 5]);
    $this->actingAs($fundacion->usuario, 'api')->postJson("/api/v1/postulaciones/{$p2->id}/confirmar-asistencia", ['asistio' => true, 'calificacion' => 5]);

    $puntosFacil   = \App\Models\VoluntarioPuntos::where('voluntario_id', $voluntario1->id)->value('total_historico');
    $puntosDificil = \App\Models\VoluntarioPuntos::where('voluntario_id', $voluntario2->id)->value('total_historico');

    expect($puntosDificil)->toBeGreaterThan($puntosFacil);
});

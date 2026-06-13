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

test('una fundacion puede publicar una convocatoria en borrador', function () {
    $fundacion   = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::BORRADOR,
    ]);

    $this->actingAs($fundacion->usuario, 'api')
         ->postJson("/api/v1/publicaciones/{$publicacion->id}/publicar")
         ->assertStatus(200)
         ->assertJsonPath('estado', 'PUBLICADA');
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
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/gestionar", [
             'estado' => 'APROBADA',
         ])->assertStatus(200)
           ->assertJsonPath('estado_verificacion', 'APROBADA');
});

test('un voluntario no puede gestionar fundaciones en el panel admin', function () {
    $usuario   = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $fundacion = Fundacion::factory()->pendiente()->create();

    $this->actingAs($usuario, 'api')
         ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/gestionar", [
             'estado' => 'APROBADA',
         ])->assertStatus(403);
});

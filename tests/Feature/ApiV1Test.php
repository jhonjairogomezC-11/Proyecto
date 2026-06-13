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

uses(RefreshDatabase::class);

beforeEach(function () {
    // Sembrar catálogos necesarios para los registros y pruebas
    $this->seed(\Database\Seeders\CatalogosSeeder::class);
    $this->seed(\Database\Seeders\AdminSeeder::class);
});

/*
|--------------------------------------------------------------------------
| 1. Pruebas de Catálogos
|--------------------------------------------------------------------------
*/
test('se pueden listar departamentos de forma pública', function () {
    $response = $this->getJson('/api/v1/catalogos/departamentos');

    $response->assertStatus(200)
             ->assertJsonStructure([['id', 'nombre']]);
});

test('se pueden listar municipios filtrados por departamento', function () {
    $departamento = Departamento::first();
    $response = $this->getJson("/api/v1/catalogos/municipios?departamento_id={$departamento->id}");

    $response->assertStatus(200)
             ->assertJsonStructure([['id', 'nombre', 'departamento']]);
});

/*
|--------------------------------------------------------------------------
| 2. Pruebas de Autenticación
|--------------------------------------------------------------------------
*/
test('un usuario se puede registrar como voluntario', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Juan Pérez',
        'email'                 => 'juan@example.com',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'VOLUNTARIO',
        'telefono'              => '3001234567',
    ]);

    $response->assertStatus(201)
             ->assertJsonStructure(['usuario', 'token']);
});

test('un usuario se puede registrar como fundacion', function () {
    $response = $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Fundación Esperanza',
        'email'                 => 'contacto@esperanza.org',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'FUNDACION',
        'telefono'              => '3001234567',
    ]);

    $response->assertStatus(201)
             ->assertJsonStructure(['usuario', 'token']);
});

test('un usuario no puede registrarse con un email existente', function () {
    Usuario::factory()->create(['email' => 'duplicado@example.com']);

    $response = $this->postJson('/api/v1/auth/register', [
        'nombre'                => 'Otro Usuario',
        'email'                 => 'duplicado@example.com',
        'password'              => 'Password123!',
        'password_confirmation' => 'Password123!',
        'rol'                   => 'VOLUNTARIO',
        'telefono'              => '3001234567',
    ]);

    $response->assertStatus(422)
             ->assertJsonValidationErrors(['email']);
});

test('un usuario puede hacer login con credenciales correctas', function () {
    $usuario = Usuario::factory()->create([
        'email'         => 'login@example.com',
        'password_hash' => Hash::make('password'),
    ]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email'    => 'login@example.com',
        'password' => 'password',
    ]);

    $response->assertStatus(200)
             ->assertJsonStructure(['usuario', 'token']);
});

test('un usuario no puede hacer login con credenciales incorrectas', function () {
    Usuario::factory()->create([
        'email'         => 'login@example.com',
        'password_hash' => Hash::make('password'),
    ]);

    $response = $this->postJson('/api/v1/auth/login', [
        'email'    => 'login@example.com',
        'password' => 'incorrecta',
    ]);

    $response->assertStatus(422)
             ->assertJsonValidationErrors(['email']);
});

test('un usuario autenticado puede consultar su propio perfil de usuario', function () {
    $usuario = Usuario::factory()->create();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->getJson('/api/v1/auth/me');

    $response->assertStatus(200)
             ->assertJsonPath('email', $usuario->email);
});

test('un usuario puede cerrar sesión correctamente', function () {
    $usuario = Usuario::factory()->create();
    // Creamos un token real para que currentAccessToken() no sea null
    $token = $usuario->createToken('api');

    $response = $this->withToken($token->plainTextToken)
                     ->postJson('/api/v1/auth/logout');

    $response->assertStatus(200)
             ->assertJsonPath('message', 'Sesión cerrada correctamente.');
});

/*
|--------------------------------------------------------------------------
| 3. Pruebas de Perfil de Voluntario
|--------------------------------------------------------------------------
*/
test('un usuario con rol voluntario puede crear su perfil de voluntario', function () {
    $usuario = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $municipio = Municipio::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/voluntario', [
                         'tipo_documento'   => 'CC',
                         'numero_documento' => '12345678',
                         'fecha_nacimiento' => '1995-10-10',
                         'genero'           => 'MASCULINO',
                         'municipio_id'     => $municipio->id,
                         'disponibilidad'   => 'ENTRE_SEMANA',
                         'experiencia'      => 'He participado en otros eventos.',
                     ]);

    $response->assertStatus(201)
             ->assertJsonStructure(['id', 'tipo_documento', 'numero_documento']);
});

test('una fundacion no puede crear un perfil de voluntario', function () {
    $usuario = Usuario::factory()->create(['rol' => RolUsuario::FUNDACION]);
    $municipio = Municipio::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/voluntario', [
                         'tipo_documento'   => 'CC',
                         'numero_documento' => '12345678',
                         'fecha_nacimiento' => '1995-10-10',
                         'genero'           => 'MASCULINO',
                         'municipio_id'     => $municipio->id,
                         'disponibilidad'   => 'ENTRE_SEMANA',
                     ]);

    $response->assertStatus(403);
});

test('un voluntario puede actualizar su perfil', function () {
    $voluntario = Voluntario::factory()->create();
    $usuario = $voluntario->usuario;

    $response = $this->actingAs($usuario, 'sanctum')
                     ->putJson('/api/v1/voluntario', [
                         'disponibilidad' => 'FLEXIBLE',
                         'experiencia'    => 'Actualizada.',
                     ]);

    $response->assertStatus(200)
             ->assertJsonPath('disponibilidad', 'FLEXIBLE')
             ->assertJsonPath('experiencia', 'Actualizada.');
});

/*
|--------------------------------------------------------------------------
| 4. Pruebas de Perfil de Fundación
|--------------------------------------------------------------------------
*/
test('un usuario con rol fundacion puede crear su perfil de fundacion', function () {
    $usuario = Usuario::factory()->create(['rol' => RolUsuario::FUNDACION]);
    $municipio = Municipio::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/fundaciones', [
                         'nombre'              => 'Fundación Por la Vida',
                         'nit'                 => '123456789-0',
                         'representante_legal' => 'Gabriel García',
                         'telefono'            => '3009876543',
                         'direccion'           => 'Calle 100 #15-30',
                         'municipio_id'        => $municipio->id,
                         'descripcion'         => 'Ayudamos a personas de escasos recursos.',
                         'documento_legal'     => 'rut.pdf',
                     ]);

    $response->assertStatus(201)
             ->assertJsonStructure(['id', 'nombre', 'nit', 'estado_verificacion']);
});

test('un voluntario no puede crear un perfil de fundacion', function () {
    $usuario = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $municipio = Municipio::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/fundaciones', [
                         'nombre'              => 'Fundación Falsa',
                         'nit'                 => '123456789-0',
                         'representante_legal' => 'Gabriel García',
                         'telefono'            => '3009876543',
                         'direccion'           => 'Calle 100 #15-30',
                         'municipio_id'        => $municipio->id,
                         'descripcion'         => 'Ayudamos a personas de escasos recursos.',
                         'documento_legal'     => 'rut.pdf',
                     ]);

    $response->assertStatus(403);
});

test('una fundacion aprobada puede actualizar su perfil', function () {
    $fundacion = Fundacion::factory()->create();
    $usuario = $fundacion->usuario;

    $response = $this->actingAs($usuario, 'sanctum')
                     ->putJson("/api/v1/fundaciones/{$fundacion->id}", [
                         'representante_legal' => 'Nuevo Representante',
                         'telefono'            => '3001112222',
                     ]);

    $response->assertStatus(200)
             ->assertJsonPath('representante_legal', 'Nuevo Representante');
});

/*
|--------------------------------------------------------------------------
| 5. Pruebas de Publicaciones (Convocatorias)
|--------------------------------------------------------------------------
*/
test('una fundacion aprobada puede crear una publicacion en borrador', function () {
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $usuario = $fundacion->usuario;
    $categoria = AreaImpacto::first();
    $municipio = Municipio::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/publicaciones', [
                         'titulo'       => 'Convocatoria Siembra de Árboles',
                         'descripcion'  => 'Siembra de árboles en el parque nacional.',
                         'categoria_id' => $categoria->id,
                         'modalidad'    => 'PRESENCIAL',
                         'municipio_id' => $municipio->id,
                         'fecha_inicio' => '2026-07-01',
                         'fecha_fin'    => '2026-07-02',
                         'cupo_maximo'  => 20,
                     ]);

    $response->assertStatus(201)
             ->assertJsonPath('estado', 'BORRADOR');
});

test('una fundacion pendiente de aprobacion NO puede crear una publicacion', function () {
    $fundacion = Fundacion::factory()->pendiente()->create();
    $usuario = $fundacion->usuario;
    $categoria = AreaImpacto::first();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->postJson('/api/v1/publicaciones', [
                         'titulo'       => 'Convocatoria Denegada',
                         'descripcion'  => 'No debería crearse.',
                         'categoria_id' => $categoria->id,
                         'modalidad'    => 'VIRTUAL',
                         'fecha_inicio' => '2026-07-01',
                         'fecha_fin'    => '2026-07-02',
                         'cupo_maximo'  => 10,
                     ]);

    $response->assertStatus(422)
             ->assertJsonValidationErrors(['fundacion']);
});

test('una fundacion puede publicar una convocatoria en borrador', function () {
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::BORRADOR,
    ]);

    $response = $this->actingAs($fundacion->usuario, 'sanctum')
                     ->postJson("/api/v1/publicaciones/{$publicacion->id}/publicar");

    $response->assertStatus(200)
             ->assertJsonPath('estado', 'PUBLICADA');
});

test('una fundacion puede cancelar una convocatoria', function () {
    $fundacion = Fundacion::factory()->create(['estado_verificacion' => EstadoVerificacion::APROBADA]);
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::PUBLICADA,
    ]);

    $response = $this->actingAs($fundacion->usuario, 'sanctum')
                     ->postJson("/api/v1/publicaciones/{$publicacion->id}/cancelar");

    $response->assertStatus(200)
             ->assertJsonPath('estado', 'CANCELADA');
});

/*
|--------------------------------------------------------------------------
| 6. Pruebas de Postulaciones
|--------------------------------------------------------------------------
*/
test('un voluntario puede postularse a una publicacion activa', function () {
    $voluntario = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create(['estado' => EstadoPublicacion::PUBLICADA]);

    $response = $this->actingAs($voluntario->usuario, 'sanctum')
                     ->postJson('/api/v1/postulaciones', [
                         'publicacion_id'     => $publicacion->id,
                         'mensaje_voluntario' => 'Me interesa la causa.',
                     ]);

    $response->assertStatus(201)
             ->assertJsonPath('estado', 'PENDIENTE');
});

test('una fundacion puede aceptar una postulacion y reducir el cupo', function () {
    $voluntario = Voluntario::factory()->create();
    $fundacion = Fundacion::factory()->create();
    $publicacion = Publicacion::factory()->create([
        'fundacion_id' => $fundacion->id,
        'estado'       => EstadoPublicacion::PUBLICADA,
        'cupo_maximo'  => 1,
    ]);

    $postulacion = Postulacion::create([
        'publicacion_id' => $publicacion->id,
        'voluntario_id'  => $voluntario->id,
        'estado'         => EstadoPostulacion::PENDIENTE,
    ]);

    $response = $this->actingAs($fundacion->usuario, 'sanctum')
                     ->putJson("/api/v1/postulaciones/{$postulacion->id}/responder", [
                         'estado' => 'ACEPTADO',
                     ]);

    $response->assertStatus(200)
             ->assertJsonPath('estado', 'ACEPTADO');

    // Dado que el cupo máximo era 1 y se aceptó, la convocatoria debe haberse cerrado automáticamente
    expect($publicacion->fresh()->estado)->toBe(EstadoPublicacion::CERRADA);
});

test('un voluntario puede retirar su postulacion', function () {
    $voluntario = Voluntario::factory()->create();
    $publicacion = Publicacion::factory()->create();

    $postulacion = Postulacion::create([
        'publicacion_id' => $publicacion->id,
        'voluntario_id'  => $voluntario->id,
        'estado'         => EstadoPostulacion::PENDIENTE,
    ]);

    $response = $this->actingAs($voluntario->usuario, 'sanctum')
                     ->postJson("/api/v1/postulaciones/{$postulacion->id}/retirar");

    $response->assertStatus(200)
             ->assertJsonPath('estado', 'RETIRADO');
});

test('una fundacion puede registrar la asistencia y calificar a un voluntario', function () {
    $voluntario = Voluntario::factory()->create();
    $fundacion = Fundacion::factory()->create();
    $publicacion = Publicacion::factory()->create(['fundacion_id' => $fundacion->id]);

    $postulacion = Postulacion::create([
        'publicacion_id' => $publicacion->id,
        'voluntario_id'  => $voluntario->id,
        'estado'         => EstadoPostulacion::ACEPTADO,
    ]);

    $response = $this->actingAs($fundacion->usuario, 'sanctum')
                     ->postJson("/api/v1/postulaciones/{$postulacion->id}/confirmar-asistencia", [
                         'asistio'              => true,
                         'calificacion'         => 5,
                         'comentario_fundacion' => 'Excelente voluntario.',
                     ]);

    $response->assertStatus(200)
             ->assertJsonPath('estado', 'ASISTIO')
             ->assertJsonPath('calificacion', 5);
});

/*
|--------------------------------------------------------------------------
| 7. Pruebas de Notificaciones
|--------------------------------------------------------------------------
*/
test('un usuario puede ver sus notificaciones', function () {
    $usuario = Usuario::factory()->create();
    $notif = \App\Models\Notificacion::create([
        'usuario_id'  => $usuario->id,
        'tipo'        => 'RECORDATORIO_ACTIVIDAD',
        'mensaje'     => 'Tienes un evento mañana.',
    ]);

    $response = $this->actingAs($usuario, 'sanctum')
                     ->getJson('/api/v1/notificaciones');

    $response->assertStatus(200)
             ->assertJsonStructure(['data', 'links', 'meta']);
});

/*
|--------------------------------------------------------------------------
| 8. Pruebas del Panel Administrador
|--------------------------------------------------------------------------
*/
test('un administrador puede aprobar una fundacion pendiente', function () {
    // Buscar o simular el admin inicial
    $admin = Usuario::where('rol', RolUsuario::ADMIN)->first();
    $fundacion = Fundacion::factory()->pendiente()->create();

    $response = $this->actingAs($admin, 'sanctum')
                     ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/gestionar", [
                         'estado' => 'APROBADA',
                     ]);

    $response->assertStatus(200)
             ->assertJsonPath('estado_verificacion', 'APROBADA');
});

test('un voluntario no puede gestionar fundaciones en el panel admin', function () {
    $usuario = Usuario::factory()->create(['rol' => RolUsuario::VOLUNTARIO]);
    $fundacion = Fundacion::factory()->pendiente()->create();

    $response = $this->actingAs($usuario, 'sanctum')
                     ->putJson("/api/v1/admin/fundaciones/{$fundacion->id}/gestionar", [
                         'estado' => 'APROBADA',
                     ]);

    $response->assertStatus(403);
});

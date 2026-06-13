<?php

namespace App\Services;

use App\Enums\EstadoUsuario;
use App\Enums\ProveedorAuth;
use App\Enums\RolUsuario;
use App\Models\Usuario;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function register(array $data): array
    {
        $existente = Usuario::where('email', $data['email'])
            ->where('provider', ProveedorAuth::LOCAL)
            ->first();

        if ($existente) {
            throw ValidationException::withMessages(['email' => 'El email ya está registrado.']);
        }

        $usuario = Usuario::create([
            'nombre'        => $data['nombre'],
            'email'         => $data['email'],
            'password_hash' => Hash::make($data['password']),
            'provider'      => ProveedorAuth::LOCAL,
            'telefono'      => $data['telefono'] ?? null,
            'rol'           => RolUsuario::from($data['rol']),
            'estado'        => EstadoUsuario::ACTIVO,
        ]);

        $this->enviarVerificacionEmail($usuario);

        $token = $usuario->createToken('api')->plainTextToken;

        return ['usuario' => $usuario, 'token' => $token];
    }

    public function login(string $email, string $password): array
    {
        $usuario = Usuario::where('email', $email)
            ->where('provider', ProveedorAuth::LOCAL)
            ->first();

        if (!$usuario || !Hash::check($password, $usuario->password_hash)) {
            throw ValidationException::withMessages(['email' => 'Credenciales incorrectas.']);
        }

        if ($usuario->estado === EstadoUsuario::BLOQUEADO) {
            throw ValidationException::withMessages(['email' => 'Cuenta bloqueada. Contacta al soporte.']);
        }

        if ($usuario->estado === EstadoUsuario::SUSPENDIDO) {
            throw ValidationException::withMessages(['email' => 'Cuenta suspendida.']);
        }

        $token = $usuario->createToken('api')->plainTextToken;

        return ['usuario' => $usuario, 'token' => $token];
    }

    public function logout(Usuario $usuario): void
    {
        $usuario->currentAccessToken()->delete();
    }

    public function enviarVerificacionEmail(Usuario $usuario): void
    {
        $token = Str::random(64);

        \DB::table('verificacion_email')->insert([
            'id'         => \Str::uuid(),
            'usuario_id' => $usuario->id,
            'token'      => $token,
            'expiracion' => now()->addHours(24),
        ]);

        // TODO: disparar evento/mail de verificación
    }

    public function verificarEmail(string $token): bool
    {
        $registro = \DB::table('verificacion_email')
            ->where('token', $token)
            ->where('usado', false)
            ->where('expiracion', '>', now())
            ->first();

        if (!$registro) return false;

        \DB::table('verificacion_email')->where('token', $token)->update(['usado' => true]);
        Usuario::where('id', $registro->usuario_id)->update(['email_verificado' => true]);

        return true;
    }

    public function solicitarResetPassword(string $email): ?string
    {
        $usuario = Usuario::where('email', $email)
            ->where('provider', ProveedorAuth::LOCAL)
            ->first();

        if (!$usuario) return null;

        $token = Str::random(64);

        \DB::table('recuperacion_password')
            ->where('usuario_id', $usuario->id)
            ->where('usado', false)
            ->update(['usado' => true, 'fecha_uso' => now()]);

        \DB::table('recuperacion_password')->insert([
            'id'          => \Str::uuid(),
            'usuario_id'  => $usuario->id,
            'token'       => $token,
            'expiracion'  => now()->addHour(),
            'ip_solicitud'=> request()->ip(),
            'user_agent'  => request()->userAgent(),
        ]);

        // TODO: disparar evento/mail de reset
        return $token;
    }

    public function resetPassword(string $token, string $nuevaPassword): bool
    {
        $registro = \DB::table('recuperacion_password')
            ->where('token', $token)
            ->where('usado', false)
            ->where('expiracion', '>', now())
            ->first();

        if (!$registro) return false;

        Usuario::where('id', $registro->usuario_id)
            ->update(['password_hash' => Hash::make($nuevaPassword)]);

        \DB::table('recuperacion_password')
            ->where('token', $token)
            ->update(['usado' => true, 'fecha_uso' => now()]);

        return true;
    }
}

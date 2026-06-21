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
use PHPOpenSourceSaver\JWTAuth\Facades\JWTAuth;

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

        $token        = JWTAuth::fromUser($usuario);
        $refreshToken = $this->generarRefreshToken($usuario);

        return [
            'usuario'       => $usuario,
            'token'         => $token,
            'refresh_token' => $refreshToken,
            'token_type'    => 'bearer',
            'expires_in'    => config('jwt.ttl') * 60,
        ];
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

        $token        = JWTAuth::fromUser($usuario);
        $refreshToken = $this->generarRefreshToken($usuario);

        return [
            'usuario'       => $usuario,
            'token'         => $token,
            'refresh_token' => $refreshToken,
            'token_type'    => 'bearer',
            'expires_in'    => config('jwt.ttl') * 60,
        ];
    }

    public function logout(?Usuario $usuario = null): void
    {
        try {
            JWTAuth::invalidate(JWTAuth::getToken());
        } catch (\Exception) {
            // Token ya inválido o inexistente — continuar
        }

        if ($usuario) {
            $this->revocarRefreshTokens($usuario->id);
        }
    }

    /**
     * Invalida todos los refresh tokens activos del usuario.
     */
    public function revocarRefreshTokens(string $usuarioId): int
    {
        return DB::table('refresh_tokens')
            ->where('usuario_id', $usuarioId)
            ->where('usado', false)
            ->update(['usado' => true, 'fecha_uso' => now()]);
    }

    public function refresh(string $refreshToken): array
    {
        $registro = DB::table('refresh_tokens')
            ->where('token', $refreshToken)
            ->where('usado', false)
            ->where('expiracion', '>', now())
            ->first();

        if (!$registro) {
            throw ValidationException::withMessages(['refresh_token' => 'Refresh token inválido o expirado.']);
        }

        $usuario = Usuario::findOrFail($registro->usuario_id);

        DB::table('refresh_tokens')
            ->where('token', $refreshToken)
            ->update(['usado' => true, 'fecha_uso' => now()]);

        $newToken        = JWTAuth::fromUser($usuario);
        $newRefreshToken = $this->generarRefreshToken($usuario);

        return [
            'token'         => $newToken,
            'refresh_token' => $newRefreshToken,
            'token_type'    => 'bearer',
            'expires_in'    => config('jwt.ttl') * 60,
        ];
    }

    private function generarRefreshToken(Usuario $usuario): string
    {
        $token = Str::random(80);

        DB::table('refresh_tokens')->insert([
            'id'             => (string) Str::uuid(),
            'usuario_id'     => $usuario->id,
            'token'          => $token,
            'expiracion'     => now()->addDays(30),
            'usado'          => false,
            'fecha_creacion' => now(),
        ]);

        return $token;
    }

    public function enviarVerificacionEmail(Usuario $usuario): void
    {
        $token = Str::random(64);

        DB::table('verificacion_email')->insert([
            'id'         => (string) Str::uuid(),
            'usuario_id' => $usuario->id,
            'token'      => $token,
            'expiracion' => now()->addHours(24),
        ]);

        // TODO: disparar evento/mail de verificación (Sprint 5)
    }

    public function verificarEmail(string $token): bool
    {
        $registro = DB::table('verificacion_email')
            ->where('token', $token)
            ->where('usado', false)
            ->where('expiracion', '>', now())
            ->first();

        if (!$registro) return false;

        DB::table('verificacion_email')->where('token', $token)->update(['usado' => true]);
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

        DB::table('recuperacion_password')
            ->where('usuario_id', $usuario->id)
            ->where('usado', false)
            ->update(['usado' => true, 'fecha_uso' => now()]);

        DB::table('recuperacion_password')->insert([
            'id'           => (string) Str::uuid(),
            'usuario_id'   => $usuario->id,
            'token'        => $token,
            'expiracion'   => now()->addHour(),
            'ip_solicitud' => request()->ip(),
            'user_agent'   => request()->userAgent(),
        ]);

        // TODO: disparar evento/mail de reset (Sprint 5)
        return $token;
    }

    public function resetPassword(string $token, string $nuevaPassword): bool
    {
        $registro = DB::table('recuperacion_password')
            ->where('token', $token)
            ->where('usado', false)
            ->where('expiracion', '>', now())
            ->first();

        if (!$registro) return false;

        Usuario::where('id', $registro->usuario_id)
            ->update(['password_hash' => Hash::make($nuevaPassword)]);

        DB::table('recuperacion_password')
            ->where('token', $token)
            ->update(['usado' => true, 'fecha_uso' => now()]);

        return true;
    }
}

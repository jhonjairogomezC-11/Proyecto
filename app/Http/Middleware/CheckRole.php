<?php

namespace App\Http\Middleware;

use App\Enums\EstadoUsuario;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }

        // Bloquear acceso si la cuenta está suspendida o bloqueada
        $estado = $user->estado instanceof \BackedEnum ? $user->estado : EstadoUsuario::tryFrom($user->estado);

        if ($estado === EstadoUsuario::SUSPENDIDO) {
            return response()->json(['message' => 'Tu cuenta está suspendida. Contacta al soporte.'], 403);
        }

        if ($estado === EstadoUsuario::BLOQUEADO) {
            return response()->json(['message' => 'Tu cuenta está bloqueada. Contacta al soporte.'], 403);
        }

        // Verificar rol
        $userRol = $user->rol instanceof \BackedEnum ? $user->rol->value : ($user->rol ?? null);

        if (!in_array($userRol, $roles)) {
            return response()->json(['message' => 'No tienes permisos para esta acción.'], 403);
        }

        return $next($request);
    }
}

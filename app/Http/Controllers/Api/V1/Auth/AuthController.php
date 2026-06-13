<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Http\Resources\UsuarioResource;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(private AuthService $authService) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());

        return response()->json([
            'usuario' => new UsuarioResource($result['usuario']),
            'token'   => $result['token'],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login($request->email, $request->password);

        return response()->json([
            'usuario' => new UsuarioResource($result['usuario']),
            'token'   => $result['token'],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json(['message' => 'Sesión cerrada correctamente.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(new UsuarioResource($request->user()));
    }

    public function verificarEmail(string $token): JsonResponse
    {
        $ok = $this->authService->verificarEmail($token);

        return response()->json(
            $ok ? ['message' => 'Email verificado correctamente.'] : ['message' => 'Token inválido o expirado.'],
            $ok ? 200 : 400
        );
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->authService->solicitarResetPassword($request->email);

        return response()->json(['message' => 'Si el email existe, recibirás un enlace de recuperación.']);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $ok = $this->authService->resetPassword($request->token, $request->password);

        return response()->json(
            $ok ? ['message' => 'Contraseña actualizada correctamente.'] : ['message' => 'Token inválido o expirado.'],
            $ok ? 200 : 400
        );
    }
}

<?php

namespace App\Http\Requests\Auth;

use App\Enums\RolUsuario;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'nombre'   => ['required', 'string', 'max:120'],
            'email'    => ['required', 'email', 'max:150'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'rol'      => ['required', 'in:VOLUNTARIO,FUNDACION'],
            'telefono' => ['nullable', 'string', 'max:20'],
        ];
    }
}

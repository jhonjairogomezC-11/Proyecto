<?php

namespace App\Http\Requests\Admin;

use App\Enums\EstadoVerificacion;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class GestionarFundacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'estado'  => ['required', Rule::enum(EstadoVerificacion::class)],
            'motivo'  => ['required_if:estado,RECHAZADA', 'required_if:estado,SUSPENDIDA', 'nullable', 'string', 'max:500'],
        ];
    }
}

<?php

namespace App\Http\Requests\Postulacion;

use App\Enums\EstadoPostulacion;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePostulacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'estado'              => ['required', Rule::enum(EstadoPostulacion::class)],
            'motivo_rechazo'      => ['required_if:estado,RECHAZADO', 'nullable', 'string', 'max:500'],
            'calificacion'        => ['required_if:estado,ASISTIO', 'nullable', 'integer', 'between:1,5'],
            'comentario_fundacion'=> ['nullable', 'string', 'max:1000'],
        ];
    }
}

<?php

namespace App\Http\Requests\Voluntario;

use App\Enums\DisponibilidadTipo;
use App\Enums\GeneroTipo;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateVoluntarioRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'genero'         => ['sometimes', Rule::enum(GeneroTipo::class)],
            'municipio_id'   => ['sometimes', 'integer', 'exists:municipios,id'],
            'disponibilidad' => ['sometimes', Rule::enum(DisponibilidadTipo::class)],
            'experiencia'    => ['nullable', 'string'],
            'habilidades'    => ['nullable', 'array'],
            'habilidades.*'  => ['integer', 'exists:habilidades,id'],
            'intereses'      => ['nullable', 'array'],
            'intereses.*'    => ['integer', 'exists:intereses,id'],
        ];
    }
}

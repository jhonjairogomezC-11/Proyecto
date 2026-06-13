<?php

namespace App\Http\Requests\Voluntario;

use App\Enums\DisponibilidadTipo;
use App\Enums\GeneroTipo;
use App\Enums\TipoDocumento;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreVoluntarioRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'tipo_documento'   => ['required', Rule::enum(TipoDocumento::class)],
            'numero_documento' => ['required', 'string', 'max:30', 'unique:voluntarios,numero_documento'],
            'fecha_nacimiento' => ['required', 'date', 'before:-14 years'],
            'genero'           => ['required', Rule::enum(GeneroTipo::class)],
            'municipio_id'     => ['required', 'integer', 'exists:municipios,id'],
            'disponibilidad'   => ['required', Rule::enum(DisponibilidadTipo::class)],
            'experiencia'      => ['nullable', 'string'],
            'habilidades'      => ['nullable', 'array'],
            'habilidades.*'    => ['integer', 'exists:habilidades,id'],
            'intereses'        => ['nullable', 'array'],
            'intereses.*'      => ['integer', 'exists:intereses,id'],
        ];
    }
}

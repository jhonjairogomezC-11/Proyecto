<?php

namespace App\Http\Requests\Publicacion;

use App\Enums\ModalidadTipo;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePublicacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'titulo'                  => ['required', 'string', 'max:200'],
            'descripcion'             => ['required', 'string'],
            'categoria_id'            => ['required', 'integer', 'exists:areas_impacto,id'],
            'modalidad'               => ['required', Rule::enum(ModalidadTipo::class)],
            'municipio_id'            => ['required_if:modalidad,PRESENCIAL', 'required_if:modalidad,HIBRIDA', 'nullable', 'integer', 'exists:municipios,id'],
            'direccion_exacta'        => ['nullable', 'string', 'max:200'],
            'enlace_virtual'          => ['nullable', 'string'],
            'fecha_inicio'            => ['required', 'date', 'after_or_equal:today'],
            'fecha_fin'               => ['required', 'date', 'after_or_equal:fecha_inicio'],
            'hora_inicio'             => ['nullable', 'date_format:H:i'],
            'hora_fin'                => ['nullable', 'date_format:H:i'],
            'cupo_maximo'             => ['required', 'integer', 'min:1'],
            'edad_minima'             => ['nullable', 'integer', 'min:14'],
            'edad_maxima'             => ['nullable', 'integer', 'gte:edad_minima'],
            'requisitos_adicionales'  => ['nullable', 'string'],
            'contacto_nombre'         => ['nullable', 'string', 'max:150'],
            'contacto_email'          => ['nullable', 'email', 'max:150'],
            'contacto_telefono'       => ['nullable', 'string', 'max:20'],
            'habilidades'             => ['nullable', 'array'],
            'habilidades.*'           => ['integer', 'exists:habilidades,id'],
        ];
    }
}

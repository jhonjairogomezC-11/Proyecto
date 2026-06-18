<?php

namespace App\Http\Requests\Publicacion;

use App\Enums\EstadoPublicacion;
use App\Enums\ModalidadTipo;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePublicacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'titulo'                 => ['sometimes', 'string', 'max:200'],
            'descripcion'            => ['sometimes', 'string'],
            'categoria_id'           => ['sometimes', 'integer', 'exists:areas_impacto,id'],
            'modalidad'              => ['sometimes', Rule::enum(ModalidadTipo::class)],
            'municipio_id'           => ['nullable', 'integer', 'exists:municipios,id'],
            'direccion_exacta'       => ['nullable', 'string', 'max:200'],
            'enlace_virtual'         => ['nullable', 'string'],
            'fecha_inicio'           => ['sometimes', 'date'],
            'fecha_fin'              => ['sometimes', 'date', 'after_or_equal:fecha_inicio'],
            'hora_inicio'            => ['nullable', 'date_format:H:i'],
            'hora_fin'               => ['nullable', 'date_format:H:i'],
            'cupo_maximo'            => ['sometimes', 'integer', 'min:1'],
            'dificultad'             => ['nullable', Rule::enum(\App\Enums\DificultadTipo::class)],
            'urgente'                => ['nullable', 'boolean'],
            'edad_minima'            => ['nullable', 'integer', 'min:14'],
            'edad_maxima'            => ['nullable', 'integer', 'gte:edad_minima'],
            'requisitos_adicionales' => ['nullable', 'string'],
            'contacto_nombre'        => ['nullable', 'string', 'max:150'],
            'contacto_email'         => ['nullable', 'email'],
            'contacto_telefono'      => ['nullable', 'string', 'max:20'],
            'estado'                 => ['sometimes', Rule::enum(EstadoPublicacion::class)],
            'habilidades'            => ['nullable', 'array'],
            'habilidades.*'          => ['integer', 'exists:habilidades,id'],
        ];
    }
}

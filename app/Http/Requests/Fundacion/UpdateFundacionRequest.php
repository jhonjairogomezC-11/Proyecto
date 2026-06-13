<?php

namespace App\Http\Requests\Fundacion;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFundacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        $id = $this->route('fundacion');

        return [
            'nombre'               => ['sometimes', 'string', 'max:150'],
            'representante_legal'  => ['sometimes', 'string', 'max:150'],
            'correo_institucional' => ['nullable', 'email', 'max:150', Rule::unique('fundaciones', 'correo_institucional')->ignore($id)],
            'telefono'             => ['sometimes', 'string', 'max:20'],
            'direccion'            => ['sometimes', 'string', 'max:200'],
            'municipio_id'         => ['sometimes', 'integer', 'exists:municipios,id'],
            'pagina_web'           => ['nullable', 'url', 'max:255'],
            'descripcion'          => ['sometimes', 'string'],
            'areas'                => ['nullable', 'array'],
            'areas.*'              => ['integer', 'exists:areas_impacto,id'],
        ];
    }
}

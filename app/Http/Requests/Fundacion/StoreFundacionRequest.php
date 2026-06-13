<?php

namespace App\Http\Requests\Fundacion;

use Illuminate\Foundation\Http\FormRequest;

class StoreFundacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'nombre'               => ['required', 'string', 'max:150'],
            'nit'                  => ['required', 'string', 'max:20', 'unique:fundaciones,nit', 'regex:/^\d{7,10}-\d$/'],
            'representante_legal'  => ['required', 'string', 'max:150'],
            'correo_institucional' => ['nullable', 'email', 'max:150', 'unique:fundaciones,correo_institucional'],
            'telefono'             => ['required', 'string', 'max:20'],
            'direccion'            => ['required', 'string', 'max:200'],
            'municipio_id'         => ['required', 'integer', 'exists:municipios,id'],
            'pagina_web'           => ['nullable', 'url', 'max:255'],
            'descripcion'          => ['required', 'string'],
            'documento_legal'      => ['required', 'string'],
            'areas'                => ['nullable', 'array'],
            'areas.*'              => ['integer', 'exists:areas_impacto,id'],
        ];
    }
}

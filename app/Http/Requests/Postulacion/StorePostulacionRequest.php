<?php

namespace App\Http\Requests\Postulacion;

use Illuminate\Foundation\Http\FormRequest;

class StorePostulacionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'publicacion_id'   => ['required', 'uuid', 'exists:publicaciones,id'],
            'mensaje_voluntario' => ['nullable', 'string', 'max:1000'],
        ];
    }
}

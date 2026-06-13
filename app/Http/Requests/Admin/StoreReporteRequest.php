<?php

namespace App\Http\Requests\Admin;

use App\Enums\MotivoReporte;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreReporteRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'objeto_tipo' => ['required', 'string', 'in:PUBLICACION,FUNDACION,USUARIO'],
            'objeto_id'   => ['required', 'uuid'],
            'motivo'      => ['required', Rule::enum(MotivoReporte::class)],
            'detalle'     => ['nullable', 'string', 'max:1000'],
        ];
    }
}

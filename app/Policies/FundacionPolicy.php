<?php

namespace App\Policies;

use App\Models\Fundacion;
use App\Models\Usuario;

class FundacionPolicy
{
    /**
     * Determine whether the user can update the model.
     */
    public function update(Usuario $user, Fundacion $fundacion): bool
    {
        $userRol = isset($user->rol->value) ? $user->rol->value : $user->rol;
        return $user->id === $fundacion->usuario_id || $userRol === 'ADMIN';
    }
}

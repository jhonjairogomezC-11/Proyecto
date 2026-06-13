<?php

namespace App\Policies;

use App\Models\Publicacion;
use App\Models\Usuario;

class PublicacionPolicy
{
    /**
     * Determine whether the user can update the model.
     */
    public function update(Usuario $user, Publicacion $publicacion): bool
    {
        $userRol = isset($user->rol->value) ? $user->rol->value : $user->rol;
        return ($user->fundacion && $user->fundacion->id === $publicacion->fundacion_id) || $userRol === 'ADMIN';
    }
}

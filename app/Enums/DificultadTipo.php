<?php

namespace App\Enums;

enum DificultadTipo: string
{
    case FACIL       = 'FACIL';
    case MEDIA       = 'MEDIA';
    case DIFICIL     = 'DIFICIL';
    case MUY_DIFICIL = 'MUY_DIFICIL';

    /** Puntos base según dificultad */
    public function puntosBase(): int
    {
        return match ($this) {
            self::FACIL       => 10,
            self::MEDIA       => 25,
            self::DIFICIL     => 50,
            self::MUY_DIFICIL => 100,
        };
    }

    public function label(): string
    {
        return match ($this) {
            self::FACIL       => 'Fácil',
            self::MEDIA       => 'Media',
            self::DIFICIL     => 'Difícil',
            self::MUY_DIFICIL => 'Muy difícil',
        };
    }
}

<?php

namespace App\Providers;

use App\Models\Fundacion;
use App\Models\Publicacion;
use App\Policies\FundacionPolicy;
use App\Policies\PublicacionPolicy;
use Carbon\Carbon;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Gate::policy(Fundacion::class,  FundacionPolicy::class);
        Gate::policy(Publicacion::class, PublicacionPolicy::class);

        // Macro para convertir cualquier Carbon a hora Colombia en Resources y respuestas
        Carbon::macro('toColombia', function () {
            /** @var Carbon $this */
            return $this->copy()->setTimezone('America/Bogota');
        });

        Carbon::macro('toColombiaString', function (string $format = 'd/m/Y H:i') {
            /** @var Carbon $this */
            return $this->copy()->setTimezone('America/Bogota')->format($format);
        });
    }
}

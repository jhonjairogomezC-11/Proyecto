<?php

namespace App\Providers;

use App\Models\Fundacion;
use App\Models\Publicacion;
use App\Policies\FundacionPolicy;
use App\Policies\PublicacionPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Fundacion::class,  FundacionPolicy::class);
        Gate::policy(Publicacion::class, PublicacionPolicy::class);
    }
}

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('refresh_tokens', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->constrained('usuarios')->cascadeOnDelete();
            $table->text('token');
            $table->timestamp('expiracion');
            $table->boolean('usado')->default(false);
            $table->timestamp('fecha_uso')->nullable();
            $table->string('ip_solicitud', 50)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
        });

        DB::statement('CREATE UNIQUE INDEX idx_refresh_token_unique ON refresh_tokens(token)');
        DB::statement('CREATE INDEX idx_refresh_usuario ON refresh_tokens(usuario_id)');
        DB::statement('CREATE INDEX idx_refresh_expiracion ON refresh_tokens(expiracion) WHERE usado = FALSE');
    }

    public function down(): void
    {
        Schema::dropIfExists('refresh_tokens');
    }
};

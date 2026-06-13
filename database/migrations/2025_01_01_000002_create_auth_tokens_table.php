<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('verificacion_email', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->constrained('usuarios')->cascadeOnDelete();
            $table->text('token');
            $table->timestamp('expiracion')->default(DB::raw("CURRENT_TIMESTAMP + INTERVAL '1 day'"));
            $table->boolean('usado')->default(false);
            $table->timestamp('fecha_creacion')->useCurrent();
        });

        DB::statement('CREATE UNIQUE INDEX idx_token_verificacion_unique ON verificacion_email(token)');
        DB::statement('CREATE INDEX idx_verificacion_usuario ON verificacion_email(usuario_id)');
        DB::statement('CREATE INDEX idx_verificacion_expiracion ON verificacion_email(expiracion)');

        Schema::create('recuperacion_password', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->foreignUuid('usuario_id')->constrained('usuarios')->cascadeOnDelete();
            $table->text('token');
            $table->timestamp('expiracion')->default(DB::raw("CURRENT_TIMESTAMP + INTERVAL '1 hour'"));
            $table->boolean('usado')->default(false);
            $table->timestamp('fecha_uso')->nullable();
            $table->string('ip_solicitud', 50)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('fecha_creacion')->useCurrent();
        });

        DB::statement('CREATE UNIQUE INDEX idx_reset_token_unique ON recuperacion_password(token)');
        DB::statement('CREATE INDEX idx_reset_usuario ON recuperacion_password(usuario_id)');
        DB::statement('CREATE INDEX idx_reset_expiracion ON recuperacion_password(expiracion) WHERE usado = FALSE');
    }

    public function down(): void
    {
        Schema::dropIfExists('recuperacion_password');
        Schema::dropIfExists('verificacion_email');
    }
};

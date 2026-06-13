<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"");

        DB::statement("DO \$\$ BEGIN CREATE TYPE rol_usuario AS ENUM ('VOLUNTARIO','FUNDACION','ADMIN'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE estado_usuario AS ENUM ('ACTIVO','BLOQUEADO','SUSPENDIDO'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");
        DB::statement("DO \$\$ BEGIN CREATE TYPE proveedor_auth AS ENUM ('LOCAL','GOOGLE'); EXCEPTION WHEN duplicate_object THEN null; END \$\$");

        Schema::create('usuarios', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('uuid_generate_v4()'));
            $table->string('nombre', 120);
            $table->string('email', 150);
            $table->text('password_hash')->nullable();
            $table->string('provider', 10)->default('LOCAL');
            $table->string('provider_id', 255)->nullable();
            $table->string('telefono', 20)->nullable();
            $table->string('rol', 20);
            $table->string('estado', 20)->default('ACTIVO');
            $table->boolean('email_verificado')->default(false);
            $table->timestamp('fecha_registro')->useCurrent();
            $table->timestamp('fecha_actualizacion')->useCurrent();
        });

        DB::statement("ALTER TABLE usuarios ALTER COLUMN provider DROP DEFAULT");
        DB::statement("ALTER TABLE usuarios ALTER COLUMN rol DROP DEFAULT");
        DB::statement("ALTER TABLE usuarios ALTER COLUMN estado DROP DEFAULT");

        DB::statement('ALTER TABLE usuarios ALTER COLUMN provider TYPE proveedor_auth USING provider::proveedor_auth');
        DB::statement('ALTER TABLE usuarios ALTER COLUMN rol TYPE rol_usuario USING rol::rol_usuario');
        DB::statement('ALTER TABLE usuarios ALTER COLUMN estado TYPE estado_usuario USING estado::estado_usuario');

        DB::statement("ALTER TABLE usuarios ALTER COLUMN provider SET DEFAULT 'LOCAL'");
        DB::statement("ALTER TABLE usuarios ALTER COLUMN estado SET DEFAULT 'ACTIVO'");

        DB::statement("ALTER TABLE usuarios ADD CONSTRAINT chk_auth_valid CHECK (
            (provider = 'LOCAL' AND password_hash IS NOT NULL) OR
            (provider = 'GOOGLE' AND provider_id IS NOT NULL)
        )");

        DB::statement('CREATE UNIQUE INDEX idx_email_provider_unique ON usuarios(email, provider)');
        DB::statement('CREATE UNIQUE INDEX idx_provider_id_unique ON usuarios(provider, provider_id) WHERE provider_id IS NOT NULL');
        DB::statement('CREATE INDEX idx_usuario_email ON usuarios(email)');
        DB::statement('CREATE INDEX idx_usuario_provider ON usuarios(provider)');
    }

    public function down(): void
    {
        Schema::dropIfExists('usuarios');
        DB::statement('DROP TYPE IF EXISTS rol_usuario');
        DB::statement('DROP TYPE IF EXISTS estado_usuario');
        DB::statement('DROP TYPE IF EXISTS proveedor_auth');
    }
};

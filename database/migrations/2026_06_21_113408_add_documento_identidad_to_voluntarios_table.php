<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('voluntarios', function (Blueprint $table) {
            $table->string('documento_identidad')->nullable()->after('numero_documento');
            $table->boolean('esta_verificado')->default(false)->after('documento_identidad');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('voluntarios', function (Blueprint $table) {
            $table->dropColumn(['documento_identidad', 'esta_verificado']);
        });
    }
};

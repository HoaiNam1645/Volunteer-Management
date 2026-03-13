<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chien_dich_ky_nangs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->unsignedBigInteger('ky_nang_id');
            $table->boolean('bat_buoc')->default(false)->comment('1=bat buoc, 0=uu tien');
            $table->timestamp('tao_luc')->useCurrent();

            $table->unique(['chien_dich_id', 'ky_nang_id'], 'idx_cd_kn_duy_nhat');

            $table->foreign('chien_dich_id', 'fk_cd_kn_chien_dich')->references('id')->on('chien_dichs')->cascadeOnDelete();
            $table->foreign('ky_nang_id', 'fk_cd_kn_ky_nang')->references('id')->on('ky_nangs')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chien_dich_ky_nangs');
    }
};

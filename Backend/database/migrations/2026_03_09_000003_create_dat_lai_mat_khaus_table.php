<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dat_lai_mat_khaus', function (Blueprint $table) {
            $table->id();
            $table->string('email', 255);
            $table->string('ma_xac_thuc', 255)->unique();
            $table->timestamp('het_han_luc');
            $table->timestamp('tao_luc')->useCurrent();

            $table->index('email', 'idx_dlmk_email');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dat_lai_mat_khaus');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nguoi_dung_ky_nangs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->unsignedBigInteger('ky_nang_id');
            $table->timestamp('tao_luc')->useCurrent();

            $table->unique(['nguoi_dung_id', 'ky_nang_id'], 'idx_nd_kn_duy_nhat');
            $table->index('ky_nang_id', 'idx_nd_kn_ky_nang');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
            $table->foreign('ky_nang_id')->references('id')->on('ky_nangs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nguoi_dung_ky_nangs');
    }
};

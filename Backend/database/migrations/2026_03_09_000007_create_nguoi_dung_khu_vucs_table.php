<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nguoi_dung_khu_vucs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->unsignedBigInteger('khu_vuc_id');
            $table->timestamp('tao_luc')->useCurrent();

            $table->unique(['nguoi_dung_id', 'khu_vuc_id'], 'idx_nd_kv_duy_nhat');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
            $table->foreign('khu_vuc_id')->references('id')->on('khu_vucs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nguoi_dung_khu_vucs');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('xac_thuc_emails', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->string('ma_xac_thuc', 255)->unique();
            $table->timestamp('het_han_luc');
            $table->timestamp('xac_thuc_luc')->nullable();
            $table->timestamp('tao_luc')->useCurrent();

            $table->index('nguoi_dung_id', 'idx_xte_nguoi_dung');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('xac_thuc_emails');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chung_chis', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->string('ten', 255);
            $table->string('don_vi_cap', 255)->nullable();
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

            $table->index('nguoi_dung_id', 'idx_chung_chi_nd');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chung_chis');
    }
};

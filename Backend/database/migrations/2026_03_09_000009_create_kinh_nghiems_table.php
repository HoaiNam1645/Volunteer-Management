<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kinh_nghiems', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->string('tieu_de', 255);
            $table->string('to_chuc', 255)->nullable();
            $table->string('thoi_gian', 100)->nullable()->comment('VD: 06/2024 - 08/2024');
            $table->text('mo_ta')->nullable();
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

            $table->index('nguoi_dung_id', 'idx_kinh_nghiem_nd');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kinh_nghiems');
    }
};

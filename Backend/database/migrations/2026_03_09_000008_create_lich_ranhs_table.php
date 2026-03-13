<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lich_ranhs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->enum('thu_trong_tuan', ['thu_hai', 'thu_ba', 'thu_tu', 'thu_nam', 'thu_sau', 'thu_bay', 'chu_nhat']);
            $table->timestamp('tao_luc')->useCurrent();

            $table->unique(['nguoi_dung_id', 'thu_trong_tuan'], 'idx_lich_ranh_duy_nhat');
            $table->foreign('nguoi_dung_id')->references('id')->on('nguoi_dungs')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lich_ranhs');
    }
};

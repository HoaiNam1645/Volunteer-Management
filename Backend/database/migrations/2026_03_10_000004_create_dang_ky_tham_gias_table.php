<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dang_ky_tham_gias', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->enum('trang_thai', [
                'da_dang_ky',
                'da_duyet',
                'da_xac_nhan',
                'dang_tham_gia',
                'hoan_thanh',
                'da_huy',
                'tu_choi'
            ])->default('da_dang_ky');
            $table->timestamp('dang_ky_luc')->useCurrent();
            $table->timestamp('duyet_luc')->nullable();
            $table->timestamp('xac_nhan_luc')->nullable();
            $table->timestamp('huy_luc')->nullable();
            $table->string('ly_do_huy', 500)->nullable();
            $table->text('ghi_chu')->nullable();

            // Audit
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

            // Indexes
            $table->unique(['chien_dich_id', 'nguoi_dung_id'], 'idx_dktg_duy_nhat');
            $table->index('nguoi_dung_id', 'idx_dktg_nguoi_dung');
            $table->index('trang_thai', 'idx_dktg_trang_thai');

            // Foreign keys
            $table->foreign('chien_dich_id', 'fk_dktg_chien_dich')->references('id')->on('chien_dichs')->cascadeOnDelete();
            $table->foreign('nguoi_dung_id', 'fk_dktg_nguoi_dung')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dang_ky_tham_gias');
    }
};

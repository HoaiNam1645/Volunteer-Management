<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tai_khoan_lien_ket')) {
            return;
        }

        Schema::create('tai_khoan_lien_ket', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('nguoi_dung_id');
            $table->enum('nha_cung_cap', ['google', 'facebook', 'tw']);
            $table->string('id_nha_cung_cap', 255)->comment('ID tu provider tra ve');
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

            $table->unique(['nha_cung_cap', 'id_nha_cung_cap'], 'idx_tklk_duy_nhat');
            $table->index('nguoi_dung_id', 'idx_tklk_nguoi_dung');
            $table->foreign('nguoi_dung_id', 'fk_tklk_nguoi_dung')
                ->references('id')
                ->on('nguoi_dungs')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tai_khoan_lien_ket');
    }
};

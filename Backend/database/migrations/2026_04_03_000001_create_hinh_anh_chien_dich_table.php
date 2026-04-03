<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('hinh_anh_chien_dich')) {
            return;
        }

        Schema::create('hinh_anh_chien_dich', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('chien_dich_id');
            $table->string('duong_dan_anh', 500);
            $table->integer('thu_tu')->default(0);
            $table->timestamp('tao_luc')->useCurrent();

            $table->index('chien_dich_id', 'idx_ha_cd_chien_dich');
            $table->foreign('chien_dich_id', 'fk_ha_cd_chien_dich')
                ->references('id')
                ->on('chien_dichs')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hinh_anh_chien_dich');
    }
};

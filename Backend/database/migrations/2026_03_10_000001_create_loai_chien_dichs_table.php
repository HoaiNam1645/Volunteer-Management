<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('loai_chien_dichs', function (Blueprint $table) {
            $table->id();
            $table->string('ten', 100)->unique();
            $table->string('bieu_tuong', 100)->nullable();
            $table->string('mau_sac', 50)->nullable();
            $table->boolean('hoat_dong')->default(true);
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();
            $table->timestamp('xoa_luc')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loai_chien_dichs');
    }
};

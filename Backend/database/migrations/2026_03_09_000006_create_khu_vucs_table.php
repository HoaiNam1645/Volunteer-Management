<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('khu_vucs', function (Blueprint $table) {
            $table->id();
            $table->string('ten', 150)->unique();
            $table->decimal('vi_do', 10, 7)->nullable();
            $table->decimal('kinh_do', 10, 7)->nullable();
            $table->tinyInteger('hoat_dong')->default(1);
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();
            $table->timestamp('xoa_luc')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('khu_vucs');
    }
};

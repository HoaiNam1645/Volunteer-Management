<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ky_nangs', function (Blueprint $table) {
            $table->id();
            $table->string('ten', 100)->unique();
            $table->string('bieu_tuong', 100)->nullable()->comment('FontAwesome class');
            $table->string('mo_ta', 500)->nullable();
            $table->tinyInteger('hoat_dong')->default(1);
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();
            $table->timestamp('xoa_luc')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ky_nangs');
    }
};

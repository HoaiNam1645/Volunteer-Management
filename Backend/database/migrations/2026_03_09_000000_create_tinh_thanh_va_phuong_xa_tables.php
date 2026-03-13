<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tinh_thanh', function (Blueprint $table) {
            $table->id();
            $table->string('ma', 10)->unique('idx_tinh_thanh_ma');
            $table->string('ten', 100);
            $table->decimal('vi_do', 10, 7)->nullable();
            $table->decimal('kinh_do', 10, 7)->nullable();
        });

        Schema::create('phuong_xa', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('tinh_thanh_id')->index('idx_phuong_xa_tinh');
            $table->string('ma', 10)->unique('idx_phuong_xa_ma');
            $table->string('ten', 150);
            $table->decimal('vi_do', 10, 7)->nullable();
            $table->decimal('kinh_do', 10, 7)->nullable();

            $table->foreign('tinh_thanh_id', 'fk_phuong_xa_tinh')->references('id')->on('tinh_thanh')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('phuong_xa');
        Schema::dropIfExists('tinh_thanh');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('chien_dichs', function (Blueprint $table) {
            $table->timestamp('thoi_gian_bat_dau_thuc_te')
                ->nullable()
                ->after('ngay_ket_thuc');
            $table->timestamp('thoi_gian_ket_thuc_thuc_te')
                ->nullable()
                ->after('thoi_gian_bat_dau_thuc_te');
        });
    }

    public function down(): void
    {
        Schema::table('chien_dichs', function (Blueprint $table) {
            $table->dropColumn([
                'thoi_gian_bat_dau_thuc_te',
                'thoi_gian_ket_thuc_thuc_te',
            ]);
        });
    }
};

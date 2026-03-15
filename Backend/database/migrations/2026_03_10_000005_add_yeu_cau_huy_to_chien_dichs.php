<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('chien_dichs')) {
            return;
        }

        DB::statement("ALTER TABLE `chien_dichs` MODIFY COLUMN `trang_thai` ENUM('nhap','cho_duyet','da_duyet','dang_dien_ra','hoan_thanh','yeu_cau_huy','da_huy') NOT NULL DEFAULT 'nhap'");
    }

    public function down(): void
    {
        if (!Schema::hasTable('chien_dichs')) {
            return;
        }

        DB::table('chien_dichs')
            ->where('trang_thai', 'yeu_cau_huy')
            ->update([
                'trang_thai' => 'da_duyet',
            ]);

        DB::statement("ALTER TABLE `chien_dichs` MODIFY COLUMN `trang_thai` ENUM('nhap','cho_duyet','da_duyet','dang_dien_ra','hoan_thanh','da_huy') NOT NULL DEFAULT 'nhap'");
    }
};

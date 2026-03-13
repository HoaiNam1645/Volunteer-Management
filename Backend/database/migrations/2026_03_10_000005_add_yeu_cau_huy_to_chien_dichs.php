<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE `chien_dichs` MODIFY COLUMN `trang_thai` ENUM('nhap','cho_duyet','da_duyet','dang_dien_ra','hoan_thanh','yeu_cau_huy','da_huy') NOT NULL DEFAULT 'nhap'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE `chien_dichs` MODIFY COLUMN `trang_thai` ENUM('nhap','cho_duyet','da_duyet','dang_dien_ra','hoan_thanh','da_huy') NOT NULL DEFAULT 'nhap'");
    }
};

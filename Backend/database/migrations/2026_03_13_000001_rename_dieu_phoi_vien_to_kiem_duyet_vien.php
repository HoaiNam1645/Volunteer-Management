<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('nguoi_dungs') && Schema::hasColumn('nguoi_dungs', 'vai_tro')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `nguoi_dungs` MODIFY COLUMN `vai_tro` ENUM('tinh_nguyen_vien','dieu_phoi_vien','kiem_duyet_vien','quan_tri_vien') NOT NULL DEFAULT 'tinh_nguyen_vien'");
            }

            DB::table('nguoi_dungs')
                ->where('vai_tro', 'dieu_phoi_vien')
                ->update(['vai_tro' => 'kiem_duyet_vien']);

            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `nguoi_dungs` MODIFY COLUMN `vai_tro` ENUM('tinh_nguyen_vien','kiem_duyet_vien','quan_tri_vien') NOT NULL DEFAULT 'tinh_nguyen_vien'");
            }
        }

        if (
            Schema::hasTable('chien_dichs')
            && Schema::hasColumn('chien_dichs', 'dieu_phoi_vien_id')
            && !Schema::hasColumn('chien_dichs', 'kiem_duyet_vien_id')
        ) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `chien_dichs` CHANGE `dieu_phoi_vien_id` `kiem_duyet_vien_id` BIGINT UNSIGNED NOT NULL");
            } elseif (DB::getDriverName() === 'sqlite') {
                DB::statement("ALTER TABLE `chien_dichs` RENAME COLUMN `dieu_phoi_vien_id` TO `kiem_duyet_vien_id`");
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('nguoi_dungs') && Schema::hasColumn('nguoi_dungs', 'vai_tro')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `nguoi_dungs` MODIFY COLUMN `vai_tro` ENUM('tinh_nguyen_vien','dieu_phoi_vien','kiem_duyet_vien','quan_tri_vien') NOT NULL DEFAULT 'tinh_nguyen_vien'");
            }

            DB::table('nguoi_dungs')
                ->where('vai_tro', 'kiem_duyet_vien')
                ->update(['vai_tro' => 'dieu_phoi_vien']);

            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `nguoi_dungs` MODIFY COLUMN `vai_tro` ENUM('tinh_nguyen_vien','dieu_phoi_vien','quan_tri_vien') NOT NULL DEFAULT 'tinh_nguyen_vien'");
            }
        }

        if (
            Schema::hasTable('chien_dichs')
            && Schema::hasColumn('chien_dichs', 'kiem_duyet_vien_id')
            && !Schema::hasColumn('chien_dichs', 'dieu_phoi_vien_id')
        ) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `chien_dichs` CHANGE `kiem_duyet_vien_id` `dieu_phoi_vien_id` BIGINT UNSIGNED NOT NULL");
            } elseif (DB::getDriverName() === 'sqlite') {
                DB::statement("ALTER TABLE `chien_dichs` RENAME COLUMN `kiem_duyet_vien_id` TO `dieu_phoi_vien_id`");
            }
        }
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('chien_dichs') || Schema::hasColumn('chien_dichs', 'nguoi_tao_id')) {
            return;
        }

        if (Schema::hasColumn('chien_dichs', 'kiem_duyet_vien_id')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `chien_dichs` CHANGE `kiem_duyet_vien_id` `nguoi_tao_id` BIGINT UNSIGNED NOT NULL COMMENT 'Nguoi tao chien dich'");
            } elseif (DB::getDriverName() === 'sqlite') {
                DB::statement("ALTER TABLE `chien_dichs` RENAME COLUMN `kiem_duyet_vien_id` TO `nguoi_tao_id`");
            }
        } elseif (Schema::hasColumn('chien_dichs', 'dieu_phoi_vien_id')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `chien_dichs` CHANGE `dieu_phoi_vien_id` `nguoi_tao_id` BIGINT UNSIGNED NOT NULL COMMENT 'Nguoi tao chien dich'");
            } elseif (DB::getDriverName() === 'sqlite') {
                DB::statement("ALTER TABLE `chien_dichs` RENAME COLUMN `dieu_phoi_vien_id` TO `nguoi_tao_id`");
            }
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('chien_dichs') || Schema::hasColumn('chien_dichs', 'kiem_duyet_vien_id')) {
            return;
        }

        if (Schema::hasColumn('chien_dichs', 'nguoi_tao_id')) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement("ALTER TABLE `chien_dichs` CHANGE `nguoi_tao_id` `kiem_duyet_vien_id` BIGINT UNSIGNED NOT NULL");
            } elseif (DB::getDriverName() === 'sqlite') {
                DB::statement("ALTER TABLE `chien_dichs` RENAME COLUMN `nguoi_tao_id` TO `kiem_duyet_vien_id`");
            }
        }
    }
};

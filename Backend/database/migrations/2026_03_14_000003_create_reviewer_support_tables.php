<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('phan_hoi_tnv')) {
            Schema::create('phan_hoi_tnv', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('chien_dich_id');
                $table->unsignedBigInteger('nguoi_dung_id');
                $table->unsignedTinyInteger('so_sao');
                $table->text('nhan_xet')->nullable();
                $table->timestamp('tao_luc')->useCurrent();
                $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

                $table->unique(['chien_dich_id', 'nguoi_dung_id'], 'idx_ph_duy_nhat');
                $table->index('nguoi_dung_id', 'idx_ph_nguoi_dung');
                $table->foreign('chien_dich_id', 'fk_ph_chien_dich')->references('id')->on('chien_dichs')->cascadeOnDelete();
                $table->foreign('nguoi_dung_id', 'fk_ph_nguoi_dung')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('the_phan_hoi')) {
            Schema::create('the_phan_hoi', function (Blueprint $table) {
                $table->id();
                $table->string('ten', 100)->unique('idx_the_ph_ten');
                $table->timestamp('tao_luc')->useCurrent();
            });
        }

        if (!Schema::hasTable('phan_hoi_the')) {
            Schema::create('phan_hoi_the', function (Blueprint $table) {
                $table->unsignedBigInteger('phan_hoi_id');
                $table->unsignedBigInteger('the_id');
                $table->primary(['phan_hoi_id', 'the_id']);
                $table->foreign('phan_hoi_id', 'fk_pht_phan_hoi')->references('id')->on('phan_hoi_tnv')->cascadeOnDelete();
                $table->foreign('the_id', 'fk_pht_the')->references('id')->on('the_phan_hoi')->cascadeOnDelete();
            });
        }

        if (!Schema::hasTable('thong_bao')) {
            Schema::create('thong_bao', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('nguoi_dung_id');
                $table->unsignedBigInteger('nguoi_gui_id')->nullable();
                $table->enum('loai', ['phan_cong', 'cap_nhat_cd', 'danh_gia', 'nhac_nho', 'he_thong', 'email']);
                $table->string('tieu_de', 300);
                $table->text('noi_dung')->nullable();
                $table->string('loai_tham_chieu', 50)->nullable();
                $table->unsignedBigInteger('tham_chieu_id')->nullable();
                $table->boolean('da_doc')->default(false);
                $table->timestamp('doc_luc')->nullable();
                $table->enum('gui_qua', ['he_thong', 'email', 'ca_hai'])->default('he_thong');
                $table->timestamp('tao_luc')->useCurrent();

                $table->index('nguoi_dung_id', 'idx_tb_nguoi_dung');
                $table->index(['nguoi_dung_id', 'da_doc'], 'idx_tb_da_doc');
                $table->index('loai', 'idx_tb_loai');
                $table->index(['loai_tham_chieu', 'tham_chieu_id'], 'idx_tb_tham_chieu');
                $table->foreign('nguoi_dung_id', 'fk_tb_nguoi_dung')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
                $table->foreign('nguoi_gui_id', 'fk_tb_nguoi_gui')->references('id')->on('nguoi_dungs')->nullOnDelete();
            });
        }

        if (!Schema::hasTable('danh_gia_tnv')) {
            Schema::create('danh_gia_tnv', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('chien_dich_id');
                $table->unsignedBigInteger('tinh_nguyen_vien_id');
                $table->unsignedBigInteger('danh_gia_boi');
                $table->unsignedTinyInteger('so_sao');
                $table->text('nhan_xet')->nullable();
                $table->timestamp('tao_luc')->useCurrent();
                $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

                $table->unique(['chien_dich_id', 'tinh_nguyen_vien_id'], 'idx_dg_duy_nhat');
                $table->index('tinh_nguyen_vien_id', 'idx_dg_tnv');
                $table->index('danh_gia_boi', 'idx_dg_boi');
                $table->foreign('chien_dich_id', 'fk_dg_chien_dich')->references('id')->on('chien_dichs')->cascadeOnDelete();
                $table->foreign('tinh_nguyen_vien_id', 'fk_dg_tnv')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
                $table->foreign('danh_gia_boi', 'fk_dg_boi')->references('id')->on('nguoi_dungs');
            });
        }

        if (!Schema::hasTable('bao_cao_chien_dich')) {
            Schema::create('bao_cao_chien_dich', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('chien_dich_id');
                $table->unsignedBigInteger('nguoi_gui_id');
                $table->string('phan_loai', 100);
                $table->string('tieu_de', 300);
                $table->text('noi_dung');
                $table->enum('trang_thai', ['moi', 'dang_xu_ly', 'da_xu_ly', 'tu_choi'])->default('moi');
                $table->unsignedBigInteger('nguoi_xu_ly_id')->nullable();
                $table->timestamp('xu_ly_luc')->nullable();
                $table->text('phan_hoi_xu_ly')->nullable();
                $table->timestamp('tao_luc')->useCurrent();
                $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();

                $table->index(['chien_dich_id', 'trang_thai'], 'idx_bc_cd_trang_thai');
                $table->index('nguoi_gui_id', 'idx_bc_nguoi_gui');
                $table->index('nguoi_xu_ly_id', 'idx_bc_nguoi_xu_ly');
                $table->foreign('chien_dich_id', 'fk_bc_chien_dich')->references('id')->on('chien_dichs')->cascadeOnDelete();
                $table->foreign('nguoi_gui_id', 'fk_bc_nguoi_gui')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
                $table->foreign('nguoi_xu_ly_id', 'fk_bc_nguoi_xu_ly')->references('id')->on('nguoi_dungs')->nullOnDelete();
            });
        }

        if (!Schema::hasTable('lich_su_kiem_duyet_chien_dichs')) {
            Schema::create('lich_su_kiem_duyet_chien_dichs', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('chien_dich_id');
                $table->unsignedBigInteger('nguoi_thuc_hien_id');
                $table->string('hanh_dong', 100);
                $table->string('tu_trang_thai', 50)->nullable();
                $table->string('den_trang_thai', 50)->nullable();
                $table->text('ghi_chu')->nullable();
                $table->json('du_lieu_bo_sung')->nullable();
                $table->timestamp('tao_luc')->useCurrent();

                $table->index('chien_dich_id', 'idx_ls_kd_cd');
                $table->index('nguoi_thuc_hien_id', 'idx_ls_kd_nd');
                $table->foreign('chien_dich_id', 'fk_ls_kd_cd')->references('id')->on('chien_dichs')->cascadeOnDelete();
                $table->foreign('nguoi_thuc_hien_id', 'fk_ls_kd_nd')->references('id')->on('nguoi_dungs')->cascadeOnDelete();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('lich_su_kiem_duyet_chien_dichs');
        Schema::dropIfExists('bao_cao_chien_dich');
        Schema::dropIfExists('danh_gia_tnv');
        Schema::dropIfExists('thong_bao');
        Schema::dropIfExists('phan_hoi_the');
        Schema::dropIfExists('the_phan_hoi');
        Schema::dropIfExists('phan_hoi_tnv');
    }
};

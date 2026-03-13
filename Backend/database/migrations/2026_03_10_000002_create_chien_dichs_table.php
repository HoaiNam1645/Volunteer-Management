<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chien_dichs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('kiem_duyet_vien_id')->comment('Nguoi KDV tao & leader');
            $table->unsignedBigInteger('loai_chien_dich_id')->nullable();
            $table->string('tieu_de', 300);
            $table->text('mo_ta')->nullable();
            $table->string('anh_bia', 500)->nullable();

            // Dia diem
            $table->string('dia_diem', 500);
            $table->unsignedBigInteger('khu_vuc_id')->nullable();
            $table->decimal('vi_do', 10, 7)->nullable();
            $table->decimal('kinh_do', 10, 7)->nullable();

            // Thoi gian
            $table->date('ngay_bat_dau');
            $table->date('ngay_ket_thuc');
            $table->date('han_dang_ky')->nullable();

            // Yeu cau TNV
            $table->unsignedInteger('so_luong_toi_da')->default(50);
            $table->unsignedInteger('so_luong_toi_thieu')->nullable()->default(1);

            // Uu tien & Trang thai
            $table->enum('muc_do_uu_tien', ['thap', 'trung_binh', 'cao', 'khan_cap'])->default('trung_binh');
            $table->enum('trang_thai', ['nhap', 'cho_duyet', 'da_duyet', 'dang_dien_ra', 'hoan_thanh', 'da_huy'])->default('nhap');
            $table->unsignedBigInteger('duyet_boi')->nullable()->comment('Admin duyet');
            $table->timestamp('duyet_luc')->nullable();
            $table->string('ly_do_tu_choi', 500)->nullable();

            // Cache
            $table->unsignedInteger('so_dang_ky')->default(0);
            $table->unsignedInteger('so_xac_nhan')->default(0);

            // Audit & Soft Delete
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();
            $table->timestamp('xoa_luc')->nullable();

            // Indexes
            $table->index('kiem_duyet_vien_id', 'idx_cd_dieu_phoi');
            $table->index('loai_chien_dich_id', 'idx_cd_loai');
            $table->index('khu_vuc_id', 'idx_cd_khu_vuc');
            $table->index('trang_thai', 'idx_cd_trang_thai');
            $table->index('muc_do_uu_tien', 'idx_cd_uu_tien');
            $table->index(['ngay_bat_dau', 'ngay_ket_thuc'], 'idx_cd_thoi_gian');
            $table->index(['vi_do', 'kinh_do'], 'idx_cd_toa_do');
            $table->index('xoa_luc', 'idx_cd_xoa');

            // Foreign keys
            $table->foreign('kiem_duyet_vien_id', 'fk_cd_dieu_phoi')->references('id')->on('nguoi_dungs');
            $table->foreign('loai_chien_dich_id', 'fk_cd_loai')->references('id')->on('loai_chien_dichs')->nullOnDelete();
            $table->foreign('khu_vuc_id', 'fk_cd_khu_vuc')->references('id')->on('khu_vucs')->nullOnDelete();
            $table->foreign('duyet_boi', 'fk_cd_duyet_boi')->references('id')->on('nguoi_dungs')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chien_dichs');
    }
};

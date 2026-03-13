<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nguoi_dungs', function (Blueprint $table) {
            $table->id();
            $table->string('ho_ten', 150);
            $table->string('email', 255)->unique();
            $table->timestamp('xac_thuc_email_luc')->nullable();
            $table->string('mat_khau', 255)->nullable()->comment('NULL neu chi dang nhap bang MXH');
            $table->string('so_dien_thoai', 20)->nullable();
            $table->string('anh_dai_dien', 500)->nullable();
            $table->date('ngay_sinh')->nullable();
            $table->enum('gioi_tinh', ['nam', 'nu', 'khac'])->nullable();
            $table->string('so_cccd', 20)->nullable()->comment('CCCD/CMND');
            $table->text('gioi_thieu')->nullable();
            // Vai tro & trang thai
            // Vai tro & trang thai
            $table->enum('vai_tro', ['tinh_nguyen_vien', 'kiem_duyet_vien', 'quan_tri_vien'])->default('tinh_nguyen_vien');
            $table->enum('trang_thai', ['cho_duyet', 'hoat_dong', 'bi_khoa'])->default('cho_duyet');
            // Dia chi cu the (dung cho AI Haversine)
            $table->unsignedBigInteger('tinh_thanh_id')->nullable();
            $table->unsignedBigInteger('phuong_xa_id')->nullable();
            $table->string('dia_chi_duong', 300)->nullable();
            $table->decimal('vi_do', 10, 7)->nullable()->comment('Vi do - AI Haversine');
            $table->decimal('kinh_do', 10, 7)->nullable()->comment('Kinh do - AI Haversine');
            // Tuy chon thong bao
            $table->json('tuy_chon_thong_bao')->nullable();
            $table->enum('khung_gio_uu_tien', ['sang', 'chieu', 'toi', 'ca_ngay', 'linh_hoat'])->nullable()->default('linh_hoat');
            // Audit & Soft Delete
            $table->timestamp('tao_luc')->useCurrent();
            $table->timestamp('cap_nhat_luc')->useCurrent()->useCurrentOnUpdate();
            $table->timestamp('xoa_luc')->nullable();

            $table->index('vai_tro', 'idx_nguoi_dung_vai_tro');
            $table->index('trang_thai', 'idx_nguoi_dung_trang_thai');
            $table->index('xoa_luc', 'idx_nguoi_dung_xoa');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nguoi_dungs');
    }
};

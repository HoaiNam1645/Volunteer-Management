<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChienDich extends Model
{
    protected $table = 'chien_dichs';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'nguoi_tao_id',
        'loai_chien_dich_id',
        'tieu_de',
        'mo_ta',
        'anh_bia',
        'dia_diem',
        'khu_vuc_id',
        'vi_do',
        'kinh_do',
        'ngay_bat_dau',
        'ngay_ket_thuc',
        'han_dang_ky',
        'so_luong_toi_da',
        'so_luong_toi_thieu',
        'muc_do_uu_tien',
        'trang_thai',
        'duyet_boi',
        'duyet_luc',
        'ly_do_tu_choi',
        'so_dang_ky',
        'so_xac_nhan',
    ];

    protected function casts(): array
    {
        return [
            'ngay_bat_dau'  => 'date',
            'ngay_ket_thuc' => 'date',
            'han_dang_ky'   => 'date',
            'duyet_luc'     => 'datetime',
            'tao_luc'       => 'datetime',
            'cap_nhat_luc'  => 'datetime',
            'xoa_luc'       => 'datetime',
            'vi_do'         => 'decimal:7',
            'kinh_do'       => 'decimal:7',
        ];
    }

    // ======================== RELATIONSHIPS ========================

    public function nguoiTao()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_tao_id');
    }

    // Alias tam thoi de tranh vo code cu trong giai doan chuyen nghiep vu.
    public function kiemDuyetVien()
    {
        return $this->nguoiTao();
    }

    public function loaiChienDich()
    {
        return $this->belongsTo(LoaiChienDich::class, 'loai_chien_dich_id');
    }

    public function kyNangs()
    {
        return $this->belongsToMany(KyNang::class, 'chien_dich_ky_nangs', 'chien_dich_id', 'ky_nang_id');
    }

    public function duyetBoi()
    {
        return $this->belongsTo(NguoiDung::class, 'duyet_boi');
    }

    public function dangKyThamGias()
    {
        return $this->hasMany(DangKyThamGia::class, 'chien_dich_id');
    }
}

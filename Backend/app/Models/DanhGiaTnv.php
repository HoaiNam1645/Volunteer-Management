<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DanhGiaTnv extends Model
{
    protected $table = 'danh_gia_tnv';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'chien_dich_id',
        'tinh_nguyen_vien_id',
        'danh_gia_boi',
        'so_sao',
        'nhan_xet',
    ];

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function tinhNguyenVien()
    {
        return $this->belongsTo(NguoiDung::class, 'tinh_nguyen_vien_id');
    }

    public function nguoiDanhGia()
    {
        return $this->belongsTo(NguoiDung::class, 'danh_gia_boi');
    }
}

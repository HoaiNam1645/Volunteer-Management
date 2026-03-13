<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DangKyThamGia extends Model
{
    protected $table = 'dang_ky_tham_gias';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'chien_dich_id',
        'nguoi_dung_id',
        'trang_thai',
        'dang_ky_luc',
        'duyet_luc',
        'xac_nhan_luc',
        'huy_luc',
        'ly_do_huy',
        'ghi_chu',
    ];

    protected function casts(): array
    {
        return [
            'dang_ky_luc'  => 'datetime',
            'duyet_luc'    => 'datetime',
            'xac_nhan_luc' => 'datetime',
            'huy_luc'      => 'datetime',
            'tao_luc'      => 'datetime',
            'cap_nhat_luc' => 'datetime',
        ];
    }

    // ======================== RELATIONSHIPS ========================

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LichSuKiemDuyetChienDich extends Model
{
    protected $table = 'lich_su_kiem_duyet_chien_dichs';

    const CREATED_AT = 'tao_luc';
    public const UPDATED_AT = null;

    protected $fillable = [
        'chien_dich_id',
        'nguoi_thuc_hien_id',
        'hanh_dong',
        'tu_trang_thai',
        'den_trang_thai',
        'ghi_chu',
        'du_lieu_bo_sung',
    ];

    protected function casts(): array
    {
        return [
            'du_lieu_bo_sung' => 'array',
            'tao_luc' => 'datetime',
        ];
    }

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function nguoiThucHien()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_thuc_hien_id');
    }
}

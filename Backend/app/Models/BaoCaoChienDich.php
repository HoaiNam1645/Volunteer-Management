<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BaoCaoChienDich extends Model
{
    protected $table = 'bao_cao_chien_dich';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'chien_dich_id',
        'nguoi_gui_id',
        'phan_loai',
        'tieu_de',
        'noi_dung',
        'trang_thai',
        'nguoi_xu_ly_id',
        'xu_ly_luc',
        'phan_hoi_xu_ly',
    ];

    protected function casts(): array
    {
        return [
            'xu_ly_luc' => 'datetime',
            'tao_luc' => 'datetime',
            'cap_nhat_luc' => 'datetime',
        ];
    }

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function nguoiGui()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_gui_id');
    }

    public function nguoiXuLy()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_xu_ly_id');
    }
}

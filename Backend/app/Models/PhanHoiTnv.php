<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PhanHoiTnv extends Model
{
    protected $table = 'phan_hoi_tnv';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'chien_dich_id',
        'nguoi_dung_id',
        'so_sao',
        'nhan_xet',
    ];

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }

    public function thePhanHois()
    {
        return $this->belongsToMany(ThePhanHoi::class, 'phan_hoi_the', 'phan_hoi_id', 'the_id');
    }
}

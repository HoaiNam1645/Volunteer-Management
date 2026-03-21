<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoaiChienDich extends Model
{
    protected $table = 'loai_chien_dichs';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'ten',
        'bieu_tuong',
        'mau_sac',
        'hoat_dong',
        'xoa_luc',
    ];

    protected function casts(): array
    {
        return [
            'hoat_dong'   => 'boolean',
            'tao_luc'     => 'datetime',
            'cap_nhat_luc' => 'datetime',
            'xoa_luc'     => 'datetime',
        ];
    }

    public function chienDichs()
    {
        return $this->hasMany(ChienDich::class, 'loai_chien_dich_id');
    }
}

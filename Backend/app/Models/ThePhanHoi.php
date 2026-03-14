<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ThePhanHoi extends Model
{
    protected $table = 'the_phan_hoi';

    const CREATED_AT = 'tao_luc';
    public const UPDATED_AT = null;

    protected $fillable = [
        'ten',
    ];

    public function phanHois()
    {
        return $this->belongsToMany(PhanHoiTnv::class, 'phan_hoi_the', 'the_id', 'phan_hoi_id');
    }
}

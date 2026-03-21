<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KhuVuc extends Model
{
    protected $table = 'khu_vucs';
    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = ['ten', 'vi_do', 'kinh_do', 'hoat_dong', 'xoa_luc'];
}

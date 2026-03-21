<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KyNang extends Model
{
    protected $table = 'ky_nangs';
    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = ['ten', 'bieu_tuong', 'mo_ta', 'hoat_dong', 'xoa_luc'];
}

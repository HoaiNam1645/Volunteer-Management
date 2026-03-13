<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KinhNghiem extends Model
{
    protected $table = 'kinh_nghiems';
    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = ['nguoi_dung_id', 'tieu_de', 'to_chuc', 'thoi_gian', 'mo_ta'];
}

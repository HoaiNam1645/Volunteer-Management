<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChungChi extends Model
{
    protected $table = 'chung_chis';
    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = ['nguoi_dung_id', 'ten', 'don_vi_cap'];
}

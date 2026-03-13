<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LichRanh extends Model
{
    protected $table = 'lich_ranhs';
    public $timestamps = false;
    const CREATED_AT = 'tao_luc';

    protected $fillable = ['nguoi_dung_id', 'thu_trong_tuan'];
}

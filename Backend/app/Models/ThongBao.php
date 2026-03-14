<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ThongBao extends Model
{
    protected $table = 'thong_bao';

    const CREATED_AT = 'tao_luc';
    public const UPDATED_AT = null;

    protected $fillable = [
        'nguoi_dung_id',
        'nguoi_gui_id',
        'loai',
        'tieu_de',
        'noi_dung',
        'loai_tham_chieu',
        'tham_chieu_id',
        'da_doc',
        'doc_luc',
        'gui_qua',
    ];

    protected function casts(): array
    {
        return [
            'da_doc' => 'boolean',
            'doc_luc' => 'datetime',
            'tao_luc' => 'datetime',
        ];
    }

    public function nguoiNhan()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }

    public function nguoiGui()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_gui_id');
    }
}

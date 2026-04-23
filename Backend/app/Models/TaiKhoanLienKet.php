<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaiKhoanLienKet extends Model
{
    protected $table = 'tai_khoan_lien_ket';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'nguoi_dung_id',
        'nha_cung_cap',
        'id_nha_cung_cap',
    ];

    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }
}

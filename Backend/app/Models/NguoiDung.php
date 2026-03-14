<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

class NguoiDung extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    protected $table = 'nguoi_dungs';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'ho_ten',
        'email',
        'mat_khau',
        'so_dien_thoai',
        'anh_dai_dien',
        'ngay_sinh',
        'gioi_tinh',
        'so_cccd',
        'gioi_thieu',
        'vai_tro',
        'trang_thai',
        'xac_thuc_email_luc',
        // Địa chỉ
        'tinh_thanh_id',
        'phuong_xa_id',
        'dia_chi_duong',
        'vi_do',
        'kinh_do',
        // Tùy chọn
        'khung_gio_uu_tien',
        'tuy_chon_thong_bao',
    ];

    protected $hidden = [
        'mat_khau',
    ];

    protected function casts(): array
    {
        return [
            'xac_thuc_email_luc' => 'datetime',
            'mat_khau'           => 'hashed',
            'tao_luc'            => 'datetime',
            'cap_nhat_luc'       => 'datetime',
            'xoa_luc'            => 'datetime',
            'tuy_chon_thong_bao' => 'array',
        ];
    }

    // Override password field name cho Auth
    public function getAuthPassword()
    {
        return $this->mat_khau;
    }

    // JWT Subject
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [
            'vai_tro' => $this->vai_tro,
        ];
    }

    // ======================== RELATIONSHIPS ========================

    public function kyNangs()
    {
        return $this->belongsToMany(\App\Models\KyNang::class, 'nguoi_dung_ky_nangs', 'nguoi_dung_id', 'ky_nang_id');
    }

    public function khuVucs()
    {
        return $this->belongsToMany(\App\Models\KhuVuc::class, 'nguoi_dung_khu_vucs', 'nguoi_dung_id', 'khu_vuc_id');
    }

    public function lichRanhs()
    {
        return $this->hasMany(\App\Models\LichRanh::class, 'nguoi_dung_id');
    }

    public function kinhNghiems()
    {
        return $this->hasMany(\App\Models\KinhNghiem::class, 'nguoi_dung_id');
    }

    public function chungChis()
    {
        return $this->hasMany(\App\Models\ChungChi::class, 'nguoi_dung_id');
    }

    public function chienDichs()
    {
        return $this->hasMany(\App\Models\ChienDich::class, 'nguoi_tao_id');
    }
}

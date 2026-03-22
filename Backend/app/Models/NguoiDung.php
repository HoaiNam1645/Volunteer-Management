<?php

namespace App\Models;

use App\Support\PermissionRegistry;
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
        'quyen_han',
        'trang_thai',
        'xac_thuc_email_luc',
        'xoa_luc',
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
            'quyen_han'          => 'array',
            'tao_luc'            => 'datetime',
            'cap_nhat_luc'       => 'datetime',
            'xoa_luc'            => 'datetime',
            'tuy_chon_thong_bao' => 'array',
        ];
    }

    public function getAnhDaiDienAttribute($value): ?string
    {
        if (!$value) {
            return null;
        }

        if (preg_match('#^https?://#', $value)) {
            return $value;
        }

        $path = str_starts_with($value, '/') ? $value : '/' . ltrim($value, '/');
        $request = request();
        $baseUrl = $request
            ? rtrim($request->getSchemeAndHttpHost(), '/')
            : rtrim(config('app.url', 'http://127.0.0.1:8000'), '/');

        return $baseUrl . $path;
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
            'quyen_han' => $this->layTatCaQuyen(),
        ];
    }

    public function dangDungQuyenMacDinh(): bool
    {
        return is_null($this->getRawOriginal('quyen_han'));
    }

    public function layQuyenMacDinhTheoVaiTro(): array
    {
        return PermissionRegistry::defaultsForRole($this->vai_tro);
    }

    public function layTatCaQuyen(): array
    {
        if ($this->dangDungQuyenMacDinh()) {
            return $this->layQuyenMacDinhTheoVaiTro();
        }

        return PermissionRegistry::normalize($this->quyen_han ?? []);
    }

    public function coQuyen(string $permission): bool
    {
        return in_array($permission, $this->layTatCaQuyen(), true);
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

    public function dangKyThamGias()
    {
        return $this->hasMany(\App\Models\DangKyThamGia::class, 'nguoi_dung_id');
    }

    public function thongBaosNhan()
    {
        return $this->hasMany(\App\Models\ThongBao::class, 'nguoi_dung_id');
    }

    public function thongBaosGui()
    {
        return $this->hasMany(\App\Models\ThongBao::class, 'nguoi_gui_id');
    }

    public function phanHoiTnvs()
    {
        return $this->hasMany(\App\Models\PhanHoiTnv::class, 'nguoi_dung_id');
    }

    public function baoCaoChienDichs()
    {
        return $this->hasMany(\App\Models\BaoCaoChienDich::class, 'nguoi_gui_id');
    }
}

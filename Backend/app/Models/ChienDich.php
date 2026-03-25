<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChienDich extends Model
{
    protected $table = 'chien_dichs';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = 'cap_nhat_luc';

    protected $fillable = [
        'nguoi_tao_id',
        'loai_chien_dich_id',
        'tieu_de',
        'mo_ta',
        'anh_bia',
        'dia_diem',
        'khu_vuc_id',
        'vi_do',
        'kinh_do',
        'ngay_bat_dau',
        'ngay_ket_thuc',
        'thoi_gian_bat_dau_thuc_te',
        'thoi_gian_ket_thuc_thuc_te',
        'han_dang_ky',
        'so_luong_toi_da',
        'so_luong_toi_thieu',
        'muc_do_uu_tien',
        'trang_thai',
        'duyet_boi',
        'duyet_luc',
        'ly_do_tu_choi',
        'so_dang_ky',
        'so_xac_nhan',
    ];

    protected function casts(): array
    {
        return [
            'ngay_bat_dau'  => 'date',
            'ngay_ket_thuc' => 'date',
            'thoi_gian_bat_dau_thuc_te' => 'datetime',
            'thoi_gian_ket_thuc_thuc_te' => 'datetime',
            'han_dang_ky'   => 'date',
            'duyet_luc'     => 'datetime',
            'tao_luc'       => 'datetime',
            'cap_nhat_luc'  => 'datetime',
            'xoa_luc'       => 'datetime',
            'vi_do'         => 'decimal:7',
            'kinh_do'       => 'decimal:7',
        ];
    }

    public function getAnhBiaAttribute($value): ?string
    {
        if (!$value) {
            return null;
        }

        $baseUrl = $this->resolveMediaBaseUrl();

        if (preg_match('#/storage/[^\s"\']+#', $value, $matches)) {
            return $baseUrl . $matches[0];
        }

        if (preg_match('#^https?://#', $value)) {
            return $value;
        }

        if (str_starts_with($value, 'storage/')) {
            return $baseUrl . '/' . ltrim($value, '/');
        }

        if (str_starts_with($value, '/storage/')) {
            return $baseUrl . $value;
        }

        return $value;
    }

    private function resolveMediaBaseUrl(): string
    {
        $request = request();

        if ($request) {
            return rtrim($request->getSchemeAndHttpHost(), '/');
        }

        return rtrim(config('app.url', 'http://127.0.0.1:8000'), '/');
    }

    // ======================== RELATIONSHIPS ========================

    public function nguoiTao()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_tao_id');
    }

    // Alias tam thoi de tranh vo code cu trong giai doan chuyen nghiep vu.
    public function kiemDuyetVien()
    {
        return $this->nguoiTao();
    }

    public function loaiChienDich()
    {
        return $this->belongsTo(LoaiChienDich::class, 'loai_chien_dich_id');
    }

    public function kyNangs()
    {
        return $this->belongsToMany(KyNang::class, 'chien_dich_ky_nangs', 'chien_dich_id', 'ky_nang_id');
    }

    public function duyetBoi()
    {
        return $this->belongsTo(NguoiDung::class, 'duyet_boi');
    }

    public function dangKyThamGias()
    {
        return $this->hasMany(DangKyThamGia::class, 'chien_dich_id');
    }

    public function feedbacks()
    {
        return $this->hasMany(PhanHoiTnv::class, 'chien_dich_id');
    }

    public function baoCaos()
    {
        return $this->hasMany(BaoCaoChienDich::class, 'chien_dich_id');
    }

    public function lichSuKiemDuyets()
    {
        return $this->hasMany(LichSuKiemDuyetChienDich::class, 'chien_dich_id');
    }

    public function danhGiaTnvs()
    {
        return $this->hasMany(DanhGiaTnv::class, 'chien_dich_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HinhAnhChienDich extends Model
{
    protected $table = 'hinh_anh_chien_dich';

    const CREATED_AT = 'tao_luc';
    const UPDATED_AT = null;

    protected $fillable = [
        'chien_dich_id',
        'duong_dan_anh',
        'thu_tu',
    ];

    public function getDuongDanAnhAttribute($value): ?string
    {
        if (!$value || !is_string($value)) {
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

    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }
}

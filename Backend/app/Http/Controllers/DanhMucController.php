<?php

namespace App\Http\Controllers;

use App\Models\KhuVuc;
use App\Models\KyNang;
use App\Models\LoaiChienDich;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class DanhMucController extends Controller
{
    // Danh sách kỹ năng (public - cho trang đăng ký)
    public function getKyNang()
    {
        $data = DB::table('ky_nangs')
            ->where('hoat_dong', 1)
            ->whereNull('xoa_luc')
            ->select('id', 'ten', 'bieu_tuong', 'mo_ta')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách khu vực (public - cho trang đăng ký)
    public function getKhuVuc()
    {
        $data = DB::table('khu_vucs')
            ->where('hoat_dong', 1)
            ->whereNull('xoa_luc')
            ->select('id', 'ten')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách tỉnh/thành phố (public)
    public function getTinhThanh()
    {
        $data = DB::table('tinh_thanh')
            ->select('id', 'ma', 'ten', 'vi_do', 'kinh_do')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status' => 1,
            'data'   => $data,
        ]);
    }

    // Danh sách phường/xã theo tỉnh/thành phố (public)
    public function getPhuongXa(Request $request)
    {
        $query = DB::table('phuong_xa')
            ->select('id', 'tinh_thanh_id', 'ma', 'ten', 'vi_do', 'kinh_do')
            ->orderBy('ten');

        if ($request->has('tinh_thanh_id') && $request->tinh_thanh_id) {
            $query->where('tinh_thanh_id', $request->tinh_thanh_id);
        }

        return response()->json([
            'status' => 1,
            'data'   => $query->get(),
        ]);
    }

    public function danhSachQuanLy()
    {
        $skillUserCounts = DB::table('nguoi_dung_ky_nangs')
            ->select('ky_nang_id', DB::raw('COUNT(*) as total'))
            ->groupBy('ky_nang_id')
            ->pluck('total', 'ky_nang_id');
        $skillCampaignCounts = DB::table('chien_dich_ky_nangs')
            ->select('ky_nang_id', DB::raw('COUNT(*) as total'))
            ->groupBy('ky_nang_id')
            ->pluck('total', 'ky_nang_id');
        $regionUserCounts = DB::table('nguoi_dung_khu_vucs')
            ->select('khu_vuc_id', DB::raw('COUNT(*) as total'))
            ->groupBy('khu_vuc_id')
            ->pluck('total', 'khu_vuc_id');
        $regionCampaignCounts = DB::table('chien_dichs')
            ->whereNull('xoa_luc')
            ->select('khu_vuc_id', DB::raw('COUNT(*) as total'))
            ->groupBy('khu_vuc_id')
            ->pluck('total', 'khu_vuc_id');
        $typeCampaignCounts = DB::table('chien_dichs')
            ->whereNull('xoa_luc')
            ->select('loai_chien_dich_id', DB::raw('COUNT(*) as total'))
            ->groupBy('loai_chien_dich_id')
            ->pluck('total', 'loai_chien_dich_id');

        return response()->json([
            'status'  => 1,
            'message' => 'Lấy danh mục quản trị thành công.',
            'data'    => [
                'ky_nangs' => KyNang::query()
                    ->whereNull('xoa_luc')
                    ->orderByDesc('hoat_dong')
                    ->orderBy('ten')
                    ->get()
                    ->map(fn ($item) => [
                        'id'             => $item->id,
                        'ten'            => $item->ten,
                        'bieu_tuong'     => $item->bieu_tuong,
                        'mo_ta'          => $item->mo_ta,
                        'hoat_dong'      => (bool) $item->hoat_dong,
                        'nguoi_dung_count' => (int) ($skillUserCounts[$item->id] ?? 0),
                        'chien_dich_count' => (int) ($skillCampaignCounts[$item->id] ?? 0),
                    ])->values(),
                'khu_vucs' => KhuVuc::query()
                    ->whereNull('xoa_luc')
                    ->orderByDesc('hoat_dong')
                    ->orderBy('ten')
                    ->get()
                    ->map(fn ($item) => [
                        'id'               => $item->id,
                        'ten'              => $item->ten,
                        'vi_do'            => $item->vi_do,
                        'kinh_do'          => $item->kinh_do,
                        'hoat_dong'        => (bool) $item->hoat_dong,
                        'nguoi_dung_count' => (int) ($regionUserCounts[$item->id] ?? 0),
                        'chien_dich_count' => (int) ($regionCampaignCounts[$item->id] ?? 0),
                    ])->values(),
                'loai_chien_dichs' => LoaiChienDich::query()
                    ->whereNull('xoa_luc')
                    ->orderByDesc('hoat_dong')
                    ->orderBy('ten')
                    ->get()
                    ->map(fn ($item) => [
                        'id'               => $item->id,
                        'ten'              => $item->ten,
                        'bieu_tuong'       => $item->bieu_tuong,
                        'mau_sac'          => $item->mau_sac,
                        'hoat_dong'        => (bool) $item->hoat_dong,
                        'chien_dich_count' => (int) ($typeCampaignCounts[$item->id] ?? 0),
                    ])->values(),
            ],
        ]);
    }

    public function taoQuanLy(Request $request, string $type)
    {
        [$modelClass, $payload] = $this->resolveCategoryPayload($type, $request);
        $record = $modelClass::create($payload);

        return response()->json([
            'status'  => 1,
            'message' => 'Tạo danh mục thành công.',
            'data'    => $record->fresh(),
        ], 201);
    }

    public function capNhatQuanLy(Request $request, string $type, int $id)
    {
        [$modelClass, $payload] = $this->resolveCategoryPayload($type, $request, $id);

        $record = $modelClass::query()->whereNull('xoa_luc')->findOrFail($id);
        $record->update($payload);

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật danh mục thành công.',
            'data'    => $record->fresh(),
        ]);
    }

    public function xoaQuanLy(string $type, int $id)
    {
        [$modelClass, $usageCount, $usageMessage] = $this->resolveDeleteContext($type, $id);

        if ($usageCount > 0) {
            return response()->json([
                'status'  => 0,
                'message' => $usageMessage,
            ], 422);
        }

        $record = $modelClass::query()->whereNull('xoa_luc')->findOrFail($id);
        $record->update(['xoa_luc' => now()]);

        return response()->json([
            'status'  => 1,
            'message' => 'Xóa danh mục thành công.',
        ]);
    }

    private function resolveCategoryPayload(string $type, Request $request, ?int $id = null): array
    {
        switch ($type) {
            case 'ky-nang':
                $validated = $request->validate([
                    'ten'        => ['required', 'string', 'max:100', Rule::unique('ky_nangs', 'ten')->ignore($id)],
                    'bieu_tuong' => 'nullable|string|max:100',
                    'mo_ta'      => 'nullable|string|max:500',
                    'hoat_dong'  => 'nullable|boolean',
                ]);

                return [
                    KyNang::class,
                    [
                        'ten'        => $validated['ten'],
                        'bieu_tuong' => $validated['bieu_tuong'] ?? null,
                        'mo_ta'      => $validated['mo_ta'] ?? null,
                        'hoat_dong'  => $request->boolean('hoat_dong', true),
                    ],
                ];

            case 'khu-vuc':
                $validated = $request->validate([
                    'ten'        => ['required', 'string', 'max:150', Rule::unique('khu_vucs', 'ten')->ignore($id)],
                    'vi_do'      => 'nullable|numeric',
                    'kinh_do'    => 'nullable|numeric',
                    'hoat_dong'  => 'nullable|boolean',
                ]);

                return [
                    KhuVuc::class,
                    [
                        'ten'       => $validated['ten'],
                        'vi_do'     => $validated['vi_do'] ?? null,
                        'kinh_do'   => $validated['kinh_do'] ?? null,
                        'hoat_dong' => $request->boolean('hoat_dong', true),
                    ],
                ];

            case 'loai-chien-dich':
                $validated = $request->validate([
                    'ten'        => ['required', 'string', 'max:100', Rule::unique('loai_chien_dichs', 'ten')->ignore($id)],
                    'bieu_tuong' => 'nullable|string|max:100',
                    'mau_sac'    => 'nullable|string|max:50',
                    'hoat_dong'  => 'nullable|boolean',
                ]);

                return [
                    LoaiChienDich::class,
                    [
                        'ten'        => $validated['ten'],
                        'bieu_tuong' => $validated['bieu_tuong'] ?? null,
                        'mau_sac'    => $validated['mau_sac'] ?? null,
                        'hoat_dong'  => $request->boolean('hoat_dong', true),
                    ],
                ];
        }

        abort(404, 'Loại danh mục không hợp lệ.');
    }

    private function resolveDeleteContext(string $type, int $id): array
    {
        return match ($type) {
            'ky-nang' => [
                KyNang::class,
                (int) DB::table('nguoi_dung_ky_nangs')->where('ky_nang_id', $id)->count()
                    + (int) DB::table('chien_dich_ky_nangs')->where('ky_nang_id', $id)->count(),
                'Không thể xóa kỹ năng đang được sử dụng. Hãy cập nhật hoặc ngừng hoạt động thay vì xóa.',
            ],
            'khu-vuc' => [
                KhuVuc::class,
                (int) DB::table('nguoi_dung_khu_vucs')->where('khu_vuc_id', $id)->count()
                    + (int) DB::table('chien_dichs')->where('khu_vuc_id', $id)->whereNull('xoa_luc')->count(),
                'Không thể xóa khu vực đang được sử dụng. Hãy cập nhật hoặc ngừng hoạt động thay vì xóa.',
            ],
            'loai-chien-dich' => [
                LoaiChienDich::class,
                (int) DB::table('chien_dichs')->where('loai_chien_dich_id', $id)->whereNull('xoa_luc')->count(),
                'Không thể xóa loại chiến dịch đang được sử dụng. Hãy cập nhật hoặc ngừng hoạt động thay vì xóa.',
            ],
            default => abort(404, 'Loại danh mục không hợp lệ.'),
        };
    }
}

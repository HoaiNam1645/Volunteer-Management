<?php

namespace App\Http\Controllers;

use App\Models\NguoiDung;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class NguoiDungController extends Controller
{
    // ======================== DANH SÁCH NGƯỜI DÙNG (ADMIN) ========================
    public function danhSachQuanLy(Request $request)
    {
        $perPage = max(1, min(50, (int) $request->input('per_page', 10)));

        $baseQuery = NguoiDung::query()->whereNull('xoa_luc');
        $query = (clone $baseQuery)->withCount(['dangKyThamGias', 'chienDichs']);

        if ($request->filled('tu_khoa')) {
            $tuKhoa = $request->tu_khoa;
            $query->where(function ($q) use ($tuKhoa) {
                $q->where('ho_ten', 'like', "%{$tuKhoa}%")
                    ->orWhere('email', 'like', "%{$tuKhoa}%")
                    ->orWhere('so_dien_thoai', 'like', "%{$tuKhoa}%");
            });
        }

        if ($request->filled('vai_tro')) {
            $query->where('vai_tro', $request->vai_tro);
        }

        if ($request->filled('trang_thai')) {
            $query->where('trang_thai', $request->trang_thai);
        }

        $paginated = $query->orderByDesc('tao_luc')->paginate($perPage);

        $stats = [
            'tong'       => (clone $baseQuery)->count(),
            'cho_duyet'  => (clone $baseQuery)->where('trang_thai', 'cho_duyet')->count(),
            'bi_khoa'    => (clone $baseQuery)->where('trang_thai', 'bi_khoa')->count(),
            'hoat_dong'  => (clone $baseQuery)->where('trang_thai', 'hoat_dong')->count(),
        ];

        return response()->json([
            'status'       => 1,
            'message'      => 'Lấy danh sách người dùng thành công.',
            'data'         => collect($paginated->items())->map(fn ($user) => $this->adminUserPayload($user))->values(),
            'current_page' => $paginated->currentPage(),
            'last_page'    => $paginated->lastPage(),
            'per_page'     => $paginated->perPage(),
            'total'        => $paginated->total(),
            'meta'         => [
                'stats' => $stats,
            ],
        ]);
    }

    public function taoQuanLy(Request $request)
    {
        $payload = $this->validateAdminUser($request);

        $user = NguoiDung::create($payload);
        $user->loadCount(['dangKyThamGias', 'chienDichs']);

        return response()->json([
            'status'  => 1,
            'message' => 'Tạo tài khoản thành công.',
            'data'    => $this->adminUserPayload($user),
        ], 201);
    }

    public function capNhatQuanLy(Request $request, int $id)
    {
        $user = NguoiDung::query()->whereNull('xoa_luc')->findOrFail($id);

        if ($user->id === auth('api')->id() && $request->input('trang_thai') === 'bi_khoa') {
            return response()->json([
                'status'  => 0,
                'message' => 'Bạn không thể tự khóa tài khoản của chính mình.',
            ], 422);
        }

        $payload = $this->validateAdminUser($request, $user);
        $user->update($payload);
        $user->loadCount(['dangKyThamGias', 'chienDichs']);

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật tài khoản thành công.',
            'data'    => $this->adminUserPayload($user->fresh()),
        ]);
    }

    public function capNhatTrangThaiQuanLy(Request $request, int $id)
    {
        $request->validate([
            'trang_thai' => 'required|in:cho_duyet,hoat_dong,bi_khoa',
        ]);

        $user = NguoiDung::query()->whereNull('xoa_luc')->findOrFail($id);

        if ($user->id === auth('api')->id() && $request->trang_thai === 'bi_khoa') {
            return response()->json([
                'status'  => 0,
                'message' => 'Bạn không thể tự khóa tài khoản của chính mình.',
            ], 422);
        }

        $updates = ['trang_thai' => $request->trang_thai];
        if ($request->trang_thai === 'hoat_dong' && !$user->xac_thuc_email_luc) {
            $updates['xac_thuc_email_luc'] = now();
        }

        $user->update($updates);
        $user->loadCount(['dangKyThamGias', 'chienDichs']);

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật trạng thái thành công.',
            'data'    => $this->adminUserPayload($user->fresh()),
        ]);
    }

    public function xoaQuanLy(int $id)
    {
        $user = NguoiDung::query()->whereNull('xoa_luc')->findOrFail($id);

        if ($user->id === auth('api')->id()) {
            return response()->json([
                'status'  => 0,
                'message' => 'Bạn không thể tự xóa tài khoản của chính mình.',
            ], 422);
        }

        $user->update([
            'xoa_luc' => now(),
        ]);

        return response()->json([
            'status'  => 1,
            'message' => 'Xóa người dùng thành công.',
        ]);
    }

    private function validateAdminUser(Request $request, ?NguoiDung $user = null): array
    {
        $userId = $user?->id;

        $validated = $request->validate([
            'ho_ten'              => 'required|string|max:150',
            'email'               => ['required', 'email', 'max:255', Rule::unique('nguoi_dungs', 'email')->ignore($userId)],
            'so_dien_thoai'       => 'nullable|string|max:20',
            'vai_tro'             => 'required|in:tinh_nguyen_vien,kiem_duyet_vien,quan_tri_vien',
            'trang_thai'          => 'required|in:cho_duyet,hoat_dong,bi_khoa',
            'mat_khau'            => ($user ? 'nullable' : 'required') . '|string|min:8',
            'xac_thuc_email'      => 'nullable|boolean',
        ]);

        $payload = [
            'ho_ten'        => $validated['ho_ten'],
            'email'         => $validated['email'],
            'so_dien_thoai' => $validated['so_dien_thoai'] ?? null,
            'vai_tro'       => $validated['vai_tro'],
            'trang_thai'    => $validated['trang_thai'],
        ];

        if (!empty($validated['mat_khau'])) {
            $payload['mat_khau'] = $validated['mat_khau'];
        }

        $xacThucEmail = $request->boolean('xac_thuc_email', $validated['trang_thai'] === 'hoat_dong');
        $payload['xac_thuc_email_luc'] = $xacThucEmail ? ($user?->xac_thuc_email_luc ?? now()) : null;

        return $payload;
    }

    private function adminUserPayload(NguoiDung $user): array
    {
        $campaignCount = $user->vai_tro === 'tinh_nguyen_vien'
            ? (int) ($user->dang_ky_tham_gias_count ?? 0)
            : (int) ($user->chien_dichs_count ?? 0);

        return [
            'id'                => $user->id,
            'ho_ten'            => $user->ho_ten,
            'email'             => $user->email,
            'so_dien_thoai'     => $user->so_dien_thoai,
            'vai_tro'           => $user->vai_tro,
            'trang_thai'        => $user->trang_thai,
            'anh_dai_dien'      => $user->anh_dai_dien,
            'xac_thuc_email_luc'=> $user->xac_thuc_email_luc,
            'da_xac_thuc_email' => !is_null($user->xac_thuc_email_luc),
            'tao_luc'           => $user->tao_luc,
            'campaign_count'    => $campaignCount,
        ];
    }

    // ======================== LẤY THÔNG TIN CÁ NHÂN ========================
    public function layThongTin(Request $request)
    {
        $user = auth('api')->user();

        return response()->json([
            'status'  => 1,
            'message' => 'Lấy thông tin thành công.',
            'data'    => [
                'id'              => $user->id,
                'ho_ten'          => $user->ho_ten,
                'email'           => $user->email,
                'so_dien_thoai'   => $user->so_dien_thoai,
                'ngay_sinh'       => $user->ngay_sinh,
                'gioi_tinh'       => $user->gioi_tinh,
                'so_cccd'         => $user->so_cccd,
                'gioi_thieu'      => $user->gioi_thieu,
                'anh_dai_dien'    => $user->anh_dai_dien,
                'tinh_thanh_id'   => $user->tinh_thanh_id,
                'phuong_xa_id'    => $user->phuong_xa_id,
                'dia_chi_duong'   => $user->dia_chi_duong,
                'vi_do'           => $user->vi_do,
                'kinh_do'         => $user->kinh_do,
                'vai_tro'         => $user->vai_tro,
                'tuy_chon_thong_bao' => $user->tuy_chon_thong_bao,
            ],
        ]);
    }

    // ======================== CẬP NHẬT THÔNG TIN CÁ NHÂN ========================
    public function capNhatThongTin(Request $request)
    {
        $request->validate([
            'ho_ten'        => 'required|string|max:150',
            'so_dien_thoai' => 'nullable|string|max:20',
            'ngay_sinh'     => 'nullable|date',
            'gioi_tinh'     => 'nullable|in:nam,nu,khac',
            'so_cccd'       => 'nullable|string|max:20',
            'gioi_thieu'    => 'nullable|string|max:500',
            'anh_dai_dien'  => 'nullable|image|max:5120',
            'tinh_thanh_id' => 'nullable|integer',
            'phuong_xa_id'  => 'nullable|integer',
            'dia_chi_duong' => 'nullable|string|max:300',
            'vi_do'         => 'nullable|numeric',
            'kinh_do'       => 'nullable|numeric',
            'tuy_chon_thong_bao' => 'nullable|array',
        ]);

        $user = auth('api')->user();

        $payload = $request->only([
            'ho_ten',
            'so_dien_thoai',
            'ngay_sinh',
            'gioi_tinh',
            'so_cccd',
            'gioi_thieu',
            'tinh_thanh_id',
            'phuong_xa_id',
            'dia_chi_duong',
            'vi_do',
            'kinh_do',
            'tuy_chon_thong_bao',
        ]);

        if ($request->hasFile('anh_dai_dien')) {
            if ($user->getRawOriginal('anh_dai_dien')) {
                $oldPath = preg_replace('#^/?storage/#', '', (string) $user->getRawOriginal('anh_dai_dien'));
                if ($oldPath) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            $payload['anh_dai_dien'] = '/storage/' . $request->file('anh_dai_dien')->store('avatars', 'public');
        }

        $user->update($payload);

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật thông tin thành công.',
            'data'    => $user->fresh(),
        ]);
    }

    // ======================== ĐỔI MẬT KHẨU ========================
    public function doiMatKhau(Request $request)
    {
        $request->validate([
            'mat_khau_cu'           => 'required|string',
            'mat_khau_moi'          => 'required|string|min:8|confirmed|different:mat_khau_cu',
        ]);

        $user = auth('api')->user();

        if (!Hash::check($request->mat_khau_cu, $user->mat_khau)) {
            return response()->json([
                'status'  => 0,
                'message' => 'Mật khẩu hiện tại không chính xác.',
            ], 422);
        }

        $user->update(['mat_khau' => $request->mat_khau_moi]);

        return response()->json([
            'status'  => 1,
            'message' => 'Đổi mật khẩu thành công.',
        ]);
    }

    // ======================== LẤY HỒ SƠ NĂNG LỰC ========================
    public function layHoSoNangLuc(Request $request)
    {
        $user = auth('api')->user();

        $ky_nang_ids = $user->kyNangs()->pluck('ky_nangs.id')->toArray();
        $khu_vuc_ids = $user->khuVucs()->pluck('khu_vucs.id')->toArray();
        $lich_ranh   = $user->lichRanhs()->pluck('thu_trong_tuan')->toArray();

        $kinh_nghiems = $user->kinhNghiems()->orderBy('tao_luc', 'desc')->get()->map(fn($kn) => [
            'id'        => $kn->id,
            'tieu_de'   => $kn->tieu_de,
            'to_chuc'   => $kn->to_chuc,
            'thoi_gian' => $kn->thoi_gian,
            'mo_ta'     => $kn->mo_ta,
        ]);

        $chung_chis = $user->chungChis()->orderBy('tao_luc', 'desc')->get()->map(fn($cc) => [
            'id'         => $cc->id,
            'ten'        => $cc->ten,
            'don_vi_cap' => $cc->don_vi_cap,
        ]);

        return response()->json([
            'status'  => 1,
            'message' => 'Lấy hồ sơ năng lực thành công.',
            'data'    => [
                'ho_ten'            => $user->ho_ten,
                'email'             => $user->email,
                'anh_dai_dien'      => $user->anh_dai_dien,
                'ky_nang_ids'       => $ky_nang_ids,
                'khu_vuc_ids'       => $khu_vuc_ids,
                'lich_ranh'         => $lich_ranh,
                'khung_gio_uu_tien' => $user->khung_gio_uu_tien ?? 'linh_hoat',
                'kinh_nghiems'      => $kinh_nghiems,
                'chung_chis'        => $chung_chis,
            ],
        ]);
    }

    // ======================== LƯU HỒ SƠ NĂNG LỰC ========================
    public function luuHoSoNangLuc(Request $request)
    {
        $request->validate([
            'ky_nang_ids'          => 'nullable|array',
            'ky_nang_ids.*'        => 'integer|exists:ky_nangs,id',
            'khu_vuc_ids'          => 'nullable|array',
            'khu_vuc_ids.*'        => 'integer|exists:khu_vucs,id',
            'lich_ranh'            => 'nullable|array',
            'lich_ranh.*'          => 'in:thu_hai,thu_ba,thu_tu,thu_nam,thu_sau,thu_bay,chu_nhat',
            'khung_gio_uu_tien'    => 'nullable|in:sang,chieu,toi,ca_ngay,linh_hoat',
            'kinh_nghiems'         => 'nullable|array',
            'kinh_nghiems.*.tieu_de' => 'required|string|max:255',
            'kinh_nghiems.*.to_chuc' => 'nullable|string|max:255',
            'kinh_nghiems.*.thoi_gian' => 'nullable|string|max:100',
            'kinh_nghiems.*.mo_ta'   => 'nullable|string',
            'chung_chis'           => 'nullable|array',
            'chung_chis.*.ten'     => 'required|string|max:255',
            'chung_chis.*.don_vi_cap' => 'nullable|string|max:255',
        ]);

        $user = auth('api')->user();

        DB::transaction(function () use ($request, $user) {
            // Sync kỹ năng
            $user->kyNangs()->sync($request->ky_nang_ids ?? []);

            // Sync khu vực
            $user->khuVucs()->sync($request->khu_vuc_ids ?? []);

            // Sync lịch rảnh (delete + insert)
            $user->lichRanhs()->delete();
            if ($request->lich_ranh && count($request->lich_ranh) > 0) {
                $lich_data = array_map(fn($day) => [
                    'nguoi_dung_id' => $user->id,
                    'thu_trong_tuan' => $day,
                    'tao_luc' => now(),
                ], $request->lich_ranh);
                DB::table('lich_ranhs')->insert($lich_data);
            }

            // Khung giờ ưu tiên
            $user->update(['khung_gio_uu_tien' => $request->khung_gio_uu_tien ?? 'linh_hoat']);

            // Sync kinh nghiệm (delete + re-create)
            $user->kinhNghiems()->delete();
            if ($request->kinh_nghiems && count($request->kinh_nghiems) > 0) {
                foreach ($request->kinh_nghiems as $kn) {
                    $user->kinhNghiems()->create([
                        'tieu_de'   => $kn['tieu_de'],
                        'to_chuc'   => $kn['to_chuc'] ?? null,
                        'thoi_gian' => $kn['thoi_gian'] ?? null,
                        'mo_ta'     => $kn['mo_ta'] ?? null,
                    ]);
                }
            }

            // Sync chứng chỉ (delete + re-create)
            $user->chungChis()->delete();
            if ($request->chung_chis && count($request->chung_chis) > 0) {
                foreach ($request->chung_chis as $cc) {
                    $user->chungChis()->create([
                        'ten'        => $cc['ten'],
                        'don_vi_cap' => $cc['don_vi_cap'] ?? null,
                    ]);
                }
            }
        });

        return response()->json([
            'status'  => 1,
            'message' => 'Lưu hồ sơ năng lực thành công.',
        ]);
    }
}

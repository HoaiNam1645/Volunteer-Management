<?php

namespace App\Http\Controllers;

use App\Models\ChienDich;
use App\Models\LoaiChienDich;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChienDichController extends Controller
{
    // ======================== DANH SÁCH CHIẾN DỊCH CỦA KDV ========================
    public function danhSach(Request $request)
    {
        $user = auth('api')->user();
        $perPage = (int) $request->input('per_page', 10);

        $query = ChienDich::where('kiem_duyet_vien_id', $user->id)
            ->whereNull('xoa_luc')
            ->with(['loaiChienDich:id,ten,bieu_tuong,mau_sac', 'kyNangs:ky_nangs.id,ten']);

        // Filter by status
        if ($request->filled('trang_thai') && $request->trang_thai !== 'all') {
            $query->where('trang_thai', $request->trang_thai);
        }

        // Search by title or location
        if ($request->filled('tu_khoa')) {
            $keyword = $request->tu_khoa;
            $query->where(function ($q) use ($keyword) {
                $q->where('tieu_de', 'like', "%{$keyword}%")
                    ->orWhere('dia_diem', 'like', "%{$keyword}%");
            });
        }

        // Filter by category
        if ($request->filled('loai_chien_dich_id')) {
            $query->where('loai_chien_dich_id', $request->loai_chien_dich_id);
        }

        // Filter by priority
        if ($request->filled('muc_do_uu_tien')) {
            $query->where('muc_do_uu_tien', $request->muc_do_uu_tien);
        }

        $paginated = $query->orderByDesc('tao_luc')->paginate($perPage);

        $mapped = $paginated->getCollection()->map(function ($cd) {
            return [
                'id'                  => $cd->id,
                'tieu_de'             => $cd->tieu_de,
                'mo_ta'               => $cd->mo_ta,
                'anh_bia'             => $cd->anh_bia,
                'dia_diem'            => $cd->dia_diem,
                'vi_do'               => $cd->vi_do,
                'kinh_do'             => $cd->kinh_do,
                'ngay_bat_dau'        => $cd->ngay_bat_dau?->format('Y-m-d'),
                'ngay_ket_thuc'       => $cd->ngay_ket_thuc?->format('Y-m-d'),
                'han_dang_ky'         => $cd->han_dang_ky?->format('Y-m-d'),
                'so_luong_toi_da'     => $cd->so_luong_toi_da,
                'so_luong_toi_thieu'  => $cd->so_luong_toi_thieu,
                'muc_do_uu_tien'      => $cd->muc_do_uu_tien,
                'trang_thai'          => $cd->trang_thai,
                'so_dang_ky'          => $cd->so_dang_ky,
                'so_xac_nhan'         => $cd->so_xac_nhan,
                'loai_chien_dich_id'  => $cd->loai_chien_dich_id,
                'loai_chien_dich'     => $cd->loaiChienDich,
                'ky_nang_ids'         => $cd->kyNangs->pluck('id')->toArray(),
                'tao_luc'             => $cd->tao_luc?->format('Y-m-d H:i:s'),
            ];
        });

        return response()->json([
            'status'       => 1,
            'message'      => 'Lấy danh sách chiến dịch thành công.',
            'data'         => $mapped->values(),
            'current_page' => $paginated->currentPage(),
            'last_page'    => $paginated->lastPage(),
            'per_page'     => $paginated->perPage(),
            'total'        => $paginated->total(),
        ]);
    }

    // ======================== CHI TIẾT CHIẾN DỊCH ========================
    public function chiTiet(Request $request, $id)
    {
        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('kiem_duyet_vien_id', $user->id)
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'kiemDuyetVien:id,ho_ten,email'
            ])
            ->first();

        if (!$cd) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        return response()->json([
            'status'  => 1,
            'message' => 'Lấy chi tiết chiến dịch thành công.',
            'data'    => [
                'id'                  => $cd->id,
                'tieu_de'             => $cd->tieu_de,
                'mo_ta'               => $cd->mo_ta,
                'anh_bia'             => $cd->anh_bia,
                'dia_diem'            => $cd->dia_diem,
                'vi_do'               => $cd->vi_do,
                'kinh_do'             => $cd->kinh_do,
                'ngay_bat_dau'        => $cd->ngay_bat_dau?->format('Y-m-d'),
                'ngay_ket_thuc'       => $cd->ngay_ket_thuc?->format('Y-m-d'),
                'han_dang_ky'         => $cd->han_dang_ky?->format('Y-m-d'),
                'so_luong_toi_da'     => $cd->so_luong_toi_da,
                'so_luong_toi_thieu'  => $cd->so_luong_toi_thieu,
                'muc_do_uu_tien'      => $cd->muc_do_uu_tien,
                'trang_thai'          => $cd->trang_thai,
                'so_dang_ky'          => $cd->so_dang_ky,
                'so_xac_nhan'         => $cd->so_xac_nhan,
                'loai_chien_dich_id'  => $cd->loai_chien_dich_id,
                'loai_chien_dich'     => $cd->loaiChienDich,
                'kiem_duyet_vien'      => $cd->kiemDuyetVien,
                'ky_nang_ids'         => $cd->kyNangs->pluck('id')->toArray(),
                'tao_luc'             => $cd->tao_luc?->format('Y-m-d H:i:s'),
            ],
        ]);
    }

    // ======================== TẠO CHIẾN DỊCH ========================
    public function taoMoi(Request $request)
    {
        $request->validate([
            'tieu_de'            => 'required|string|max:300',
            'mo_ta'              => 'nullable|string',
            'loai_chien_dich_id' => 'nullable|integer|exists:loai_chien_dichs,id',
            'dia_diem'           => 'required|string|max:500',
            'vi_do'              => 'nullable|numeric',
            'kinh_do'            => 'nullable|numeric',
            'ngay_bat_dau'       => 'required|date',
            'ngay_ket_thuc'      => 'required|date|after_or_equal:ngay_bat_dau',
            'han_dang_ky'        => 'nullable|date',
            'so_luong_toi_da'    => 'required|integer|min:1',
            'so_luong_toi_thieu' => 'nullable|integer|min:1',
            'muc_do_uu_tien'     => 'required|in:thap,trung_binh,cao,khan_cap',
            'ky_nang_ids'        => 'nullable|array',
            'ky_nang_ids.*'      => 'integer|exists:ky_nangs,id',
        ]);

        $user = auth('api')->user();

        $cd = DB::transaction(function () use ($request, $user) {
            $cd = ChienDich::create([
                'kiem_duyet_vien_id'  => $user->id,
                'loai_chien_dich_id' => $request->loai_chien_dich_id,
                'tieu_de'            => $request->tieu_de,
                'mo_ta'              => $request->mo_ta,
                'dia_diem'           => $request->dia_diem,
                'vi_do'              => $request->vi_do,
                'kinh_do'            => $request->kinh_do,
                'ngay_bat_dau'       => $request->ngay_bat_dau,
                'ngay_ket_thuc'      => $request->ngay_ket_thuc,
                'han_dang_ky'        => $request->han_dang_ky,
                'so_luong_toi_da'    => $request->so_luong_toi_da,
                'so_luong_toi_thieu' => $request->so_luong_toi_thieu ?? 1,
                'muc_do_uu_tien'     => $request->muc_do_uu_tien,
                'trang_thai'         => 'cho_duyet',
            ]);

            // Sync kỹ năng yêu cầu
            if ($request->ky_nang_ids && count($request->ky_nang_ids) > 0) {
                $cd->kyNangs()->sync($request->ky_nang_ids);
            }

            return $cd;
        });

        return response()->json([
            'status'  => 1,
            'message' => 'Tạo chiến dịch thành công. Đang chờ Admin phê duyệt.',
            'data'    => ['id' => $cd->id],
        ], 201);
    }

    // ======================== CẬP NHẬT CHIẾN DỊCH ========================
    public function capNhat(Request $request, $id)
    {
        $request->validate([
            'tieu_de'            => 'required|string|max:300',
            'mo_ta'              => 'nullable|string',
            'loai_chien_dich_id' => 'nullable|integer|exists:loai_chien_dichs,id',
            'dia_diem'           => 'required|string|max:500',
            'vi_do'              => 'nullable|numeric',
            'kinh_do'            => 'nullable|numeric',
            'ngay_bat_dau'       => 'required|date',
            'ngay_ket_thuc'      => 'required|date|after_or_equal:ngay_bat_dau',
            'han_dang_ky'        => 'nullable|date',
            'so_luong_toi_da'    => 'required|integer|min:1',
            'so_luong_toi_thieu' => 'nullable|integer|min:1',
            'muc_do_uu_tien'     => 'required|in:thap,trung_binh,cao,khan_cap',
            'ky_nang_ids'        => 'nullable|array',
            'ky_nang_ids.*'      => 'integer|exists:ky_nangs,id',
        ]);

        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('kiem_duyet_vien_id', $user->id)
            ->whereNull('xoa_luc')
            ->first();

        if (!$cd) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        // Không cho sửa chiến dịch đã hủy hoặc đã hoàn thành
        if (in_array($cd->trang_thai, ['da_huy', 'hoan_thanh'])) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không thể chỉnh sửa chiến dịch đã hủy hoặc đã hoàn thành.',
            ], 422);
        }

        DB::transaction(function () use ($request, $cd) {
            $cd->update([
                'loai_chien_dich_id' => $request->loai_chien_dich_id,
                'tieu_de'            => $request->tieu_de,
                'mo_ta'              => $request->mo_ta,
                'dia_diem'           => $request->dia_diem,
                'vi_do'              => $request->vi_do,
                'kinh_do'            => $request->kinh_do,
                'ngay_bat_dau'       => $request->ngay_bat_dau,
                'ngay_ket_thuc'      => $request->ngay_ket_thuc,
                'han_dang_ky'        => $request->han_dang_ky,
                'so_luong_toi_da'    => $request->so_luong_toi_da,
                'so_luong_toi_thieu' => $request->so_luong_toi_thieu ?? 1,
                'muc_do_uu_tien'     => $request->muc_do_uu_tien,
            ]);

            // Sync kỹ năng yêu cầu
            $cd->kyNangs()->sync($request->ky_nang_ids ?? []);
        });

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật chiến dịch thành công.',
        ]);
    }

    // ======================== YÊU CẦU HỦY CHIẾN DỊCH (KDV gửi yêu cầu → Admin duyệt) ========================
    public function huyChienDich(Request $request, $id)
    {
        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('kiem_duyet_vien_id', $user->id)
            ->whereNull('xoa_luc')
            ->first();

        if (!$cd) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        if ($cd->trang_thai === 'da_huy') {
            return response()->json([
                'status'  => 0,
                'message' => 'Chiến dịch này đã bị hủy trước đó.',
            ], 422);
        }

        if ($cd->trang_thai === 'yeu_cau_huy') {
            return response()->json([
                'status'  => 0,
                'message' => 'Chiến dịch này đang chờ Admin duyệt hủy.',
            ], 422);
        }

        if ($cd->trang_thai === 'hoan_thanh') {
            return response()->json([
                'status'  => 0,
                'message' => 'Không thể hủy chiến dịch đã hoàn thành.',
            ], 422);
        }

        $lyDo = $request->ly_do ?? 'Kiểm duyệt viên yêu cầu hủy chiến dịch.';

        $cd->update([
            'trang_thai'    => 'yeu_cau_huy',
            'ly_do_tu_choi' => $lyDo,
        ]);

        // Gửi email thông báo cho tất cả TNV đã đăng ký (chưa hủy) rằng chiến dịch đang chờ hủy
        $danhSachDangKy = $cd->dangKyThamGias()
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->with('nguoiDung:id,ho_ten,email')
            ->get();

        foreach ($danhSachDangKy as $dangKy) {
            $tnv = $dangKy->nguoiDung;
            if ($tnv && $tnv->email) {
                \App\Jobs\SendMailJob::dispatch(
                    $tnv->email,
                    'Thông báo: Chiến dịch "' . $cd->tieu_de . '" đang chờ xét duyệt hủy',
                    'huy_chien_dich',
                    [
                        'ho_ten'          => $tnv->ho_ten,
                        'ten_chien_dich'  => $cd->tieu_de,
                        'dia_diem'        => $cd->dia_diem,
                        'ngay_bat_dau'    => $cd->ngay_bat_dau?->format('d/m/Y'),
                        'ngay_ket_thuc'   => $cd->ngay_ket_thuc?->format('d/m/Y'),
                        'ly_do'           => $lyDo,
                        'trang_thai_huy'  => 'yeu_cau_huy',
                        'link_chien_dich' => config('app.frontend_url', 'http://localhost:5180') . '/danh-sach-chien-dich',
                    ]
                );
            }
        }

        return response()->json([
            'status'  => 1,
            'message' => 'Đã gửi yêu cầu hủy chiến dịch. Vui lòng chờ Admin phê duyệt.'
                . ($danhSachDangKy->count() > 0 ? ' Đã thông báo đến ' . $danhSachDangKy->count() . ' tình nguyện viên.' : ''),
        ]);
    }

    // ======================== DANH SÁCH LOẠI CHIẾN DỊCH ========================
    public function danhSachLoai()
    {
        $loais = LoaiChienDich::where('hoat_dong', true)
            ->whereNull('xoa_luc')
            ->select('id', 'ten', 'bieu_tuong', 'mau_sac')
            ->orderBy('ten')
            ->get();

        return response()->json([
            'status'  => 1,
            'data'    => $loais,
        ]);
    }
}

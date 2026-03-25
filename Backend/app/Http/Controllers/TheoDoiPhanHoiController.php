<?php

namespace App\Http\Controllers;

use App\Models\BaoCaoChienDich;
use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\DanhGiaTnv;
use App\Models\PhanHoiTnv;
use App\Models\ThePhanHoi;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TheoDoiPhanHoiController extends Controller
{
    public function tongQuan(Request $request)
    {
        $user = auth('api')->user();

        $dangKys = DangKyThamGia::query()
            ->where('nguoi_dung_id', $user->id)
            ->with([
                'chienDich:id,tieu_de,dia_diem,ngay_bat_dau,ngay_ket_thuc,thoi_gian_bat_dau_thuc_te,thoi_gian_ket_thuc_thuc_te,trang_thai,nguoi_tao_id,tao_luc',
                'chienDich.nguoiTao:id,ho_ten,email',
            ])
            ->orderByDesc('dang_ky_luc')
            ->get()
            ->filter(fn ($dangKy) => $dangKy->chienDich && !$dangKy->chienDich->xoa_luc)
            ->values();

        $campaignIds = $dangKys->pluck('chien_dich_id')->unique()->values();

        $danhGias = DanhGiaTnv::query()
            ->where('tinh_nguyen_vien_id', $user->id)
            ->whereIn('chien_dich_id', $campaignIds)
            ->with([
                'chienDich:id,tieu_de,ngay_bat_dau,ngay_ket_thuc',
                'nguoiDanhGia:id,ho_ten,email',
            ])
            ->orderByDesc('tao_luc')
            ->get();

        $phanHois = PhanHoiTnv::query()
            ->where('nguoi_dung_id', $user->id)
            ->whereIn('chien_dich_id', $campaignIds)
            ->with(['thePhanHois:id,ten'])
            ->get()
            ->keyBy('chien_dich_id');

        $baoCaos = BaoCaoChienDich::query()
            ->where('nguoi_gui_id', $user->id)
            ->whereIn('chien_dich_id', $campaignIds)
            ->with([
                'chienDich:id,tieu_de,trang_thai',
                'nguoiXuLy:id,ho_ten,email',
            ])
            ->orderByDesc('tao_luc')
            ->get();

        $tags = ThePhanHoi::query()->orderBy('ten')->get(['id', 'ten']);

        $danhGiaByCampaign = $danhGias->keyBy('chien_dich_id');

        $lichSu = $dangKys->map(function ($dangKy) use ($danhGiaByCampaign, $phanHois) {
            $chienDich = $dangKy->chienDich;
            $danhGia = $danhGiaByCampaign->get($dangKy->chien_dich_id);
            $phanHoi = $phanHois->get($dangKy->chien_dich_id);

            return [
                'id' => $dangKy->id,
                'chien_dich_id' => $chienDich->id,
                'trang_thai_dang_ky' => $dangKy->trang_thai,
                'trang_thai_chien_dich' => $chienDich->trang_thai,
                'dang_ky_luc' => optional($dangKy->dang_ky_luc)->format('Y-m-d H:i:s'),
                'xac_nhan_luc' => optional($dangKy->xac_nhan_luc)->format('Y-m-d H:i:s'),
                'huy_luc' => optional($dangKy->huy_luc)->format('Y-m-d H:i:s'),
                'ly_do_huy' => $dangKy->ly_do_huy,
                'chien_dich' => [
                    'id' => $chienDich->id,
                    'tieu_de' => $chienDich->tieu_de,
                    'dia_diem' => $chienDich->dia_diem,
                    'tao_luc' => optional($chienDich->tao_luc)->format('Y-m-d H:i:s'),
                    'ngay_bat_dau' => optional($chienDich->ngay_bat_dau)->format('Y-m-d'),
                    'ngay_ket_thuc' => optional($chienDich->ngay_ket_thuc)->format('Y-m-d'),
                    'thoi_gian_bat_dau_thuc_te' => optional($chienDich->thoi_gian_bat_dau_thuc_te)->format('Y-m-d H:i:s'),
                    'thoi_gian_ket_thuc_thuc_te' => optional($chienDich->thoi_gian_ket_thuc_thuc_te)->format('Y-m-d H:i:s'),
                    'nguoi_tao' => $chienDich->nguoiTao ? [
                        'id' => $chienDich->nguoiTao->id,
                        'ho_ten' => $chienDich->nguoiTao->ho_ten,
                        'email' => $chienDich->nguoiTao->email,
                    ] : null,
                ],
                'danh_gia_tnv' => $danhGia ? [
                    'id' => $danhGia->id,
                    'so_sao' => $danhGia->so_sao,
                    'nhan_xet' => $danhGia->nhan_xet,
                    'tao_luc' => optional($danhGia->tao_luc)->format('Y-m-d H:i:s'),
                    'nguoi_danh_gia' => $danhGia->nguoiDanhGia ? [
                        'id' => $danhGia->nguoiDanhGia->id,
                        'ho_ten' => $danhGia->nguoiDanhGia->ho_ten,
                        'email' => $danhGia->nguoiDanhGia->email,
                    ] : null,
                ] : null,
                'phan_hoi_chien_dich' => $phanHoi ? [
                    'id' => $phanHoi->id,
                    'so_sao' => $phanHoi->so_sao,
                    'nhan_xet' => $phanHoi->nhan_xet,
                    'tao_luc' => optional($phanHoi->tao_luc)->format('Y-m-d H:i:s'),
                    'the_ids' => $phanHoi->thePhanHois->pluck('id')->values(),
                    'the_phan_hoi' => $phanHoi->thePhanHois->map(fn ($the) => [
                        'id' => $the->id,
                        'ten' => $the->ten,
                    ])->values(),
                ] : null,
                'co_the_report' => $this->coTheBaoCao($dangKy),
                'co_the_danh_gia_chien_dich' => $this->coTheDanhGiaChienDich($dangKy, $phanHoi),
            ];
        })->values();

        $avgRating = $danhGias->count() > 0
            ? round($danhGias->avg('so_sao'), 1)
            : 0;

        return response()->json([
            'status' => 1,
            'message' => 'Lấy dữ liệu theo dõi & phản hồi thành công.',
            'data' => [
                'thong_ke' => [
                    'so_chien_dich_hoan_thanh' => $dangKys->where('trang_thai', 'hoan_thanh')->count(),
                    'so_chien_dich_dang_tham_gia' => $dangKys->filter(fn ($dangKy) => in_array($dangKy->trang_thai, ['da_duyet', 'dang_tham_gia'], true))->count(),
                    'diem_danh_gia_trung_binh' => $avgRating,
                    'tong_luot_danh_gia' => $danhGias->count(),
                    'tong_bao_cao' => $baoCaos->count(),
                    'bao_cao_dang_xu_ly' => $baoCaos->whereIn('trang_thai', ['moi', 'dang_xu_ly'])->count(),
                ],
                'lich_su_hoat_dong' => $lichSu,
                'diem_danh_gia' => $danhGias->map(fn ($danhGia) => [
                    'id' => $danhGia->id,
                    'chien_dich_id' => $danhGia->chien_dich_id,
                    'ten_chien_dich' => optional($danhGia->chienDich)->tieu_de,
                    'so_sao' => $danhGia->so_sao,
                    'nhan_xet' => $danhGia->nhan_xet,
                    'tao_luc' => optional($danhGia->tao_luc)->format('Y-m-d H:i:s'),
                    'nguoi_danh_gia' => $danhGia->nguoiDanhGia ? [
                        'id' => $danhGia->nguoiDanhGia->id,
                        'ho_ten' => $danhGia->nguoiDanhGia->ho_ten,
                    ] : null,
                ])->values(),
                'bao_cao_chien_dich' => $baoCaos->map(fn ($baoCao) => [
                    'id' => $baoCao->id,
                    'chien_dich_id' => $baoCao->chien_dich_id,
                    'ten_chien_dich' => optional($baoCao->chienDich)->tieu_de,
                    'phan_loai' => $baoCao->phan_loai,
                    'tieu_de' => $baoCao->tieu_de,
                    'noi_dung' => $baoCao->noi_dung,
                    'trang_thai' => $baoCao->trang_thai,
                    'phan_hoi_xu_ly' => $baoCao->phan_hoi_xu_ly,
                    'xu_ly_luc' => optional($baoCao->xu_ly_luc)->format('Y-m-d H:i:s'),
                    'tao_luc' => optional($baoCao->tao_luc)->format('Y-m-d H:i:s'),
                    'nguoi_xu_ly' => $baoCao->nguoiXuLy ? [
                        'id' => $baoCao->nguoiXuLy->id,
                        'ho_ten' => $baoCao->nguoiXuLy->ho_ten,
                    ] : null,
                ])->values(),
                'the_phan_hoi' => $tags,
            ],
        ]);
    }

    public function taoBaoCao(Request $request)
    {
        $request->validate([
            'chien_dich_id' => 'required|integer|exists:chien_dichs,id',
            'phan_loai' => 'required|string|max:100',
            'tieu_de' => 'required|string|max:300',
            'noi_dung' => 'required|string|max:5000',
        ]);

        $user = auth('api')->user();

        $dangKy = $this->findDangKyThamGia($request->integer('chien_dich_id'), $user->id);

        if (!$dangKy || !$this->coTheBaoCao($dangKy)) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn chỉ có thể báo cáo khi đã được duyệt tham gia hoặc đang tham gia chiến dịch.',
            ], 422);
        }

        $baoCao = BaoCaoChienDich::create([
            'chien_dich_id' => $request->integer('chien_dich_id'),
            'nguoi_gui_id' => $user->id,
            'phan_loai' => trim($request->phan_loai),
            'tieu_de' => trim($request->tieu_de),
            'noi_dung' => trim($request->noi_dung),
            'trang_thai' => 'moi',
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Gửi báo cáo chiến dịch thành công.',
            'data' => [
                'id' => $baoCao->id,
                'chien_dich_id' => $baoCao->chien_dich_id,
                'phan_loai' => $baoCao->phan_loai,
                'tieu_de' => $baoCao->tieu_de,
                'noi_dung' => $baoCao->noi_dung,
                'trang_thai' => $baoCao->trang_thai,
                'tao_luc' => optional($baoCao->tao_luc)->format('Y-m-d H:i:s'),
            ],
        ]);
    }

    public function danhGiaChienDich(Request $request)
    {
        $request->validate([
            'chien_dich_id' => 'required|integer|exists:chien_dichs,id',
            'so_sao' => 'required|integer|min:1|max:5',
            'nhan_xet' => 'nullable|string|max:2000',
            'the_ids' => 'nullable|array',
            'the_ids.*' => 'integer|exists:the_phan_hoi,id',
        ]);

        $user = auth('api')->user();

        $chienDich = ChienDich::query()
            ->where('id', $request->integer('chien_dich_id'))
            ->whereNull('xoa_luc')
            ->first();

        if (!$chienDich) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        if ($chienDich->trang_thai !== 'hoan_thanh') {
            return response()->json([
                'status' => 0,
                'message' => 'Chỉ có thể đánh giá chiến dịch khi chiến dịch đã hoàn thành.',
            ], 422);
        }

        $dangKy = DangKyThamGia::query()
            ->where('chien_dich_id', $chienDich->id)
            ->where('nguoi_dung_id', $user->id)
            ->first();

        if (!$dangKy || !$this->coTheDanhGiaChienDich($dangKy)) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn không thể đánh giá chiến dịch này vì chưa tham gia hợp lệ.',
            ], 422);
        }

        $phanHoiDaTonTai = PhanHoiTnv::query()
            ->where('chien_dich_id', $chienDich->id)
            ->where('nguoi_dung_id', $user->id)
            ->first();

        if ($phanHoiDaTonTai) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn chỉ được đánh giá chiến dịch một lần.',
            ], 422);
        }

        $payload = [
            'so_sao' => $request->integer('so_sao'),
            'nhan_xet' => $request->nhan_xet,
        ];

        $phanHoi = DB::transaction(function () use ($request, $user, $chienDich, $payload) {
            $phanHoi = PhanHoiTnv::create([
                'chien_dich_id' => $chienDich->id,
                'nguoi_dung_id' => $user->id,
                'so_sao' => $payload['so_sao'],
                'nhan_xet' => $payload['nhan_xet'],
            ]);

            $theIds = collect($request->input('the_ids', []))
                ->filter()
                ->unique()
                ->values()
                ->all();

            $phanHoi->thePhanHois()->sync($theIds);

            return $phanHoi->fresh(['thePhanHois:id,ten']);
        });

        return response()->json([
            'status' => 1,
            'message' => 'Đánh giá chiến dịch thành công.',
            'data' => [
                'id' => $phanHoi->id,
                'chien_dich_id' => $phanHoi->chien_dich_id,
                'so_sao' => $phanHoi->so_sao,
                'nhan_xet' => $phanHoi->nhan_xet,
                'tao_luc' => optional($phanHoi->tao_luc)->format('Y-m-d H:i:s'),
                'the_ids' => $phanHoi->thePhanHois->pluck('id')->values(),
                'the_phan_hoi' => $phanHoi->thePhanHois->map(fn ($the) => [
                    'id' => $the->id,
                    'ten' => $the->ten,
                ])->values(),
            ],
        ]);
    }

    private function findDangKyThamGia(int $chienDichId, int $nguoiDungId): ?DangKyThamGia
    {
        return DangKyThamGia::query()
            ->where('chien_dich_id', $chienDichId)
            ->where('nguoi_dung_id', $nguoiDungId)
            ->first();
    }

    private function coTheBaoCao(DangKyThamGia $dangKy): bool
    {
        return in_array($dangKy->trang_thai, ['da_duyet', 'dang_tham_gia', 'hoan_thanh'], true);
    }

    private function coTheDanhGiaChienDich(DangKyThamGia $dangKy, ?PhanHoiTnv $phanHoi = null): bool
    {
        if (!$dangKy->chienDich) {
            return false;
        }

        return $dangKy->chienDich->trang_thai === 'hoan_thanh'
            && in_array($dangKy->trang_thai, ['dang_tham_gia', 'hoan_thanh'], true)
            && !$phanHoi;
    }
}

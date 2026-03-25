<?php

namespace App\Http\Controllers;

use App\Jobs\SendMailJob;
use App\Models\ChienDich;
use App\Models\LichSuKiemDuyetChienDich;
use App\Models\LoaiChienDich;
use App\Models\ThongBao;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ChienDichController extends Controller
{
    // ======================== DANH SÁCH CHIẾN DỊCH CỦA NGƯỜI TẠO ========================
    public function danhSach(Request $request)
    {
        $user = auth('api')->user();
        $perPage = (int) $request->input('per_page', 10);

        $query = ChienDich::where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email,vai_tro',
            ]);

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
                'thoi_gian_bat_dau_thuc_te' => $cd->thoi_gian_bat_dau_thuc_te?->format('Y-m-d H:i:s'),
                'thoi_gian_ket_thuc_thuc_te' => $cd->thoi_gian_ket_thuc_thuc_te?->format('Y-m-d H:i:s'),
                'han_dang_ky'         => $cd->han_dang_ky?->format('Y-m-d'),
                'so_luong_toi_da'     => $cd->so_luong_toi_da,
                'so_luong_toi_thieu'  => $cd->so_luong_toi_thieu,
                'muc_do_uu_tien'      => $cd->muc_do_uu_tien,
                'trang_thai'          => $cd->trang_thai,
                'so_dang_ky'          => $cd->so_dang_ky,
                'so_xac_nhan'         => $cd->so_xac_nhan,
                'loai_chien_dich_id'  => $cd->loai_chien_dich_id,
                'loai_chien_dich'     => $cd->loaiChienDich,
                'nguoi_tao_id'        => $cd->nguoi_tao_id,
                'nguoi_tao'           => $cd->nguoiTao,
                'duyet_boi'           => $cd->duyetBoi,
                // Alias tạm để FE cũ chưa cần sửa ngay.
                'kiem_duyet_vien'     => $cd->duyetBoi,
                'duyet_luc'           => $cd->duyet_luc?->format('Y-m-d H:i:s'),
                'ly_do_tu_choi'       => $cd->ly_do_tu_choi,
                'ky_nangs'            => $cd->kyNangs->map(fn($kyNang) => [
                    'id'  => $kyNang->id,
                    'ten' => $kyNang->ten,
                ])->values(),
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

    // ======================== CHI TIẾT CHIẾN DỊCH CỦA NGƯỜI TẠO ========================
    public function chiTiet(Request $request, $id)
    {
        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email,vai_tro',
                'dangKyThamGias.nguoiDung:id,ho_ten,email',
                'dangKyThamGias.nguoiDung.kyNangs:ky_nangs.id,ten',
                'dangKyThamGias.nguoiDung.khuVucs:khu_vucs.id,ten',
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
                'thoi_gian_bat_dau_thuc_te' => $cd->thoi_gian_bat_dau_thuc_te?->format('Y-m-d H:i:s'),
                'thoi_gian_ket_thuc_thuc_te' => $cd->thoi_gian_ket_thuc_thuc_te?->format('Y-m-d H:i:s'),
                'han_dang_ky'         => $cd->han_dang_ky?->format('Y-m-d'),
                'so_luong_toi_da'     => $cd->so_luong_toi_da,
                'so_luong_toi_thieu'  => $cd->so_luong_toi_thieu,
                'muc_do_uu_tien'      => $cd->muc_do_uu_tien,
                'trang_thai'          => $cd->trang_thai,
                'so_dang_ky'          => $cd->so_dang_ky,
                'so_xac_nhan'         => $cd->so_xac_nhan,
                'loai_chien_dich_id'  => $cd->loai_chien_dich_id,
                'loai_chien_dich'     => $cd->loaiChienDich,
                'nguoi_tao_id'        => $cd->nguoi_tao_id,
                'nguoi_tao'           => $cd->nguoiTao,
                'duyet_boi'           => $cd->duyetBoi,
                // Alias tạm để FE cũ chưa cần sửa ngay.
                'kiem_duyet_vien'     => $cd->duyetBoi,
                'duyet_luc'           => $cd->duyet_luc?->format('Y-m-d H:i:s'),
                'ly_do_tu_choi'       => $cd->ly_do_tu_choi,
                'ky_nangs'            => $cd->kyNangs->map(fn($kyNang) => [
                    'id'  => $kyNang->id,
                    'ten' => $kyNang->ten,
                ])->values(),
                'ky_nang_ids'         => $cd->kyNangs->pluck('id')->toArray(),
                'danh_sach_dang_ky'   => $cd->dangKyThamGias->map(function ($dangKy) {
                    $nguoiDung = $dangKy->nguoiDung;

                    return [
                        'id'            => $dangKy->id,
                        'nguoi_dung_id' => $dangKy->nguoi_dung_id,
                        'trang_thai'    => $dangKy->trang_thai,
                        'dang_ky_luc'   => $dangKy->dang_ky_luc?->format('Y-m-d H:i:s'),
                        'duyet_luc'     => $dangKy->duyet_luc?->format('Y-m-d H:i:s'),
                        'xac_nhan_luc'  => $dangKy->xac_nhan_luc?->format('Y-m-d H:i:s'),
                        'huy_luc'       => $dangKy->huy_luc?->format('Y-m-d H:i:s'),
                        'ly_do_huy'     => $dangKy->ly_do_huy,
                        'ghi_chu'       => $dangKy->ghi_chu,
                        'nguoi_dung'    => $nguoiDung ? [
                            'id'        => $nguoiDung->id,
                            'ho_ten'    => $nguoiDung->ho_ten,
                            'email'     => $nguoiDung->email,
                            'ky_nangs'  => $nguoiDung->kyNangs->map(fn($kyNang) => [
                                'id'  => $kyNang->id,
                                'ten' => $kyNang->ten,
                            ])->values(),
                            'khu_vucs'  => $nguoiDung->khuVucs->map(fn($khuVuc) => [
                                'id'  => $khuVuc->id,
                                'ten' => $khuVuc->ten,
                            ])->values(),
                        ] : null,
                    ];
                })->values(),
                'tao_luc'             => $cd->tao_luc?->format('Y-m-d H:i:s'),
            ],
        ]);
    }

    public function giamSatBaoCao(Request $request, $id)
    {
        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'nguoiTao:id,ho_ten,email',
                'dangKyThamGias.nguoiDung:id,ho_ten,email,anh_dai_dien',
                'feedbacks.nguoiDung:id,ho_ten,email',
                'feedbacks.thePhanHois:id,ten',
                'baoCaos.nguoiGui:id,ho_ten,email',
                'baoCaos.nguoiXuLy:id,ho_ten,email',
            ])
            ->first();

        if (!$cd) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $dangKyThamGia = $cd->dangKyThamGias
            ->sortByDesc(fn ($dangKy) => $dangKy->xac_nhan_luc ?? $dangKy->dang_ky_luc)
            ->values();

        $tongDangKyHopLe = $dangKyThamGia
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->count();

        $tongDaDuyet = $dangKyThamGia
            ->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])
            ->count();

        $tongDangThamGia = $dangKyThamGia->where('trang_thai', 'dang_tham_gia')->count();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy dữ liệu giám sát báo cáo thành công.',
            'data' => [
                'chien_dich' => [
                    'id' => $cd->id,
                    'tieu_de' => $cd->tieu_de,
                    'dia_diem' => $cd->dia_diem,
                    'ngay_bat_dau' => $cd->ngay_bat_dau?->format('Y-m-d'),
                    'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('Y-m-d'),
                    'thoi_gian_bat_dau_thuc_te' => $cd->thoi_gian_bat_dau_thuc_te?->format('Y-m-d H:i:s'),
                    'thoi_gian_ket_thuc_thuc_te' => $cd->thoi_gian_ket_thuc_thuc_te?->format('Y-m-d H:i:s'),
                    'trang_thai' => $cd->trang_thai,
                    'so_luong_toi_da' => $cd->so_luong_toi_da,
                    'so_luong_toi_thieu' => $cd->so_luong_toi_thieu,
                    'so_dang_ky' => $cd->so_dang_ky,
                    'so_xac_nhan' => $cd->so_xac_nhan,
                    'nguoi_tao' => $cd->nguoiTao ? [
                        'id' => $cd->nguoiTao->id,
                        'ho_ten' => $cd->nguoiTao->ho_ten,
                        'email' => $cd->nguoiTao->email,
                    ] : null,
                    'loai_chien_dich' => $cd->loaiChienDich ? [
                        'id' => $cd->loaiChienDich->id,
                        'ten' => $cd->loaiChienDich->ten,
                    ] : null,
                ],
                'thong_ke' => [
                    'tong_dang_ky_hop_le' => $tongDangKyHopLe,
                    'tong_da_duyet' => $tongDaDuyet,
                    'tong_dang_tham_gia' => $tongDangThamGia,
                    'tong_phan_hoi' => $cd->feedbacks->count(),
                    'tong_bao_cao' => $cd->baoCaos->count(),
                    'bao_cao_chua_xu_ly' => $cd->baoCaos->whereIn('trang_thai', ['moi', 'dang_xu_ly'])->count(),
                ],
                'danh_sach_tham_gia' => $dangKyThamGia->map(function ($dangKy) {
                    $nguoiDung = $dangKy->nguoiDung;

                    return [
                        'id' => $dangKy->id,
                        'trang_thai' => $dangKy->trang_thai,
                        'dang_ky_luc' => $dangKy->dang_ky_luc?->format('Y-m-d H:i:s'),
                        'xac_nhan_luc' => $dangKy->xac_nhan_luc?->format('Y-m-d H:i:s'),
                        'huy_luc' => $dangKy->huy_luc?->format('Y-m-d H:i:s'),
                        'ly_do_huy' => $dangKy->ly_do_huy,
                        'ghi_chu' => $dangKy->ghi_chu,
                        'nguoi_dung' => $nguoiDung ? [
                            'id' => $nguoiDung->id,
                            'ho_ten' => $nguoiDung->ho_ten,
                            'email' => $nguoiDung->email,
                            'anh_dai_dien' => $nguoiDung->anh_dai_dien,
                        ] : null,
                    ];
                })->values(),
                'phan_hoi' => $cd->feedbacks
                    ->sortByDesc('tao_luc')
                    ->values()
                    ->map(function ($feedback) {
                        return [
                            'id' => $feedback->id,
                            'so_sao' => $feedback->so_sao,
                            'nhan_xet' => $feedback->nhan_xet,
                            'tao_luc' => $feedback->tao_luc?->format('Y-m-d H:i:s'),
                            'nguoi_dung' => $feedback->nguoiDung ? [
                                'id' => $feedback->nguoiDung->id,
                                'ho_ten' => $feedback->nguoiDung->ho_ten,
                                'email' => $feedback->nguoiDung->email,
                            ] : null,
                            'the_phan_hoi' => $feedback->thePhanHois->map(fn ($the) => [
                                'id' => $the->id,
                                'ten' => $the->ten,
                            ])->values(),
                        ];
                    }),
                'bao_cao' => $cd->baoCaos
                    ->sortByDesc('tao_luc')
                    ->values()
                    ->map(function ($baoCao) {
                        return [
                            'id' => $baoCao->id,
                            'phan_loai' => $baoCao->phan_loai,
                            'tieu_de' => $baoCao->tieu_de,
                            'noi_dung' => $baoCao->noi_dung,
                            'trang_thai' => $baoCao->trang_thai,
                            'phan_hoi_xu_ly' => $baoCao->phan_hoi_xu_ly,
                            'tao_luc' => $baoCao->tao_luc?->format('Y-m-d H:i:s'),
                            'xu_ly_luc' => $baoCao->xu_ly_luc?->format('Y-m-d H:i:s'),
                            'nguoi_gui' => $baoCao->nguoiGui ? [
                                'id' => $baoCao->nguoiGui->id,
                                'ho_ten' => $baoCao->nguoiGui->ho_ten,
                                'email' => $baoCao->nguoiGui->email,
                            ] : null,
                            'nguoi_xu_ly' => $baoCao->nguoiXuLy ? [
                                'id' => $baoCao->nguoiXuLy->id,
                                'ho_ten' => $baoCao->nguoiXuLy->ho_ten,
                                'email' => $baoCao->nguoiXuLy->email,
                            ] : null,
                        ];
                    }),
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
            'anh_bia'            => 'nullable|image|max:5120',
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
        $hanDangKy = $request->han_dang_ky
            ? Carbon::parse($request->han_dang_ky)->toDateString()
            : Carbon::parse($request->ngay_bat_dau)->subDays(3)->toDateString();
        $anhBiaUrl = $request->hasFile('anh_bia')
            ? $this->luuAnhBia($request->file('anh_bia'))
            : null;

        $cd = DB::transaction(function () use ($request, $user, $hanDangKy, $anhBiaUrl) {
            $cd = ChienDich::create([
                'nguoi_tao_id'        => $user->id,
                'loai_chien_dich_id' => $request->loai_chien_dich_id,
                'tieu_de'            => $request->tieu_de,
                'mo_ta'              => $request->mo_ta,
                'anh_bia'            => $anhBiaUrl,
                'dia_diem'           => $request->dia_diem,
                'vi_do'              => $request->vi_do,
                'kinh_do'            => $request->kinh_do,
                'ngay_bat_dau'       => $request->ngay_bat_dau,
                'ngay_ket_thuc'      => $request->ngay_ket_thuc,
                'han_dang_ky'        => $hanDangKy,
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
            'message' => 'Tạo chiến dịch thành công. Đang chờ Kiểm duyệt viên phê duyệt.',
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
            'anh_bia'            => 'nullable|image|max:5120',
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
            ->where('nguoi_tao_id', $user->id)
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

        $hanDangKy = $request->han_dang_ky
            ? Carbon::parse($request->han_dang_ky)->toDateString()
            : Carbon::parse($request->ngay_bat_dau)->subDays(3)->toDateString();
        $anhBiaUrl = $request->hasFile('anh_bia')
            ? $this->luuAnhBia($request->file('anh_bia'))
            : $cd->getRawOriginal('anh_bia');

        DB::transaction(function () use ($request, $cd, $hanDangKy, $anhBiaUrl) {
            $cd->update([
                'loai_chien_dich_id' => $request->loai_chien_dich_id,
                'tieu_de'            => $request->tieu_de,
                'mo_ta'              => $request->mo_ta,
                'anh_bia'            => $anhBiaUrl,
                'dia_diem'           => $request->dia_diem,
                'vi_do'              => $request->vi_do,
                'kinh_do'            => $request->kinh_do,
                'ngay_bat_dau'       => $request->ngay_bat_dau,
                'ngay_ket_thuc'      => $request->ngay_ket_thuc,
                'han_dang_ky'        => $hanDangKy,
                'so_luong_toi_da'    => $request->so_luong_toi_da,
                'so_luong_toi_thieu' => $request->so_luong_toi_thieu ?? 1,
                'muc_do_uu_tien'     => $request->muc_do_uu_tien,
            ]);

            // Sync kỹ năng yêu cầu
            $cd->kyNangs()->sync($request->ky_nang_ids ?? []);
        });

        $this->forgetOwnerStartReminderCache($cd->id);

        return response()->json([
            'status'  => 1,
            'message' => 'Cập nhật chiến dịch thành công.',
        ]);
    }

    // ======================== CẬP NHẬT TRẠNG THÁI CHIẾN DỊCH (NGƯỜI TẠO) ========================
    public function capNhatTrangThai(Request $request, $id)
    {
        $request->validate([
            'trang_thai' => 'required|in:dang_dien_ra,hoan_thanh',
            'ghi_chu' => 'nullable|string|max:1000',
            'bo_qua_canh_bao' => 'nullable|boolean',
        ]);

        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->with([
                'nguoiTao:id,ho_ten,email',
                'dangKyThamGias.nguoiDung:id,ho_ten,email',
            ])
            ->first();

        if (!$cd) {
            return response()->json([
                'status'  => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $allowedTransitions = [
            'da_duyet' => ['dang_dien_ra'],
            'dang_dien_ra' => ['hoan_thanh'],
        ];

        $nextStatus = $request->trang_thai;
        if (!in_array($nextStatus, $allowedTransitions[$cd->trang_thai] ?? [], true)) {
            return response()->json([
                'status'  => 0,
                'message' => 'Chuyển trạng thái không hợp lệ.',
            ], 422);
        }

        $ghiChu = $request->ghi_chu;
        $boQuaCanhBao = (bool) $request->boolean('bo_qua_canh_bao');

        if ($nextStatus === 'dang_dien_ra') {
            $thongTinCanhBao = $this->buildStartCampaignWarning($cd);

            if ($thongTinCanhBao && !$boQuaCanhBao) {
                return response()->json([
                    'status' => 0,
                    'message' => $thongTinCanhBao['message'],
                    'warning' => $thongTinCanhBao,
                ], 422);
            }
        }

        $warningInfo = $nextStatus === 'dang_dien_ra'
            ? $this->buildStartCampaignWarning($cd)
            : null;
        $thoiDiemThucTe = now();

        DB::transaction(function () use ($cd, $user, $nextStatus, $ghiChu, $warningInfo, $thoiDiemThucTe) {
            $oldStatus = $cd->trang_thai;

            $capNhatChienDich = [
                'trang_thai' => $nextStatus,
            ];

            if ($nextStatus === 'dang_dien_ra' && !$cd->thoi_gian_bat_dau_thuc_te) {
                $capNhatChienDich['thoi_gian_bat_dau_thuc_te'] = $thoiDiemThucTe;
            }

            if ($nextStatus === 'hoan_thanh' && !$cd->thoi_gian_ket_thuc_thuc_te) {
                $capNhatChienDich['thoi_gian_ket_thuc_thuc_te'] = $thoiDiemThucTe;
            }

            $cd->update($capNhatChienDich);

            $thongTinDongBo = $this->dongBoTrangThaiDangKyTheoTrangThaiChienDich($cd, $nextStatus);
            $cd->refresh();

            $duLieuBoSung = [
                'nguoi_tao_id' => $user->id,
                'canh_bao' => $warningInfo,
                'thoi_gian_bat_dau_thuc_te' => $cd->thoi_gian_bat_dau_thuc_te?->format('Y-m-d H:i:s'),
                'thoi_gian_ket_thuc_thuc_te' => $cd->thoi_gian_ket_thuc_thuc_te?->format('Y-m-d H:i:s'),
            ];

            LichSuKiemDuyetChienDich::create([
                'chien_dich_id' => $cd->id,
                'nguoi_thuc_hien_id' => $user->id,
                'hanh_dong' => $nextStatus === 'dang_dien_ra' ? 'bat_dau_chien_dich' : 'hoan_thanh_chien_dich',
                'tu_trang_thai' => $oldStatus,
                'den_trang_thai' => $nextStatus,
                'ghi_chu' => $ghiChu,
                'du_lieu_bo_sung' => $duLieuBoSung,
            ]);

            $this->guiThongBaoCapNhatTrangThai($cd, $user->id, $nextStatus, $ghiChu, $thongTinDongBo);
            $this->ghiLogTrangThaiChienDich($cd, $user->id, $nextStatus, $warningInfo);
        });

        $this->forgetOwnerStartReminderCache($cd->id);

        return response()->json([
            'status'  => 1,
            'message' => $nextStatus === 'dang_dien_ra'
                ? 'Bắt đầu chiến dịch thành công.'
                : 'Hoàn thành chiến dịch thành công.',
        ]);
    }

    public function capNhatTrangThaiDangKy(Request $request, int $id, int $registrationId)
    {
        $request->validate([
            'trang_thai' => 'required|in:da_duyet,tu_choi',
            'ghi_chu' => 'nullable|string|max:1000',
        ]);

        $user = auth('api')->user();

        $cd = ChienDich::query()
            ->where('id', $id)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->with('dangKyThamGias.nguoiDung:id,ho_ten,email')
            ->first();

        if (!$cd) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        if (!in_array($cd->trang_thai, ['da_duyet', 'cho_duyet', 'nhap'], true)) {
            return response()->json([
                'status' => 0,
                'message' => 'Chỉ có thể cập nhật trạng thái tham gia khi chiến dịch chưa bắt đầu.',
            ], 422);
        }

        $dangKy = $cd->dangKyThamGias->firstWhere('id', $registrationId);

        if (!$dangKy) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy đăng ký tham gia.',
            ], 404);
        }

        if (in_array($dangKy->trang_thai, ['dang_tham_gia', 'hoan_thanh', 'da_huy'], true)) {
            return response()->json([
                'status' => 0,
                'message' => 'Không thể đổi trạng thái của đăng ký này ở thời điểm hiện tại.',
            ], 422);
        }

        if ($dangKy->trang_thai !== 'da_xac_nhan') {
            return response()->json([
                'status' => 0,
                'message' => 'Chỉ có thể duyệt hoặc từ chối khi tình nguyện viên đã xác nhận tham gia.',
            ], 422);
        }

        $trangThaiCu = $dangKy->trang_thai;
        $trangThaiMoi = $request->string('trang_thai')->value();
        $ghiChu = trim((string) $request->input('ghi_chu', ''));

        if ($trangThaiCu === $trangThaiMoi && $ghiChu === trim((string) ($dangKy->ghi_chu ?? ''))) {
            return response()->json([
                'status' => 1,
                'message' => 'Trạng thái tham gia không thay đổi.',
                'data' => [
                    'dang_ky_id' => $dangKy->id,
                    'trang_thai' => $dangKy->trang_thai,
                ],
            ]);
        }

        DB::transaction(function () use ($cd, $dangKy, $trangThaiCu, $trangThaiMoi, $ghiChu, $user) {
            $payload = [
                'trang_thai' => $trangThaiMoi,
                'ghi_chu' => $ghiChu !== '' ? $ghiChu : null,
                'duyet_luc' => now(),
            ];

            if ($trangThaiMoi === 'da_duyet') {
                $payload['huy_luc'] = null;
                $payload['ly_do_huy'] = null;
            }

            if ($trangThaiMoi === 'tu_choi') {
                $payload['huy_luc'] = now();
                $payload['ly_do_huy'] = $ghiChu !== '' ? $ghiChu : 'Chủ chiến dịch từ chối xác nhận tham gia.';
            }

            $dangKy->update($payload);
            $cd->refresh();
            $this->dongBoSoLuongDangKy($cd);

            $this->taoThongBaoCapNhatTrangThaiChienDich(
                $dangKy->nguoi_dung_id,
                $user->id,
                $this->layTieuDeThongBaoTrangThaiDangKy($trangThaiMoi),
                $this->layNoiDungThongBaoTrangThaiDangKy($cd, $trangThaiMoi, $ghiChu),
                $cd->id
            );

            Log::info('Chu chien dich cap nhat trang thai tham gia.', [
                'chien_dich_id' => $cd->id,
                'dang_ky_id' => $dangKy->id,
                'nguoi_dung_id' => $dangKy->nguoi_dung_id,
                'nguoi_thuc_hien_id' => $user->id,
                'tu_trang_thai' => $trangThaiCu,
                'den_trang_thai' => $trangThaiMoi,
            ]);
        });

        $cd->refresh();
        $dangKy->refresh();

        return response()->json([
            'status' => 1,
            'message' => 'Cập nhật trạng thái tham gia thành công.',
            'data' => [
                'dang_ky_id' => $dangKy->id,
                'trang_thai' => $dangKy->trang_thai,
                'duyet_luc' => optional($dangKy->duyet_luc)->format('Y-m-d H:i:s'),
                'xac_nhan_luc' => optional($dangKy->xac_nhan_luc)->format('Y-m-d H:i:s'),
                'huy_luc' => optional($dangKy->huy_luc)->format('Y-m-d H:i:s'),
                'ghi_chu' => $dangKy->ghi_chu,
                'ly_do_huy' => $dangKy->ly_do_huy,
                'so_dang_ky' => (int) $cd->so_dang_ky,
                'so_xac_nhan' => (int) $cd->so_xac_nhan,
            ],
        ]);
    }

    // ======================== YÊU CẦU HỦY CHIẾN DỊCH (NGƯỜI TẠO GỬI YÊU CẦU -> KDV DUYỆT) ========================
    public function huyChienDich(Request $request, $id)
    {
        $user = auth('api')->user();

        $cd = ChienDich::where('id', $id)
            ->where('nguoi_tao_id', $user->id)
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
                'message' => 'Chiến dịch này đang chờ Kiểm duyệt viên duyệt hủy.',
            ], 422);
        }

        if ($cd->trang_thai === 'hoan_thanh') {
            return response()->json([
                'status'  => 0,
                'message' => 'Không thể hủy chiến dịch đã hoàn thành.',
            ], 422);
        }

        $lyDo = $request->ly_do ?? 'Người tạo chiến dịch yêu cầu hủy chiến dịch.';

        $cd->update([
            'trang_thai'    => 'yeu_cau_huy',
            'ly_do_tu_choi' => $lyDo,
        ]);

        LichSuKiemDuyetChienDich::create([
            'chien_dich_id' => $cd->id,
            'nguoi_thuc_hien_id' => $user->id,
            'hanh_dong' => 'gui_yeu_cau_huy',
            'tu_trang_thai' => $cd->getOriginal('trang_thai'),
            'den_trang_thai' => 'yeu_cau_huy',
            'ghi_chu' => $lyDo,
            'du_lieu_bo_sung' => [
                'nguoi_tao_id' => $user->id,
            ],
        ]);

        $danhSachKiemDuyetVien = \App\Models\NguoiDung::where('vai_tro', 'kiem_duyet_vien')
            ->whereNull('xoa_luc')
            ->get(['id']);

        foreach ($danhSachKiemDuyetVien as $kiemDuyetVien) {
            ThongBao::create([
                'nguoi_dung_id' => $kiemDuyetVien->id,
                'nguoi_gui_id' => $user->id,
                'loai' => 'cap_nhat_cd',
                'tieu_de' => 'Có yêu cầu hủy chiến dịch mới',
                'noi_dung' => 'Chiến dịch "' . $cd->tieu_de . '" đang chờ kiểm duyệt yêu cầu hủy.',
                'loai_tham_chieu' => 'chien_dich',
                'tham_chieu_id' => $cd->id,
                'gui_qua' => 'he_thong',
            ]);
        }

        // Gửi email thông báo cho tất cả TNV đã đăng ký (chưa hủy) rằng chiến dịch đang chờ xét duyệt hủy.
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
                        'link_chien_dich' => config('app.frontend_url', 'http://localhost:5173') . '/danh-sach-chien-dich',
                    ]
                );
            }
        }

        $this->forgetOwnerStartReminderCache($cd->id);

        return response()->json([
            'status'  => 1,
            'message' => 'Đã gửi yêu cầu hủy chiến dịch. Vui lòng chờ Kiểm duyệt viên phê duyệt.'
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

    private function guiThongBaoCapNhatTrangThai(
        ChienDich $cd,
        int $nguoiGuiId,
        string $trangThaiMoi,
        ?string $ghiChu = null,
        array $thongTinDongBo = []
    ): void
    {
        $danhSachDangKy = $cd->dangKyThamGias()->with('nguoiDung:id,ho_ten,email')->get();
        $dangThamGiaIds = collect($thongTinDongBo['dang_tham_gia_ids'] ?? [])->map(fn ($id) => (int) $id)->all();
        $tuDongTuChoiIds = collect($thongTinDongBo['tu_dong_tu_choi_ids'] ?? [])->map(fn ($id) => (int) $id)->all();
        $hoanThanhIds = collect($thongTinDongBo['hoan_thanh_ids'] ?? [])->map(fn ($id) => (int) $id)->all();

        if ($trangThaiMoi === 'dang_dien_ra') {
            foreach ($danhSachDangKy as $dangKy) {
                $tnv = $dangKy->nguoiDung;
                if (!$tnv) {
                    continue;
                }

                if (in_array((int) $dangKy->id, $dangThamGiaIds, true)) {
                    $tieuDe = 'Chiến dịch đã bắt đầu';
                    $noiDung = 'Chiến dịch "' . $cd->tieu_de . '" đã bắt đầu. Bạn đang ở danh sách tham gia chính thức.';
                    if ($ghiChu) {
                        $noiDung .= ' Ghi chú: ' . $ghiChu;
                    }

                    $this->taoThongBaoCapNhatTrangThaiChienDich($tnv->id, $nguoiGuiId, $tieuDe, $noiDung, $cd->id);
                    $this->guiMailTrangThaiDangKyChienDich($tnv->email, 'chien_dich_bat_dau', [
                        'ho_ten' => $tnv->ho_ten,
                        'ten_chien_dich' => $cd->tieu_de,
                        'dia_diem' => $cd->dia_diem,
                        'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                        'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                        'ghi_chu' => $ghiChu,
                        'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . '/chi-tiet-chien-dich/' . $cd->id,
                    ]);
                    continue;
                }

                if (in_array((int) $dangKy->id, $tuDongTuChoiIds, true)) {
                    $tieuDe = 'Đăng ký tham gia không còn hiệu lực';
                    $noiDung = 'Bạn chưa xác nhận tham gia trước khi chiến dịch "' . $cd->tieu_de . '" bắt đầu, nên đăng ký đã được đóng lại.';

                    $this->taoThongBaoCapNhatTrangThaiChienDich($tnv->id, $nguoiGuiId, $tieuDe, $noiDung, $cd->id);
                    $this->guiMailTrangThaiDangKyChienDich($tnv->email, 'tu_dong_tu_choi_do_chua_xac_nhan', [
                        'ho_ten' => $tnv->ho_ten,
                        'ten_chien_dich' => $cd->tieu_de,
                        'dia_diem' => $cd->dia_diem,
                        'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                        'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                        'ghi_chu' => $ghiChu,
                        'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . '/chi-tiet-chien-dich/' . $cd->id,
                    ]);
                }
            }

            return;
        }

        foreach ($danhSachDangKy as $dangKy) {
            $tnv = $dangKy->nguoiDung;
            if (!$tnv || !in_array((int) $dangKy->id, $hoanThanhIds, true)) {
                continue;
            }

            $tieuDe = 'Chiến dịch đã hoàn thành';
            $noiDung = 'Chiến dịch "' . $cd->tieu_de . '" đã hoàn thành. Cảm ơn bạn đã tham gia.';
            if ($ghiChu) {
                $noiDung .= ' Ghi chú: ' . $ghiChu;
            }

            $this->taoThongBaoCapNhatTrangThaiChienDich($tnv->id, $nguoiGuiId, $tieuDe, $noiDung, $cd->id);
            $this->guiMailTrangThaiDangKyChienDich($tnv->email, 'chien_dich_hoan_thanh', [
                'ho_ten' => $tnv->ho_ten,
                'ten_chien_dich' => $cd->tieu_de,
                'dia_diem' => $cd->dia_diem,
                'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                'ghi_chu' => $ghiChu,
                'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . '/chi-tiet-chien-dich/' . $cd->id,
            ]);
        }
    }

    private function dongBoTrangThaiDangKyTheoTrangThaiChienDich(ChienDich $cd, string $trangThaiMoi): array
    {
        $ketQua = [
            'dang_tham_gia_ids' => [],
            'tu_dong_tu_choi_ids' => [],
            'hoan_thanh_ids' => [],
        ];

        if ($trangThaiMoi === 'dang_dien_ra') {
            $dangThamGiaIds = $cd->dangKyThamGias()
                ->where('trang_thai', 'da_duyet')
                ->pluck('id')
                ->all();

            $cd->dangKyThamGias()
                ->whereIn('id', $dangThamGiaIds)
                ->update([
                    'trang_thai' => 'dang_tham_gia',
                    'ghi_chu' => 'Tự động chuyển sang đang tham gia khi chiến dịch bắt đầu.',
                ]);
            $ketQua['dang_tham_gia_ids'] = $dangThamGiaIds;

            $tuDongTuChoiIds = $cd->dangKyThamGias()
                ->whereIn('trang_thai', ['da_dang_ky', 'da_xac_nhan'])
                ->pluck('id')
                ->all();

            $cd->dangKyThamGias()
                ->whereIn('id', $tuDongTuChoiIds)
                ->update([
                    'trang_thai' => 'tu_choi',
                    'ghi_chu' => 'Tự động đóng đăng ký do chưa xác nhận tham gia trước khi chiến dịch bắt đầu.',
                ]);
            $ketQua['tu_dong_tu_choi_ids'] = $tuDongTuChoiIds;
        }

        if ($trangThaiMoi === 'hoan_thanh') {
            $hoanThanhIds = $cd->dangKyThamGias()
                ->where('trang_thai', 'dang_tham_gia')
                ->pluck('id')
                ->all();

            $cd->dangKyThamGias()
                ->whereIn('id', $hoanThanhIds)
                ->update([
                    'trang_thai' => 'hoan_thanh',
                    'ghi_chu' => 'Tự động chuyển sang hoàn thành khi chiến dịch kết thúc.',
                ]);
            $ketQua['hoan_thanh_ids'] = $hoanThanhIds;
        }

        $cd->refresh();
        $this->dongBoSoLuongDangKy($cd);

        return $ketQua;
    }

    private function buildStartCampaignWarning(ChienDich $cd): ?array
    {
        $soXacNhan = $cd->dangKyThamGias()
            ->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])
            ->count();

        $soChuaXacNhan = $cd->dangKyThamGias()
            ->whereIn('trang_thai', ['da_dang_ky', 'da_xac_nhan'])
            ->count();

        $soLuongToiThieu = (int) ($cd->so_luong_toi_thieu ?? 0);

        $batDauSomHonDuKien = $cd->ngay_bat_dau
            ? now()->lt($cd->ngay_bat_dau->copy()->startOfDay())
            : false;

        $warningItems = [];

        if ($soLuongToiThieu > 0 && $soXacNhan < $soLuongToiThieu) {
            $warningItems[] = [
                'code' => 'insufficient_confirmed_volunteers',
                'message' => 'Số lượng tình nguyện viên đã xác nhận hiện chưa đạt mức tối thiểu.',
            ];
        }

        if ($soChuaXacNhan > 0) {
            $warningItems[] = [
                'code' => 'pending_volunteer_confirmations',
                'message' => 'Vẫn còn tình nguyện viên đang chờ xác nhận hoặc chờ được duyệt.',
            ];
        }

        if ($batDauSomHonDuKien) {
            $warningItems[] = [
                'code' => 'starting_before_planned_date',
                'message' => 'Chiến dịch đang được bắt đầu sớm hơn ngày dự kiến ban đầu.',
            ];
        }

        if (!empty($warningItems)) {
            $warningCodes = collect($warningItems)->pluck('code')->all();

            return [
                'code' => in_array('insufficient_confirmed_volunteers', $warningCodes, true)
                    ? 'insufficient_confirmed_volunteers'
                    : 'starting_before_planned_date',
                'message' => 'Có cảnh báo trước khi bắt đầu chiến dịch. Bạn vẫn có thể tiếp tục nếu chấp nhận các thay đổi sẽ được áp dụng ngay.',
                'warning_items' => $warningItems,
                'so_xac_nhan' => $soXacNhan,
                'so_luong_toi_thieu' => $soLuongToiThieu,
                'so_chua_xac_nhan' => $soChuaXacNhan,
                'bat_dau_som_hon_du_kien' => $batDauSomHonDuKien,
                'ngay_bat_dau_du_kien' => $cd->ngay_bat_dau?->format('Y-m-d'),
                'chi_tiet' => $batDauSomHonDuKien
                    ? 'Hệ thống sẽ ghi nhận thời gian bắt đầu thực tế riêng để không phụ thuộc vào ngày bắt đầu khi tạo chiến dịch.'
                    : null,
            ];
        }

        return null;
    }

    private function dongBoSoLuongDangKy(ChienDich $cd): void
    {
        $cd->update([
            'so_dang_ky' => $cd->dangKyThamGias()->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])->count(),
            'so_xac_nhan' => $cd->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
        ]);
    }

    private function ghiLogTrangThaiChienDich(
        ChienDich $cd,
        int $nguoiThucHienId,
        string $trangThaiMoi,
        ?array $warningInfo = null
    ): void {
        $context = [
            'chien_dich_id' => $cd->id,
            'nguoi_thuc_hien_id' => $nguoiThucHienId,
            'trang_thai_moi' => $trangThaiMoi,
            'ngay_bat_dau_du_kien' => $cd->ngay_bat_dau?->format('Y-m-d'),
            'ngay_ket_thuc_du_kien' => $cd->ngay_ket_thuc?->format('Y-m-d'),
            'thoi_gian_bat_dau_thuc_te' => $cd->thoi_gian_bat_dau_thuc_te?->format('Y-m-d H:i:s'),
            'thoi_gian_ket_thuc_thuc_te' => $cd->thoi_gian_ket_thuc_thuc_te?->format('Y-m-d H:i:s'),
            'warning' => $warningInfo,
        ];

        if (!empty($warningInfo)) {
            Log::warning('Cap nhat trang thai chien dich co canh bao.', $context);
            return;
        }

        Log::info('Cap nhat vong doi chien dich thanh cong.', $context);
    }

    private function layTieuDeThongBaoTrangThaiDangKy(string $trangThaiMoi): string
    {
        return match ($trangThaiMoi) {
            'da_duyet' => 'Chủ chiến dịch đã duyệt xác nhận tham gia của bạn',
            'tu_choi' => 'Chủ chiến dịch đã từ chối xác nhận tham gia',
            default => 'Trạng thái tham gia chiến dịch đã được cập nhật',
        };
    }

    private function layNoiDungThongBaoTrangThaiDangKy(ChienDich $cd, string $trangThaiMoi, string $ghiChu = ''): string
    {
        $noiDung = match ($trangThaiMoi) {
            'da_duyet' => 'Chủ chiến dịch đã duyệt xác nhận tham gia của bạn cho chiến dịch "' . $cd->tieu_de . '". Bạn đã ở trong danh sách chính thức của chiến dịch.',
            'tu_choi' => 'Chủ chiến dịch đã từ chối đăng ký tham gia chiến dịch "' . $cd->tieu_de . '".',
            default => 'Trạng thái đăng ký tham gia chiến dịch "' . $cd->tieu_de . '" đã được cập nhật.',
        };

        if ($ghiChu !== '') {
            $noiDung .= ' Ghi chú: ' . $ghiChu;
        }

        return $noiDung;
    }

    private function taoThongBaoCapNhatTrangThaiChienDich(int $nguoiDungId, int $nguoiGuiId, string $tieuDe, string $noiDung, int $campaignId): void
    {
        ThongBao::create([
            'nguoi_dung_id' => $nguoiDungId,
            'nguoi_gui_id' => $nguoiGuiId,
            'loai' => 'cap_nhat_cd',
            'tieu_de' => $tieuDe,
            'noi_dung' => $noiDung,
            'loai_tham_chieu' => 'chien_dich',
            'tham_chieu_id' => $campaignId,
            'gui_qua' => 'ca_hai',
        ]);
    }

    private function guiMailTrangThaiDangKyChienDich(?string $email, string $loai, array $data): void
    {
        if (!$email) {
            return;
        }

        $titles = [
            'chien_dich_bat_dau' => 'Chiến dịch đã bắt đầu',
            'tu_dong_tu_choi_do_chua_xac_nhan' => 'Đăng ký tham gia không còn hiệu lực',
            'chien_dich_hoan_thanh' => 'Chiến dịch đã hoàn thành',
        ];

        SendMailJob::dispatch(
            $email,
            $titles[$loai] ?? 'Cập nhật trạng thái tham gia chiến dịch',
            'cap_nhat_trang_thai_tham_gia_chien_dich',
            array_merge($data, ['loai' => $loai])
        );
    }

    private function luuAnhBia($file): string
    {
        $path = $file->store('campaign-covers', 'public');

        return Storage::disk('public')->url($path);
    }

    private function forgetOwnerStartReminderCache(int $campaignId): void
    {
        Cache::forget("campaigns:owner-start-reminder-sent:{$campaignId}");
    }
}

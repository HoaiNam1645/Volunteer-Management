<?php

namespace App\Http\Controllers;

use App\Jobs\SendMailJob;
use App\Models\BaoCaoChienDich;
use App\Models\ChienDich;
use App\Models\LichSuKiemDuyetChienDich;
use App\Models\ThongBao;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KiemDuyetChienDichController extends Controller
{
    public function danhSach(Request $request)
    {
        $query = ChienDich::query()
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email',
            ]);

        if ($request->filled('trang_thai') && $request->trang_thai !== 'all') {
            $query->where('trang_thai', $request->trang_thai);
        }

        if ($request->filled('tu_khoa')) {
            $keyword = trim($request->tu_khoa);
            $query->where(function ($sub) use ($keyword) {
                $sub->where('tieu_de', 'like', "%{$keyword}%")
                    ->orWhere('dia_diem', 'like', "%{$keyword}%")
                    ->orWhereHas('nguoiTao', function ($nguoiTaoQuery) use ($keyword) {
                        $nguoiTaoQuery->where('ho_ten', 'like', "%{$keyword}%")
                            ->orWhere('email', 'like', "%{$keyword}%");
                    });
            });
        }

        if ($request->filled('loai_chien_dich_id')) {
            $query->where('loai_chien_dich_id', $request->integer('loai_chien_dich_id'));
        }

        if ($request->filled('muc_do_uu_tien')) {
            $query->where('muc_do_uu_tien', $request->muc_do_uu_tien);
        }

        $campaigns = $query->orderByRaw("FIELD(trang_thai, 'yeu_cau_huy', 'cho_duyet', 'dang_dien_ra', 'da_duyet', 'hoan_thanh', 'tu_choi', 'da_huy', 'nhap')")
            ->orderByDesc('tao_luc')
            ->get();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy danh sách chiến dịch kiểm duyệt thành công.',
            'data' => $campaigns->map(fn ($cd) => $this->mapCampaignSummary($cd))->values(),
            'thong_ke' => [
                'tong' => ChienDich::whereNull('xoa_luc')->count(),
                'cho_duyet' => ChienDich::whereNull('xoa_luc')->where('trang_thai', 'cho_duyet')->count(),
                'yeu_cau_huy' => ChienDich::whereNull('xoa_luc')->where('trang_thai', 'yeu_cau_huy')->count(),
                'dang_dien_ra' => ChienDich::whereNull('xoa_luc')->where('trang_thai', 'dang_dien_ra')->count(),
                'hoan_thanh' => ChienDich::whereNull('xoa_luc')->where('trang_thai', 'hoan_thanh')->count(),
            ],
        ]);
    }

    public function chiTiet($id)
    {
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Lấy chi tiết chiến dịch thành công.',
            'data' => $this->mapCampaignDetail($cd),
        ]);
    }

    public function duyet($id)
    {
        $reviewer = auth('api')->user();
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }
        if ($cd->trang_thai !== 'cho_duyet') {
            return response()->json(['status' => 0, 'message' => 'Chỉ có thể duyệt chiến dịch đang chờ duyệt.'], 422);
        }

        DB::transaction(function () use ($cd, $reviewer) {
            $oldStatus = $cd->trang_thai;
            $cd->update([
                'trang_thai' => 'da_duyet',
                'duyet_boi' => $reviewer->id,
                'duyet_luc' => now(),
                'ly_do_tu_choi' => null,
            ]);
            $this->ghiLichSu($cd->id, $reviewer->id, 'duyet_chien_dich', $oldStatus, 'da_duyet', 'Chiến dịch được duyệt.');
            $this->guiThongBaoKetQua($cd, $reviewer->id, 'duyet', 'Chiến dịch của bạn đã được duyệt và sẵn sàng cho các bước tiếp theo.', null, 'Đã duyệt');
        });

        return response()->json(['status' => 1, 'message' => 'Duyệt chiến dịch thành công.']);
    }

    public function tuChoi(Request $request, $id)
    {
        $request->validate([
            'ly_do' => 'required|string|max:1000',
        ]);

        $reviewer = auth('api')->user();
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }
        if ($cd->trang_thai !== 'cho_duyet') {
            return response()->json(['status' => 0, 'message' => 'Chỉ có thể từ chối chiến dịch đang chờ duyệt.'], 422);
        }

        DB::transaction(function () use ($cd, $reviewer, $request) {
            $oldStatus = $cd->trang_thai;
            $cd->update([
                'trang_thai' => 'tu_choi',
                'duyet_boi' => $reviewer->id,
                'duyet_luc' => now(),
                'ly_do_tu_choi' => $request->ly_do,
            ]);
            $this->ghiLichSu($cd->id, $reviewer->id, 'tu_choi_chien_dich', $oldStatus, 'tu_choi', $request->ly_do);
            $this->guiThongBaoKetQua($cd, $reviewer->id, 'tu_choi', 'Chiến dịch của bạn đã bị từ chối sau khi kiểm duyệt.', $request->ly_do, 'Từ chối');
        });

        return response()->json(['status' => 1, 'message' => 'Đã từ chối chiến dịch.']);
    }

    public function duyetYeuCauHuy($id)
    {
        $reviewer = auth('api')->user();
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }
        if ($cd->trang_thai !== 'yeu_cau_huy') {
            return response()->json(['status' => 0, 'message' => 'Chiến dịch này không ở trạng thái chờ duyệt hủy.'], 422);
        }

        DB::transaction(function () use ($cd, $reviewer) {
            $oldStatus = $cd->trang_thai;
            $lyDo = $cd->ly_do_tu_choi;
            $cd->update([
                'trang_thai' => 'da_huy',
                'duyet_boi' => $reviewer->id,
                'duyet_luc' => now(),
            ]);
            $this->ghiLichSu($cd->id, $reviewer->id, 'duyet_huy_chien_dich', $oldStatus, 'da_huy', $lyDo);
            $this->guiThongBaoKetQua($cd, $reviewer->id, 'duyet_huy', 'Yêu cầu hủy chiến dịch của bạn đã được chấp thuận.', $lyDo, 'Đã hủy');
            $this->guiThongBaoKetQuaHuyChoTnv($cd, $reviewer->id, true, $lyDo, 'da_huy');
        });

        return response()->json(['status' => 1, 'message' => 'Đã duyệt yêu cầu hủy chiến dịch.']);
    }

    public function tuChoiYeuCauHuy(Request $request, $id)
    {
        $request->validate([
            'ly_do' => 'required|string|max:1000',
        ]);

        $reviewer = auth('api')->user();
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }
        if ($cd->trang_thai !== 'yeu_cau_huy') {
            return response()->json(['status' => 0, 'message' => 'Chiến dịch này không ở trạng thái chờ duyệt hủy.'], 422);
        }

        DB::transaction(function () use ($cd, $reviewer, $request) {
            $oldStatus = $cd->trang_thai;
            $restoredStatus = $this->resolveStatusBeforeCancel($cd);
            $cd->update([
                'trang_thai' => $restoredStatus,
                'duyet_boi' => $reviewer->id,
                'duyet_luc' => now(),
                'ly_do_tu_choi' => $request->ly_do,
            ]);
            $this->ghiLichSu($cd->id, $reviewer->id, 'tu_choi_huy_chien_dich', $oldStatus, $restoredStatus, $request->ly_do);
            $this->guiThongBaoKetQua($cd, $reviewer->id, 'tu_choi_huy', 'Yêu cầu hủy chiến dịch của bạn đã bị từ chối.', $request->ly_do, $this->humanCampaignStatus($restoredStatus));
            $this->guiThongBaoKetQuaHuyChoTnv($cd, $reviewer->id, false, $request->ly_do, $restoredStatus);
        });

        return response()->json(['status' => 1, 'message' => 'Đã từ chối yêu cầu hủy chiến dịch.']);
    }

    public function capNhatTrangThai(Request $request, $id)
    {
        $request->validate([
            'trang_thai' => 'required|in:dang_dien_ra,hoan_thanh',
            'ghi_chu' => 'nullable|string|max:1000',
        ]);

        $reviewer = auth('api')->user();
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }

        $allowedTransitions = [
            'da_duyet' => ['dang_dien_ra'],
            'dang_dien_ra' => ['hoan_thanh'],
        ];

        $nextStatus = $request->trang_thai;
        if (!in_array($nextStatus, $allowedTransitions[$cd->trang_thai] ?? [], true)) {
            return response()->json(['status' => 0, 'message' => 'Chuyển trạng thái không hợp lệ.'], 422);
        }

        DB::transaction(function () use ($cd, $reviewer, $nextStatus, $request) {
            $oldStatus = $cd->trang_thai;
            $cd->update([
                'trang_thai' => $nextStatus,
            ]);
            $this->ghiLichSu($cd->id, $reviewer->id, 'cap_nhat_trang_thai', $oldStatus, $nextStatus, $request->ghi_chu);
            $this->guiThongBaoKetQua($cd, $reviewer->id, 'cap_nhat_trang_thai', 'Trạng thái chiến dịch của bạn vừa được cập nhật.', $request->ghi_chu, $this->humanCampaignStatus($nextStatus));
        });

        return response()->json(['status' => 1, 'message' => 'Cập nhật trạng thái chiến dịch thành công.']);
    }

    public function danhSachFeedback($id)
    {
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }

        return response()->json([
            'status' => 1,
            'data' => $cd->feedbacks->map(fn ($feedback) => $this->mapFeedback($feedback))->values(),
        ]);
    }

    public function danhSachBaoCao($id)
    {
        $cd = $this->findCampaignForReview($id);
        if (!$cd) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy chiến dịch.'], 404);
        }

        return response()->json([
            'status' => 1,
            'data' => $cd->baoCaos->map(fn ($baoCao) => $this->mapBaoCao($baoCao))->values(),
        ]);
    }

    public function xuLyBaoCao(Request $request, $id)
    {
        $request->validate([
            'trang_thai' => 'required|in:dang_xu_ly,da_xu_ly,tu_choi',
            'phan_hoi_xu_ly' => 'nullable|string|max:2000',
        ]);

        $reviewer = auth('api')->user();
        $baoCao = BaoCaoChienDich::with(['chienDich.nguoiTao:id,ho_ten,email', 'nguoiGui:id,ho_ten,email'])
            ->find($id);

        if (!$baoCao) {
            return response()->json(['status' => 0, 'message' => 'Không tìm thấy báo cáo.'], 404);
        }

        DB::transaction(function () use ($baoCao, $reviewer, $request) {
            $baoCao->update([
                'trang_thai' => $request->trang_thai,
                'nguoi_xu_ly_id' => $reviewer->id,
                'xu_ly_luc' => now(),
                'phan_hoi_xu_ly' => $request->phan_hoi_xu_ly,
            ]);

            $this->ghiLichSu(
                $baoCao->chien_dich_id,
                $reviewer->id,
                'xu_ly_bao_cao',
                null,
                null,
                $request->phan_hoi_xu_ly,
                ['bao_cao_id' => $baoCao->id, 'trang_thai' => $request->trang_thai]
            );
        });

        return response()->json(['status' => 1, 'message' => 'Xử lý báo cáo thành công.']);
    }

    private function findCampaignForReview($id): ?ChienDich
    {
        return ChienDich::where('id', $id)
            ->whereNull('xoa_luc')
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email',
                'feedbacks.nguoiDung:id,ho_ten,email',
                'feedbacks.thePhanHois:id,ten',
                'baoCaos.nguoiGui:id,ho_ten,email',
                'baoCaos.nguoiXuLy:id,ho_ten,email',
                'lichSuKiemDuyets.nguoiThucHien:id,ho_ten,email',
            ])
            ->first();
    }

    private function mapCampaignSummary(ChienDich $cd): array
    {
        return [
            'id' => $cd->id,
            'tieu_de' => $cd->tieu_de,
            'dia_diem' => $cd->dia_diem,
            'vi_do' => $cd->vi_do,
            'kinh_do' => $cd->kinh_do,
            'ngay_bat_dau' => $cd->ngay_bat_dau?->format('Y-m-d'),
            'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('Y-m-d'),
            'so_luong_toi_da' => $cd->so_luong_toi_da,
            'so_dang_ky' => $cd->so_dang_ky,
            'muc_do_uu_tien' => $cd->muc_do_uu_tien,
            'trang_thai' => $cd->trang_thai,
            'ly_do_tu_choi' => $cd->ly_do_tu_choi,
            'loai_chien_dich' => $cd->loaiChienDich,
            'nguoi_tao' => $cd->nguoiTao,
            'duyet_boi' => $cd->duyetBoi,
            'tao_luc' => $cd->tao_luc?->format('Y-m-d H:i:s'),
            'duyet_luc' => $cd->duyet_luc?->format('Y-m-d H:i:s'),
        ];
    }

    private function mapCampaignDetail(ChienDich $cd): array
    {
        return array_merge($this->mapCampaignSummary($cd), [
            'mo_ta' => $cd->mo_ta,
            'han_dang_ky' => $cd->han_dang_ky?->format('Y-m-d'),
            'so_luong_toi_thieu' => $cd->so_luong_toi_thieu,
            'ky_nangs' => $cd->kyNangs->map(fn ($kyNang) => [
                'id' => $kyNang->id,
                'ten' => $kyNang->ten,
            ])->values(),
            'feedbacks' => $cd->feedbacks->map(fn ($feedback) => $this->mapFeedback($feedback))->values(),
            'bao_caos' => $cd->baoCaos->map(fn ($baoCao) => $this->mapBaoCao($baoCao))->values(),
            'lich_su_kiem_duyet' => $cd->lichSuKiemDuyets->sortByDesc('tao_luc')->values()->map(function ($item) {
                return [
                    'id' => $item->id,
                    'hanh_dong' => $item->hanh_dong,
                    'tu_trang_thai' => $item->tu_trang_thai,
                    'den_trang_thai' => $item->den_trang_thai,
                    'ghi_chu' => $item->ghi_chu,
                    'du_lieu_bo_sung' => $item->du_lieu_bo_sung,
                    'tao_luc' => $item->tao_luc?->format('Y-m-d H:i:s'),
                    'nguoi_thuc_hien' => $item->nguoiThucHien ? [
                        'id' => $item->nguoiThucHien->id,
                        'ho_ten' => $item->nguoiThucHien->ho_ten,
                        'email' => $item->nguoiThucHien->email,
                    ] : null,
                ];
            })->values(),
        ]);
    }

    private function mapFeedback($feedback): array
    {
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
    }

    private function mapBaoCao($baoCao): array
    {
        return [
            'id' => $baoCao->id,
            'phan_loai' => $baoCao->phan_loai,
            'tieu_de' => $baoCao->tieu_de,
            'noi_dung' => $baoCao->noi_dung,
            'trang_thai' => $baoCao->trang_thai,
            'phan_hoi_xu_ly' => $baoCao->phan_hoi_xu_ly,
            'xu_ly_luc' => $baoCao->xu_ly_luc?->format('Y-m-d H:i:s'),
            'tao_luc' => $baoCao->tao_luc?->format('Y-m-d H:i:s'),
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
    }

    private function ghiLichSu(int $chienDichId, int $nguoiThucHienId, string $hanhDong, ?string $tuTrangThai, ?string $denTrangThai, ?string $ghiChu = null, ?array $duLieuBoSung = null): void
    {
        LichSuKiemDuyetChienDich::create([
            'chien_dich_id' => $chienDichId,
            'nguoi_thuc_hien_id' => $nguoiThucHienId,
            'hanh_dong' => $hanhDong,
            'tu_trang_thai' => $tuTrangThai,
            'den_trang_thai' => $denTrangThai,
            'ghi_chu' => $ghiChu,
            'du_lieu_bo_sung' => $duLieuBoSung,
        ]);
    }

    private function guiThongBaoKetQua(ChienDich $cd, int $nguoiGuiId, string $loai, string $thongDiep, ?string $lyDo, string $trangThaiHienTai): void
    {
        $nguoiTao = $cd->nguoiTao;
        if (!$nguoiTao) {
            return;
        }

        ThongBao::create([
            'nguoi_dung_id' => $nguoiTao->id,
            'nguoi_gui_id' => $nguoiGuiId,
            'loai' => 'cap_nhat_cd',
            'tieu_de' => 'Chiến dịch "' . $cd->tieu_de . '" vừa được cập nhật',
            'noi_dung' => $thongDiep,
            'loai_tham_chieu' => 'chien_dich',
            'tham_chieu_id' => $cd->id,
            'gui_qua' => 'ca_hai',
        ]);

        if ($nguoiTao->email) {
            SendMailJob::dispatch(
                $nguoiTao->email,
                'Thông báo chiến dịch: ' . $cd->tieu_de,
                'ket_qua_duyet_chien_dich',
                [
                    'loai' => $loai,
                    'ho_ten' => $nguoiTao->ho_ten,
                    'thong_diep' => $thongDiep,
                    'ten_chien_dich' => $cd->tieu_de,
                    'dia_diem' => $cd->dia_diem,
                    'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                    'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                    'ly_do' => $lyDo,
                    'trang_thai_hien_tai' => $trangThaiHienTai,
                    'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5180'), '/') . '/quan-ly-chien-dich/chi-tiet/' . $cd->id,
                ]
            );
        }
    }

    private function guiThongBaoKetQuaHuyChoTnv(ChienDich $cd, int $nguoiGuiId, bool $daDuyetHuy, ?string $lyDo, string $trangThaiHienTai): void
    {
        $danhSachDangKy = $cd->dangKyThamGias()
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->with('nguoiDung:id,ho_ten,email')
            ->get();

        foreach ($danhSachDangKy as $dangKy) {
            $tnv = $dangKy->nguoiDung;
            if (!$tnv) {
                continue;
            }

            ThongBao::create([
                'nguoi_dung_id' => $tnv->id,
                'nguoi_gui_id' => $nguoiGuiId,
                'loai' => 'cap_nhat_cd',
                'tieu_de' => $daDuyetHuy
                    ? 'Chiến dịch "' . $cd->tieu_de . '" đã bị hủy'
                    : 'Chiến dịch "' . $cd->tieu_de . '" tiếp tục diễn ra',
                'noi_dung' => $daDuyetHuy
                    ? 'Yêu cầu hủy chiến dịch đã được kiểm duyệt viên chấp thuận.'
                    : 'Yêu cầu hủy chiến dịch đã bị từ chối. Chiến dịch tiếp tục diễn ra theo kế hoạch.',
                'loai_tham_chieu' => 'chien_dich',
                'tham_chieu_id' => $cd->id,
                'gui_qua' => 'ca_hai',
            ]);

            if ($tnv->email) {
                if ($daDuyetHuy) {
                    SendMailJob::dispatch(
                        $tnv->email,
                        'Thông báo: Chiến dịch "' . $cd->tieu_de . '" đã bị hủy',
                        'huy_chien_dich',
                        [
                            'ho_ten' => $tnv->ho_ten,
                            'ten_chien_dich' => $cd->tieu_de,
                            'dia_diem' => $cd->dia_diem,
                            'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                            'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                            'ly_do' => $lyDo,
                            'trang_thai_huy' => 'da_huy',
                            'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5180'), '/') . '/danh-sach-chien-dich',
                        ]
                    );
                } else {
                    SendMailJob::dispatch(
                        $tnv->email,
                        'Thông báo: Chiến dịch "' . $cd->tieu_de . '" tiếp tục diễn ra',
                        'ket_qua_huy_chien_dich_tnv',
                        [
                            'ho_ten' => $tnv->ho_ten,
                            'ten_chien_dich' => $cd->tieu_de,
                            'dia_diem' => $cd->dia_diem,
                            'ngay_bat_dau' => $cd->ngay_bat_dau?->format('d/m/Y'),
                            'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('d/m/Y'),
                            'ly_do' => $lyDo,
                            'trang_thai_hien_tai' => $this->humanCampaignStatus($trangThaiHienTai),
                            'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5180'), '/') . '/danh-sach-chien-dich',
                        ]
                    );
                }
            }
        }
    }

    private function resolveStatusBeforeCancel(ChienDich $cd): string
    {
        if (!$cd->duyet_boi) {
            return 'cho_duyet';
        }
        if ($cd->ngay_bat_dau && $cd->ngay_bat_dau->isPast() && (!$cd->ngay_ket_thuc || $cd->ngay_ket_thuc->isFuture())) {
            return 'dang_dien_ra';
        }
        return 'da_duyet';
    }

    private function humanCampaignStatus(string $status): string
    {
        return [
            'cho_duyet' => 'Chờ duyệt',
            'tu_choi' => 'Từ chối',
            'da_duyet' => 'Đã duyệt',
            'dang_dien_ra' => 'Đang diễn ra',
            'hoan_thanh' => 'Hoàn thành',
            'yeu_cau_huy' => 'Yêu cầu hủy',
            'da_huy' => 'Đã hủy',
            'nhap' => 'Nháp',
        ][$status] ?? $status;
    }
}

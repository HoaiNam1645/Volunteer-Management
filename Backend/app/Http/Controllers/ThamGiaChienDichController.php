<?php

namespace App\Http\Controllers;

use App\Jobs\SendMailJob;
use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\LoaiChienDich;
use App\Models\ThongBao;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class ThamGiaChienDichController extends Controller
{
    private const PUBLIC_STATUSES = ['da_duyet', 'dang_dien_ra', 'hoan_thanh'];

    public function boLoc()
    {
        $baseQuery = ChienDich::query()
            ->whereNull('chien_dichs.xoa_luc')
            ->whereIn('chien_dichs.trang_thai', self::PUBLIC_STATUSES);

        $categoryCounts = (clone $baseQuery)
            ->select('chien_dichs.loai_chien_dich_id', DB::raw('COUNT(chien_dichs.id) as total'))
            ->groupBy('chien_dichs.loai_chien_dich_id')
            ->pluck('total', 'chien_dichs.loai_chien_dich_id');

        $categories = LoaiChienDich::query()
            ->orderBy('ten')
            ->get(['id', 'ten'])
            ->map(fn ($item) => [
                'value' => (string) $item->id,
                'label' => $item->ten,
                'count' => (int) ($categoryCounts[$item->id] ?? 0),
            ])
            ->values();

        $creators = (clone $baseQuery)
            ->join('nguoi_dungs', 'chien_dichs.nguoi_tao_id', '=', 'nguoi_dungs.id')
            ->select(
                'nguoi_dungs.id',
                'nguoi_dungs.ho_ten',
                DB::raw('COUNT(chien_dichs.id) as total')
            )
            ->groupBy('nguoi_dungs.id', 'nguoi_dungs.ho_ten')
            ->orderBy('nguoi_dungs.ho_ten')
            ->get();

        $statusCounts = [
            'registering' => 0,
            'closed_registration' => 0,
            'upcoming' => 0,
            'completed' => 0,
        ];

        (clone $baseQuery)
            ->get(['id', 'trang_thai', 'han_dang_ky'])
            ->each(function ($campaign) use (&$statusCounts) {
                $statusKey = $this->mapDisplayStatusFromCampaign($campaign);
                $statusCounts[$statusKey] = ($statusCounts[$statusKey] ?? 0) + 1;
            });

        $locations = [
            [
                'value' => 'TP.HCM',
                'count' => (clone $baseQuery)->where('dia_diem', 'like', '%TP.HCM%')->count(),
            ],
            [
                'value' => 'Hà Nội',
                'count' => (clone $baseQuery)->where('dia_diem', 'like', '%Hà Nội%')->count(),
            ],
            [
                'value' => 'Đà Nẵng',
                'count' => (clone $baseQuery)->where('dia_diem', 'like', '%Đà Nẵng%')->count(),
            ],
            [
                'value' => 'Khác',
                'count' => (clone $baseQuery)
                    ->where('dia_diem', 'not like', '%TP.HCM%')
                    ->where('dia_diem', 'not like', '%Hà Nội%')
                    ->where('dia_diem', 'not like', '%Đà Nẵng%')
                    ->count(),
            ],
        ];

        return response()->json([
            'status' => 1,
            'message' => 'Lấy bộ lọc chiến dịch thành công.',
            'data' => [
                'statuses' => [
                    ['value' => 'registering', 'count' => (int) ($statusCounts['registering'] ?? 0)],
                    ['value' => 'closed_registration', 'count' => (int) ($statusCounts['closed_registration'] ?? 0)],
                    ['value' => 'upcoming', 'count' => (int) ($statusCounts['upcoming'] ?? 0)],
                    ['value' => 'completed', 'count' => (int) ($statusCounts['completed'] ?? 0)],
                ],
                'categories' => $categories,
                'locations' => array_values(array_filter($locations, fn ($item) => $item['count'] > 0)),
                'creators' => $creators->map(fn ($item) => [
                    'value' => (string) $item->id,
                    'label' => $item->ho_ten,
                    'count' => (int) $item->total,
                ])->values(),
            ],
        ]);
    }

    public function danhSach(Request $request)
    {
        $user = auth('api')->user();

        $query = $this->buildPublicCampaignQuery();

        if ($request->filled('tu_khoa')) {
            $keyword = trim($request->tu_khoa);
            $query->where(function ($subQuery) use ($keyword) {
                $subQuery->where('tieu_de', 'like', "%{$keyword}%")
                    ->orWhere('mo_ta', 'like', "%{$keyword}%")
                    ->orWhere('dia_diem', 'like', "%{$keyword}%");
            });
        }

        if ($request->filled('loai_chien_dich_id')) {
            $query->where('loai_chien_dich_id', $request->integer('loai_chien_dich_id'));
        }

        if ($request->filled('loai_chien_dich_ids')) {
            $loaiIds = array_values(array_filter(
                array_map('intval', explode(',', (string) $request->loai_chien_dich_ids))
            ));

            if (!empty($loaiIds)) {
                $query->whereIn('loai_chien_dich_id', $loaiIds);
            }
        }

        if ($request->filled('muc_do_uu_tien')) {
            $query->where('muc_do_uu_tien', $request->muc_do_uu_tien);
        }

        if ($request->filled('trang_thai')) {
            $trangThais = array_filter(explode(',', $request->trang_thai));
            $hopLe = array_values(array_intersect($trangThais, ['registering', 'closed_registration', 'upcoming', 'completed']));
            if (!empty($hopLe)) {
                $query->where(function ($subQuery) use ($hopLe) {
                    if (in_array('registering', $hopLe, true)) {
                        $subQuery->orWhere(function ($innerQuery) {
                            $innerQuery->where('trang_thai', 'da_duyet')
                                ->where(function ($dateQuery) {
                                    $dateQuery->whereNull('han_dang_ky')
                                        ->orWhere('han_dang_ky', '>=', now());
                                });
                        });
                    }

                    if (in_array('closed_registration', $hopLe, true)) {
                        $subQuery->orWhere(function ($innerQuery) {
                            $innerQuery->where('trang_thai', 'da_duyet')
                                ->whereNotNull('han_dang_ky')
                                ->where('han_dang_ky', '<', now());
                        });
                    }

                    if (in_array('upcoming', $hopLe, true)) {
                        $subQuery->orWhere('trang_thai', 'dang_dien_ra');
                    }

                    if (in_array('completed', $hopLe, true)) {
                        $subQuery->orWhere('trang_thai', 'hoan_thanh');
                    }
                });
            }
        }

        if ($request->filled('dia_diem')) {
            $diaDiem = trim($request->dia_diem);
            if ($diaDiem === 'Khác') {
                $query->where(function ($subQuery) {
                    $subQuery->where('dia_diem', 'not like', '%TP.HCM%')
                        ->where('dia_diem', 'not like', '%Hà Nội%')
                        ->where('dia_diem', 'not like', '%Đà Nẵng%');
                });
            } else {
                $query->where('dia_diem', 'like', "%{$diaDiem}%");
            }
        }

        if ($request->filled('nguoi_tao_id')) {
            $query->where('nguoi_tao_id', $request->integer('nguoi_tao_id'));
        }

        $campaigns = $query->orderByDesc('tao_luc')->get();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy danh sách chiến dịch thành công.',
            'data' => $campaigns->map(fn ($campaign) => $this->mapCampaignSummary($campaign, $user))->values(),
        ]);
    }

    public function timKiem(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'limit' => 'nullable|integer|min:1|max:12',
        ]);

        $user = auth('api')->user();
        $keyword = trim($request->string('name')->value());
        $limit = $request->integer('limit') > 0 ? $request->integer('limit') : null;
        $likeKeyword = "%{$keyword}%";

        $query = $this->buildPublicCampaignQuery()
            ->where(function ($subQuery) use ($likeKeyword) {
                $subQuery->where('tieu_de', 'like', $likeKeyword)
                    ->orWhere('dia_diem', 'like', $likeKeyword)
                    ->orWhereHas('loaiChienDich', function ($loaiQuery) use ($likeKeyword) {
                        $loaiQuery->where('ten', 'like', $likeKeyword);
                    });
            })
            ->orderByRaw(
                'CASE
                    WHEN tieu_de LIKE ? THEN 0
                    WHEN dia_diem LIKE ? THEN 1
                    ELSE 2
                END',
                ["{$keyword}%", "{$keyword}%"]
            )
            ->orderByDesc('tao_luc');

        if ($limit) {
            $query->limit($limit);
        }

        $campaigns = $query->get();

        return response()->json([
            'status' => 1,
            'message' => 'Tìm kiếm chiến dịch thành công.',
            'data' => $campaigns->map(fn ($campaign) => $this->mapCampaignSummary($campaign, $user))->values(),
            'meta' => [
                'keyword' => $keyword,
                'total' => $campaigns->count(),
            ],
        ]);
    }

    public function chiTiet(Request $request, $id)
    {
        $user = auth('api')->user();

        $campaign = ChienDich::query()
            ->where('id', $id)
            ->whereNull('xoa_luc')
            ->whereIn('trang_thai', self::PUBLIC_STATUSES)
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email',
                'feedbacks.nguoiDung:id,ho_ten,email',
            ])
            ->first();

        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Lấy chi tiết chiến dịch thành công.',
            'data' => $this->mapCampaignDetail($campaign, $user),
        ]);
    }

    public function dangKy(Request $request, $id)
    {
        $user = auth('api')->user();
        $campaign = ChienDich::query()
            ->where('id', $id)
            ->whereNull('xoa_luc')
            ->first();

        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Chiến dịch không tồn tại.',
            ], 404);
        }

        if (!$this->coMoDangKy($campaign)) {
            return response()->json([
                'status' => 0,
                'message' => 'Chiến dịch không tồn tại hoặc không còn mở đăng ký.',
            ], 404);
        }

        if ($this->daDuSoLuongTinhNguyenVien($campaign)) {
            return response()->json([
                'status' => 0,
                'message' => 'Chiến dịch đã đủ số lượng tình nguyện viên.',
            ], 422);
        }

        if ((int) $campaign->nguoi_tao_id === (int) $user->id) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn không thể đăng ký tham gia chiến dịch do chính mình tạo.',
            ], 422);
        }

        $dangKyHienTai = DangKyThamGia::query()
            ->where('chien_dich_id', $campaign->id)
            ->where('nguoi_dung_id', $user->id)
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->first();

        if ($dangKyHienTai) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn đã đăng ký chiến dịch này rồi.',
            ], 422);
        }

        DB::transaction(function () use ($campaign, $user, &$dangKy) {
            $dangKy = DangKyThamGia::create([
                'chien_dich_id' => $campaign->id,
                'nguoi_dung_id' => $user->id,
                'trang_thai' => 'da_dang_ky',
                'dang_ky_luc' => now(),
            ]);

            $this->forgetParticipationReminderCache($dangKy->id);

            $campaign->update([
                'so_dang_ky' => $campaign->dangKyThamGias()->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])->count(),
                'so_xac_nhan' => $campaign->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
            ]);

            $this->taoThongBaoChoDangKy(
                $user->id,
                $user->id,
                'dang_ky_chien_dich',
                'Đăng ký chiến dịch thành công',
                "Bạn đã đăng ký chiến dịch \"{$campaign->tieu_de}\". Vui lòng xác nhận tham gia khi đã sẵn sàng.",
                $campaign->id
            );

            if ($campaign->nguoi_tao_id !== $user->id) {
                $this->taoThongBaoChoDangKy(
                    $campaign->nguoi_tao_id,
                    $user->id,
                    'tinh_nguyen_vien_dang_ky',
                    'Có tình nguyện viên mới đăng ký',
                    "{$user->ho_ten} vừa đăng ký tham gia chiến dịch \"{$campaign->tieu_de}\".",
                    $campaign->id
                );
            }
        });

        $this->guiMailCapNhatDangKy($user->email, 'xac_nhan_dang_ky', [
            'ho_ten' => $user->ho_ten,
            'ten_chien_dich' => $campaign->tieu_de,
            'dia_diem' => $campaign->dia_diem,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('d/m/Y'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('d/m/Y'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('d/m/Y'),
            'link_chien_dich' => $this->campaignDetailLink($campaign->id),
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Đăng ký tham gia thành công. Vui lòng kiểm tra email để xác nhận tham gia.',
            'data' => $this->mapDangKy($dangKy->fresh(), $campaign),
        ]);
    }

    public function huyDangKy(Request $request, $id)
    {
        $request->validate([
            'ly_do_huy' => 'nullable|string|max:500',
        ]);

        $user = auth('api')->user();
        $dangKy = DangKyThamGia::query()
            ->where('chien_dich_id', $id)
            ->where('nguoi_dung_id', $user->id)
            ->with('chienDich')
            ->first();

        if (!$dangKy || !$dangKy->chienDich || $dangKy->chienDich->xoa_luc) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy đăng ký tham gia.',
            ], 404);
        }

        $campaign = $dangKy->chienDich;

        if (!$this->coTheHuyDangKy($campaign, $dangKy)) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn không thể hủy đăng ký ở thời điểm hiện tại.',
            ], 422);
        }

        DB::transaction(function () use ($dangKy, $campaign, $user, $request) {
            $dangKy->update([
                'trang_thai' => 'da_huy',
                'huy_luc' => now(),
                'ly_do_huy' => $request->ly_do_huy,
            ]);

            $this->forgetParticipationReminderCache($dangKy->id);

            $campaign->update([
                'so_dang_ky' => $campaign->dangKyThamGias()->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])->count(),
                'so_xac_nhan' => $campaign->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
            ]);

            $this->taoThongBaoChoDangKy(
                $user->id,
                $user->id,
                'huy_dang_ky_chien_dich',
                'Đã hủy đăng ký tham gia',
                "Bạn đã hủy đăng ký tham gia chiến dịch \"{$campaign->tieu_de}\".",
                $campaign->id
            );

            if ($campaign->nguoi_tao_id !== $user->id) {
                $this->taoThongBaoChoDangKy(
                    $campaign->nguoi_tao_id,
                    $user->id,
                    'tinh_nguyen_vien_huy_dang_ky',
                    'Tình nguyện viên đã hủy đăng ký',
                    "{$user->ho_ten} đã hủy đăng ký tham gia chiến dịch \"{$campaign->tieu_de}\".",
                    $campaign->id
                );
            }
        });

        $this->guiMailCapNhatDangKy($user->email, 'huy_dang_ky', [
            'ho_ten' => $user->ho_ten,
            'ten_chien_dich' => $campaign->tieu_de,
            'dia_diem' => $campaign->dia_diem,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('d/m/Y'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('d/m/Y'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('d/m/Y'),
            'ly_do_huy' => $request->ly_do_huy,
            'link_chien_dich' => $this->campaignDetailLink($campaign->id),
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Hủy đăng ký tham gia thành công.',
        ]);
    }

    public function xacNhanThamGia($id)
    {
        $user = auth('api')->user();
        $dangKy = DangKyThamGia::query()
            ->where('chien_dich_id', $id)
            ->where('nguoi_dung_id', $user->id)
            ->with('chienDich')
            ->first();

        if (!$dangKy || !$dangKy->chienDich || $dangKy->chienDich->xoa_luc) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy đăng ký tham gia.',
            ], 404);
        }

        $campaign = $dangKy->chienDich;

        if (!$this->coTheXacNhanThamGia($campaign, $dangKy)) {
            return response()->json([
                'status' => 0,
                'message' => 'Bạn không thể xác nhận tham gia ở thời điểm hiện tại.',
            ], 422);
        }

        DB::transaction(function () use ($dangKy, $campaign, $user) {
            $dangKy->update([
                'trang_thai' => 'da_xac_nhan',
                'xac_nhan_luc' => now(),
            ]);

            $this->forgetParticipationReminderCache($dangKy->id);

            $campaign->update([
                'so_dang_ky' => $campaign->dangKyThamGias()->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])->count(),
                'so_xac_nhan' => $campaign->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
            ]);

            $this->taoThongBaoChoDangKy(
                $user->id,
                $user->id,
                'xac_nhan_tham_gia',
                'Xác nhận tham gia thành công',
                "Bạn đã xác nhận tham gia chiến dịch \"{$campaign->tieu_de}\".",
                $campaign->id
            );

            if ($campaign->nguoi_tao_id !== $user->id) {
                $this->taoThongBaoChoDangKy(
                    $campaign->nguoi_tao_id,
                    $user->id,
                    'tinh_nguyen_vien_xac_nhan',
                    'Tình nguyện viên đã xác nhận tham gia',
                    "{$user->ho_ten} đã xác nhận tham gia chiến dịch \"{$campaign->tieu_de}\".",
                    $campaign->id
                );
            }
        });

        $this->guiMailCapNhatDangKy($user->email, 'xac_nhan_tham_gia', [
            'ho_ten' => $user->ho_ten,
            'ten_chien_dich' => $campaign->tieu_de,
            'dia_diem' => $campaign->dia_diem,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('d/m/Y'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('d/m/Y'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('d/m/Y'),
            'link_chien_dich' => $this->campaignDetailLink($campaign->id),
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Xác nhận tham gia thành công.',
        ]);
    }

    private function findCampaignOpenForRegistration(int $campaignId): ?ChienDich
    {
        return ChienDich::query()
            ->where('id', $campaignId)
            ->whereNull('xoa_luc')
            ->where('trang_thai', 'da_duyet')
            ->first();
    }

    private function buildPublicCampaignQuery()
    {
        return ChienDich::query()
            ->whereNull('xoa_luc')
            ->whereIn('trang_thai', self::PUBLIC_STATUSES)
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'kyNangs:ky_nangs.id,ten',
                'nguoiTao:id,ho_ten,email',
                'duyetBoi:id,ho_ten,email',
            ]);
    }

    private function mapCampaignSummary(ChienDich $campaign, $user = null): array
    {
        $dangKy = $this->dangKyHienTai($campaign->id, $user?->id);
        $flags = $this->buildAvailabilityFlags($campaign, $dangKy);

        return [
            'id' => $campaign->id,
            'tieu_de' => $campaign->tieu_de,
            'mo_ta' => $campaign->mo_ta,
            'anh_bia' => $campaign->anh_bia,
            'dia_diem' => $campaign->dia_diem,
            'vi_do' => $campaign->vi_do,
            'kinh_do' => $campaign->kinh_do,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('Y-m-d'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('Y-m-d'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('Y-m-d'),
            'muc_do_uu_tien' => $campaign->muc_do_uu_tien,
            'trang_thai' => $campaign->trang_thai,
            'so_luong_toi_da' => $campaign->so_luong_toi_da,
            'so_dang_ky' => $campaign->so_dang_ky,
            'so_xac_nhan' => $campaign->so_xac_nhan,
            'loai_chien_dich' => $campaign->loaiChienDich,
            'ky_nangs' => $campaign->kyNangs->map(fn ($kyNang) => [
                'id' => $kyNang->id,
                'ten' => $kyNang->ten,
            ])->values(),
            'nguoi_tao' => $campaign->nguoiTao,
            'duyet_boi' => $campaign->duyetBoi,
            'dang_ky_hien_tai' => $dangKy ? $this->mapDangKy($dangKy, $campaign) : null,
            'co_the_dang_ky' => $flags['co_the_dang_ky'],
            'co_the_xac_nhan' => $flags['co_the_xac_nhan'],
            'co_the_huy_dang_ky' => $flags['co_the_huy_dang_ky'],
            'da_het_han_dang_ky' => $flags['da_het_han_dang_ky'],
            'da_du_so_luong' => $flags['da_du_so_luong'],
            'display_status' => $this->mapDisplayStatusFromCampaign($campaign),
        ];
    }

    private function mapCampaignDetail(ChienDich $campaign, $user = null): array
    {
        $dangKy = $this->dangKyHienTai($campaign->id, $user?->id);
        $flags = $this->buildAvailabilityFlags($campaign, $dangKy);

        return [
            'id' => $campaign->id,
            'tieu_de' => $campaign->tieu_de,
            'mo_ta' => $campaign->mo_ta,
            'anh_bia' => $campaign->anh_bia,
            'images' => $campaign->anh_bia ? [$campaign->anh_bia] : [],
            'dia_diem' => $campaign->dia_diem,
            'vi_do' => $campaign->vi_do,
            'kinh_do' => $campaign->kinh_do,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('Y-m-d'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('Y-m-d'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('Y-m-d'),
            'muc_do_uu_tien' => $campaign->muc_do_uu_tien,
            'trang_thai' => $campaign->trang_thai,
            'so_luong_toi_da' => $campaign->so_luong_toi_da,
            'so_dang_ky' => $campaign->so_dang_ky,
            'so_xac_nhan' => $campaign->so_xac_nhan,
            'loai_chien_dich' => $campaign->loaiChienDich,
            'ky_nangs' => $campaign->kyNangs->map(fn ($kyNang) => [
                'id' => $kyNang->id,
                'ten' => $kyNang->ten,
            ])->values(),
            'nguoi_tao' => $campaign->nguoiTao,
            'duyet_boi' => $campaign->duyetBoi,
            'feedbacks' => $campaign->feedbacks->map(function ($feedback) {
                return [
                    'id' => $feedback->id,
                    'noi_dung' => $feedback->nhan_xet,
                    'danh_gia_sao' => $feedback->so_sao,
                    'tao_luc' => optional($feedback->tao_luc)->format('Y-m-d H:i:s'),
                    'nguoi_dung' => $feedback->nguoiDung ? [
                        'id' => $feedback->nguoiDung->id,
                        'ho_ten' => $feedback->nguoiDung->ho_ten,
                        'email' => $feedback->nguoiDung->email,
                    ] : null,
                ];
            })->values(),
            'dang_ky_hien_tai' => $dangKy ? $this->mapDangKy($dangKy, $campaign) : null,
            'co_the_dang_ky' => $flags['co_the_dang_ky'],
            'co_the_xac_nhan' => $flags['co_the_xac_nhan'],
            'co_the_huy_dang_ky' => $flags['co_the_huy_dang_ky'],
            'da_het_han_dang_ky' => $flags['da_het_han_dang_ky'],
            'da_du_so_luong' => $flags['da_du_so_luong'],
            'display_status' => $this->mapDisplayStatusFromCampaign($campaign),
        ];
    }

    private function mapDisplayStatusFromCampaign(ChienDich $campaign): string
    {
        if ($campaign->trang_thai === 'hoan_thanh') {
            return 'completed';
        }

        if ($campaign->trang_thai === 'dang_dien_ra') {
            return 'upcoming';
        }

        if ($campaign->trang_thai === 'da_duyet') {
            $daHetHanDangKy = $campaign->han_dang_ky && now()->gt($campaign->han_dang_ky);
            return $daHetHanDangKy ? 'closed_registration' : 'registering';
        }

        return 'registering';
    }

    private function dangKyHienTai(int $campaignId, ?int $userId): ?DangKyThamGia
    {
        if (!$userId) {
            return null;
        }

        return DangKyThamGia::query()
            ->where('chien_dich_id', $campaignId)
            ->where('nguoi_dung_id', $userId)
            ->latest('id')
            ->first();
    }

    private function buildAvailabilityFlags(ChienDich $campaign, ?DangKyThamGia $dangKy): array
    {
        $daHetHanDangKy = $campaign->han_dang_ky && now()->gt($campaign->han_dang_ky);
        $dangMoDangKy = $campaign->trang_thai === 'da_duyet' && !$daHetHanDangKy;
        $daDuSoLuong = $this->daDuSoLuongTinhNguyenVien($campaign);

        return [
            'co_the_dang_ky' => $dangMoDangKy && !$daDuSoLuong && !$dangKy,
            'co_the_xac_nhan' => $dangKy && $dangMoDangKy && $dangKy->trang_thai === 'da_dang_ky',
            'co_the_huy_dang_ky' => $dangKy && $this->coTheHuyDangKy($campaign, $dangKy),
            'da_het_han_dang_ky' => $daHetHanDangKy,
            'da_du_so_luong' => $daDuSoLuong,
        ];
    }

    private function coMoDangKy(ChienDich $campaign): bool
    {
        $daHetHanDangKy = $campaign->han_dang_ky && now()->gt($campaign->han_dang_ky);

        return $campaign->trang_thai === 'da_duyet' && !$daHetHanDangKy;
    }

    private function daDuSoLuongTinhNguyenVien(ChienDich $campaign): bool
    {
        if (!$campaign->so_luong_toi_da) {
            return false;
        }

        return (int) $campaign->so_xac_nhan >= (int) $campaign->so_luong_toi_da;
    }

    private function coTheHuyDangKy(ChienDich $campaign, DangKyThamGia $dangKy): bool
    {
        if (in_array($campaign->trang_thai, ['dang_dien_ra', 'hoan_thanh'], true)) {
            return false;
        }

        return in_array($dangKy->trang_thai, ['da_dang_ky', 'da_duyet', 'da_xac_nhan'], true);
    }

    private function coTheXacNhanThamGia(ChienDich $campaign, DangKyThamGia $dangKy): bool
    {
        return $campaign->trang_thai === 'da_duyet' && $dangKy->trang_thai === 'da_dang_ky';
    }

    private function mapDangKy(DangKyThamGia $dangKy, ?ChienDich $campaign = null): array
    {
        return [
            'id' => $dangKy->id,
            'chien_dich_id' => $dangKy->chien_dich_id,
            'nguoi_dung_id' => $dangKy->nguoi_dung_id,
            'trang_thai' => $dangKy->trang_thai,
            'dang_ky_luc' => optional($dangKy->dang_ky_luc)->format('Y-m-d H:i:s'),
            'xac_nhan_luc' => optional($dangKy->xac_nhan_luc)->format('Y-m-d H:i:s'),
            'huy_luc' => optional($dangKy->huy_luc)->format('Y-m-d H:i:s'),
            'ly_do_huy' => $dangKy->ly_do_huy,
            'campaign_status' => $campaign?->trang_thai,
        ];
    }

    private function taoThongBaoChoDangKy(int $nguoiDungId, int $nguoiGuiId, string $loai, string $tieuDe, string $noiDung, int $campaignId): void
    {
        $loaiThongBao = match ($loai) {
            'dang_ky_chien_dich',
            'tinh_nguyen_vien_dang_ky',
            'huy_dang_ky_chien_dich',
            'tinh_nguyen_vien_huy_dang_ky',
            'xac_nhan_tham_gia',
            'tinh_nguyen_vien_xac_nhan' => 'cap_nhat_cd',
            default => 'he_thong',
        };

        ThongBao::create([
            'nguoi_dung_id' => $nguoiDungId,
            'nguoi_gui_id' => $nguoiGuiId,
            'loai' => $loaiThongBao,
            'tieu_de' => $tieuDe,
            'noi_dung' => $noiDung,
            'loai_tham_chieu' => 'chien_dich',
            'tham_chieu_id' => $campaignId,
            'gui_qua' => 'ca_hai',
        ]);
    }

    private function guiMailCapNhatDangKy(string $email, string $loai, array $data): void
    {
        $titles = [
            'xac_nhan_dang_ky' => 'Xác nhận đăng ký chiến dịch',
            'xac_nhan_tham_gia' => 'Xác nhận tham gia chiến dịch thành công',
            'huy_dang_ky' => 'Hủy đăng ký chiến dịch thành công',
        ];

        SendMailJob::dispatch(
            $email,
            $titles[$loai] ?? 'Cập nhật đăng ký chiến dịch',
            'cap_nhat_dang_ky_chien_dich',
            array_merge($data, ['loai' => $loai])
        );
    }

    private function campaignDetailLink(int $campaignId): string
    {
        return rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . "/chi-tiet-chien-dich/{$campaignId}";
    }

    private function forgetParticipationReminderCache(int $dangKyId): void
    {
        Cache::forget("campaigns:participation-reminder-sent:{$dangKyId}");
    }
}

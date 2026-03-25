<?php

namespace App\Http\Controllers;

use App\Jobs\SendMailJob;
use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\NguoiDung;
use App\Services\RecommendationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecommendationController extends Controller
{
    public function __construct(
        private readonly RecommendationService $recommendationService,
    ) {
    }

    public function goiY(Request $request)
    {
        $type = $request->input('type');

        if ($type === 'chien_dich') {
            return $this->buildCampaignRecommendationResponse($request);
        }

        if ($type === 'tinh_nguyen_vien') {
            return $this->buildVolunteerRecommendationResponse($request);
        }

        return response()->json([
            'status' => 0,
            'message' => 'Loại gợi ý không hợp lệ. Vui lòng dùng type=chien_dich hoặc type=tinh_nguyen_vien.',
        ], 422);
    }

    private function buildCampaignRecommendationResponse(Request $request)
    {
        $user = auth('api')->user();
        $profileGaps = [];

        if ($user->kyNangs()->count() === 0) {
            $profileGaps[] = 'Thiếu kỹ năng';
        }

        if ($user->lichRanhs()->count() === 0) {
            $profileGaps[] = 'Thiếu lịch rảnh';
        }

        if (!$user->vi_do || !$user->kinh_do) {
            $profileGaps[] = 'Thiếu vị trí hiện tại';
        }

        $recommendations = $this->recommendationService->recommendCampaignsForVolunteer(
            $user,
            max(1, min((int) $request->input('limit', 6), 30)),
            [
                'nearby_only' => filter_var($request->input('nearby_only', false), FILTER_VALIDATE_BOOLEAN),
                'priority' => $request->input('priority'),
            ]
        );

        return response()->json([
            'status' => 1,
            'message' => 'Lấy danh sách chiến dịch đề xuất thành công.',
            'data' => $recommendations,
            'meta' => [
                'profile_gaps' => $profileGaps,
                'applied_filters' => [
                    'nearby_only' => filter_var($request->input('nearby_only', false), FILTER_VALIDATE_BOOLEAN),
                    'priority' => $request->input('priority'),
                ],
            ],
        ]);
    }

    private function buildVolunteerRecommendationResponse(Request $request)
    {
        $user = auth('api')->user();
        $mode = $request->input('mode', 'list');
        $campaignId = (int) $request->input('campaign_id');
        $campaign = ChienDich::query()
            ->where('id', $campaignId)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->first();

        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $result = $this->recommendationService->recommendVolunteersForCampaign(
            $user,
            $campaign,
            max(1, min((int) $request->input('limit', 30), 50)),
            filter_var($request->input('only_available', true), FILTER_VALIDATE_BOOLEAN)
        );

        $payload = [
            'de_xuat_uu_tien' => array_values(array_filter($result['recommendations'], fn ($item) => $item['match_level'] === 'rat_phu_hop')),
            'du_phong_phu_hop' => array_values(array_filter($result['recommendations'], fn ($item) => $item['match_level'] === 'phu_hop')),
            'can_nhac_them' => array_values(array_filter($result['recommendations'], fn ($item) => $item['match_level'] === 'can_nhac')),
            'all' => $result['recommendations'],
            'excluded' => $result['excluded'],
        ];

        if ($mode === 'allocation') {
            $allocation = $this->recommendationService->buildAllocationSuggestion($user, $campaign);
            $payload = array_merge($payload, [
                'recommended_primary' => $allocation['recommended_primary'],
                'recommended_backup' => $allocation['recommended_backup'],
                'resource_summary' => $allocation['resource_summary'],
                'risk_flags' => $allocation['risk_flags'],
            ]);
        }

        return response()->json([
            'status' => 1,
            'message' => $mode === 'allocation'
                ? 'Lấy dữ liệu điều phối tình nguyện viên thành công.'
                : 'Lấy danh sách tình nguyện viên đề xuất thành công.',
            'data' => $payload,
        ]);
    }

    public function moiTinhNguyenVien(Request $request, int $id)
    {
        $request->validate([
            'volunteer_ids' => 'required|array|min:1',
            'volunteer_ids.*' => 'integer|exists:nguoi_dungs,id',
        ]);

        $user = auth('api')->user();
        $campaign = ChienDich::query()
            ->where('id', $id)
            ->where('nguoi_tao_id', $user->id)
            ->whereNull('xoa_luc')
            ->first();

        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $volunteerIds = collect($request->volunteer_ids)
            ->map(fn ($idItem) => (int) $idItem)
            ->unique()
            ->values();

        $volunteers = NguoiDung::query()
            ->whereIn('id', $volunteerIds)
            ->where('vai_tro', 'tinh_nguyen_vien')
            ->whereNull('xoa_luc')
            ->get()
            ->keyBy('id');

        $invitedCount = 0;
        $skippedCount = 0;

        DB::transaction(function () use ($campaign, $user, $volunteerIds, $volunteers, &$invitedCount, &$skippedCount) {
            foreach ($volunteerIds as $volunteerId) {
                $volunteer = $volunteers->get($volunteerId);
                if (!$volunteer) {
                    $skippedCount++;
                    continue;
                }

                $dangKy = DangKyThamGia::query()->firstOrNew([
                    'chien_dich_id' => $campaign->id,
                    'nguoi_dung_id' => $volunteerId,
                ]);

                if ($dangKy->exists && in_array($dangKy->trang_thai, ['da_dang_ky', 'da_duyet', 'da_xac_nhan'], true)) {
                    $skippedCount++;
                    continue;
                }

                $dangKy->fill([
                    'trang_thai' => 'da_dang_ky',
                    'dang_ky_luc' => $dangKy->dang_ky_luc ?: now(),
                    'duyet_luc' => null,
                    'xac_nhan_luc' => null,
                    'huy_luc' => null,
                    'ly_do_huy' => null,
                    'ghi_chu' => 'Được mời từ màn điều phối nhân sự.',
                ]);
                $dangKy->save();

                if (!empty($volunteer->email)) {
                    SendMailJob::dispatch(
                        $volunteer->email,
                        'Thư mời xác nhận tham gia chiến dịch',
                        'cap_nhat_dang_ky_chien_dich',
                        $this->buildInviteEmailData($campaign, $volunteer, $user)
                    );
                }

                $invitedCount++;
            }

            $campaign->update([
                'so_dang_ky' => $campaign->dangKyThamGias()->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])->count(),
                'so_xac_nhan' => $campaign->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
            ]);
        });

        $message = $invitedCount > 0
            ? "Đã gửi email mời xác nhận tham gia cho {$invitedCount} tình nguyện viên."
            : 'Không có tình nguyện viên nào được gửi lời mời mới.';

        if ($skippedCount > 0) {
            $message .= " {$skippedCount} người đã có trạng thái đăng ký phù hợp nên được bỏ qua.";
        }

        return response()->json([
            'status' => 1,
            'message' => $message,
            'data' => [
                'invited_count' => $invitedCount,
                'skipped_count' => $skippedCount,
            ],
        ]);
    }

    private function buildInviteEmailData(ChienDich $campaign, NguoiDung $volunteer, NguoiDung $inviter): array
    {
        return [
            'loai' => 'loi_moi_tham_gia',
            'ho_ten' => $volunteer->ho_ten,
            'ten_chien_dich' => $campaign->tieu_de,
            'dia_diem' => $campaign->dia_diem,
            'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('d/m/Y'),
            'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('d/m/Y'),
            'han_dang_ky' => optional($campaign->han_dang_ky)->format('d/m/Y'),
            'link_chien_dich' => rtrim(config('app.frontend_url', 'http://localhost:5173'), '/') . "/chi-tiet-chien-dich/{$campaign->id}",
            'nguoi_moi' => $inviter->ho_ten,
        ];
    }
}

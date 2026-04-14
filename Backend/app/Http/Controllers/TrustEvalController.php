<?php

namespace App\Http\Controllers;

use App\Models\CampaignEvaluation;
use App\Models\ChienDich;
use App\Services\TrustScoreService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrustEvalController extends Controller
{
    public function __construct(
        private readonly TrustScoreService $trustScoreService,
    ) {
    }

    public function getCampaignEvaluation(int $id): JsonResponse
    {
        $campaign = ChienDich::find($id);
        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $evaluation = $this->trustScoreService->getEvaluation($id);

        if ($evaluation === null) {
            return response()->json([
                'status' => 0,
                'message' => 'Chiến dịch chưa được đánh giá.',
                'campaign_id' => $id,
            ], 404);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Lấy kết quả đánh giá thành công.',
            'data' => $evaluation,
        ]);
    }

    public function refreshCampaignEvaluation(int $id): JsonResponse
    {
        $campaign = ChienDich::find($id);
        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $result = $this->trustScoreService->refreshEvaluation($id);

        if (!($result['success'] ?? true)) {
            return response()->json([
                'status' => 0,
                'message' => $result['error'] ?? 'Lỗi khi refresh đánh giá.',
                'campaign_id' => $id,
            ], 500);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Đánh giá đã được làm mới thành công.',
            'data' => $result,
        ]);
    }

    public function getVolunteerEvaluation(int $id): JsonResponse
    {
        $result = $this->trustScoreService->evaluateVolunteer($id);

        if (!($result['success'] ?? true)) {
            return response()->json([
                'status' => 0,
                'message' => $result['error'] ?? 'Không tìm thấy tình nguyện viên.',
                'volunteer_id' => $id,
            ], 404);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Lấy kết quả đánh giá thành công.',
            'data' => $result,
        ]);
    }

    public function getPendingEvaluations(Request $request): JsonResponse
    {
        $evaluatedCampaignIds = CampaignEvaluation::query()
            ->whereNotNull('trust_score_calibrated')
            ->distinct()
            ->pluck('chien_dich_id');

        $pendingQuery = ChienDich::query()
            ->where('trang_thai', 'cho_duyet')
            ->whereNull('xoa_luc')
            ->whereNotIn('id', $evaluatedCampaignIds)
            ->with([
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'nguoiTao:id,ho_ten,email',
            ]);

        $totalPending = (clone $pendingQuery)->count();

        $perPage = $request->integer('per_page', 20);
        $campaigns = $pendingQuery
            ->orderByDesc('tao_luc')
            ->paginate($perPage);

        return response()->json([
            'status' => 1,
            'message' => 'Lấy danh sách chiến dịch chưa đánh giá thành công.',
            'data' => $campaigns->map(fn ($cd) => [
                'id' => $cd->id,
                'tieu_de' => $cd->tieu_de,
                'dia_diem' => $cd->dia_diem,
                'ngay_bat_dau' => $cd->ngay_bat_dau?->format('Y-m-d'),
                'ngay_ket_thuc' => $cd->ngay_ket_thuc?->format('Y-m-d'),
                'muc_do_uu_tien' => $cd->muc_do_uu_tien,
                'trang_thai' => $cd->trang_thai,
                'loai_chien_dich' => $cd->loaiChienDich,
                'nguoi_tao' => $cd->nguoiTao,
                'tao_luc' => $cd->tao_luc?->format('Y-m-d H:i:s'),
            ])->values(),
            'total' => $totalPending,
            'page' => $campaigns->currentPage(),
            'per_page' => $campaigns->perPage(),
            'last_page' => $campaigns->lastPage(),
        ]);
    }

    public function getStatistics(): JsonResponse
    {
        $stats = $this->trustScoreService->getStatistics();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy thống kê đánh giá thành công.',
            'data' => $stats,
        ]);
    }

    public function getMlServiceHealth(): JsonResponse
    {
        $health = $this->trustScoreService->getMlServiceHealth();

        return response()->json([
            'status' => 1,
            'message' => 'Lấy trạng thái ML service thành công.',
            'data' => $health,
        ]);
    }
}

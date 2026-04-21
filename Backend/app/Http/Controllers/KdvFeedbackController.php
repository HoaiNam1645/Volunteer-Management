<?php

namespace App\Http\Controllers;

use App\Models\CampaignEvaluation;
use App\Models\EvaluationTrainingLabel;
use App\Models\KdvFeedback;
use App\Models\ChienDich;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KdvFeedbackController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'chien_dich_id' => 'required|integer|exists:chien_dichs,id',
            'feedback_type' => 'required|string|in:override,agree,disagree,correct_action',
            'ml_action_correct' => 'nullable|integer|in:0,1',
            'final_trust_label_override' => 'nullable|integer|in:0,1',
            'kdv_notes' => 'nullable|string|max:2000',
            'overridden_fields' => 'nullable|array',
        ]);

        $campaign = ChienDich::find($validated['chien_dich_id']);
        if (!$campaign) {
            return response()->json([
                'status' => 0,
                'message' => 'Không tìm thấy chiến dịch.',
            ], 404);
        }

        $user = $request->user();
        if (!$user) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized.',
            ], 401);
        }

        $feedback = DB::transaction(function () use ($validated, $user, $campaign) {
            $feedback = KdvFeedback::create([
                'chien_dich_id' => $validated['chien_dich_id'],
                'nguoi_dung_id' => $user->id,
                'feedback_type' => $validated['feedback_type'],
                'ml_action_correct' => $validated['ml_action_correct'] ?? null,
                'final_trust_label_override' => $validated['final_trust_label_override'] ?? null,
                'kdv_notes' => $validated['kdv_notes'] ?? null,
                'overridden_fields' => $validated['overridden_fields'] ?? null,
                'feedback_at' => now(),
            ]);

            if ($feedback->feedback_type === KdvFeedback::TYPE_OVERRIDE && isset($validated['final_trust_label_override'])) {
                $evaluation = CampaignEvaluation::where('chien_dich_id', $campaign->id)
                    ->latest('evaluated_at')
                    ->first();

                if ($evaluation) {
                    $mlAction = $evaluation->recommended_action;
                    $kdvAction = $campaign->trang_thai;

                    $mlAgreement = ($kdvAction === 'da_duyet' && in_array($mlAction, ['APPROVE', 'APPROVE_WITH_NOTE']))
                        || ($kdvAction === 'tu_choi' && in_array($mlAction, ['REJECT', 'REQUEST_ADDITIONAL_INFO']));

                    $evaluation->update([
                        'kdv_final_action' => $kdvAction,
                        'kdv_final_trust_label' => $validated['final_trust_label_override'] ? 'RELIABLE' : 'SUSPICIOUS',
                        'kdv_id' => $user->id,
                        'kdv_decided_at' => now(),
                        'ml_agreement' => $mlAgreement,
                    ]);

                    $this->storeTrainingLabel(
                        $evaluation,
                        $campaign,
                        $user->id,
                        $validated,
                        $mlAgreement
                    );
                }
            } elseif ($validated['ml_action_correct'] !== null) {
                $evaluation = CampaignEvaluation::where('chien_dich_id', $campaign->id)
                    ->latest('evaluated_at')
                    ->first();

                if ($evaluation) {
                    $mlAction = $evaluation->recommended_action;
                    $kdvAction = $campaign->trang_thai;

                    $mlAgreement = ($validated['ml_action_correct'] === 1 && (
                        ($kdvAction === 'da_duyet' && in_array($mlAction, ['APPROVE', 'APPROVE_WITH_NOTE']))
                        || ($kdvAction === 'tu_choi' && in_array($mlAction, ['REJECT', 'REQUEST_ADDITIONAL_INFO']))
                    )) || ($validated['ml_action_correct'] === 0 && (
                        ($kdvAction === 'da_duyet' && $mlAction === 'REJECT')
                        || ($kdvAction === 'tu_choi' && $mlAction === 'APPROVE')
                    ));

                    $evaluation->update([
                        'kdv_final_action' => $kdvAction,
                        'kdv_id' => $user->id,
                        'kdv_decided_at' => now(),
                        'ml_agreement' => $mlAgreement,
                    ]);

                    $this->storeTrainingLabel(
                        $evaluation,
                        $campaign,
                        $user->id,
                        $validated,
                        $mlAgreement
                    );
                }
            }

            return $feedback;
        });

        return response()->json([
            'status' => 1,
            'message' => 'Feedback đã được ghi nhận.',
            'data' => $feedback,
        ], 201);
    }

    public function index(Request $request): JsonResponse
    {
        $perPage = $request->integer('per_page', 20);
        $feedbackType = $request->input('feedback_type');

        $query = KdvFeedback::with(['chienDich:id,tieu_de,trang_thai', 'nguoiDung:id,ho_ten'])
            ->orderByDesc('feedback_at');

        if ($feedbackType) {
            $query->where('feedback_type', $feedbackType);
        }

        $total = (clone $query)->count();
        $items = $query->paginate($perPage);

        return response()->json([
            'status' => 1,
            'data' => $items->items(),
            'total' => $total,
            'page' => $items->currentPage(),
            'per_page' => $items->perPage(),
            'last_page' => $items->lastPage(),
        ]);
    }

    public function getAgreementStats(): JsonResponse
    {
        $totalDecided = CampaignEvaluation::whereNotNull('ml_agreement')->count();

        if ($totalDecided === 0) {
            return response()->json([
                'status' => 1,
                'data' => [
                    'total_decided' => 0,
                    'ml_agreement_rate' => null,
                    'agreement_count' => 0,
                    'disagreement_count' => 0,
                    'by_action' => [],
                ],
            ]);
        }

        $agreementCount = CampaignEvaluation::where('ml_agreement', true)->count();
        $agreementRate = $agreementCount / $totalDecided;

        $byAction = CampaignEvaluation::query()
            ->selectRaw('recommended_action, ml_agreement, COUNT(*) as count')
            ->whereNotNull('ml_agreement')
            ->groupBy('recommended_action', 'ml_agreement')
            ->get()
            ->groupBy('recommended_action')
            ->map(fn ($group) => [
                'total' => $group->sum('count'),
                'agreed' => $group->where('ml_agreement', true)->sum('count'),
                'disagreed' => $group->where('ml_agreement', false)->sum('count'),
            ]);

        return response()->json([
            'status' => 1,
            'data' => [
                'total_decided' => $totalDecided,
                'ml_agreement_rate' => round($agreementRate, 4),
                'agreement_count' => $agreementCount,
                'disagreement_count' => $totalDecided - $agreementCount,
                'by_action' => $byAction,
            ],
        ]);
    }

    private function storeTrainingLabel(
        CampaignEvaluation $evaluation,
        ChienDich $campaign,
        int $kdvId,
        array $validated,
        bool $mlAgreement
    ): void {
        EvaluationTrainingLabel::create([
            'chien_dich_id' => $campaign->id,
            'evaluation_id' => $evaluation->id,
            'kdv_id' => $kdvId,
            'kdv_action' => $this->mapCampaignDecisionToTrainingAction(
                $campaign->trang_thai,
                $evaluation->recommended_action,
                $validated['ml_action_correct'] ?? null
            ),
            'kdv_reason' => $validated['kdv_notes'] ?? null,
            'ml_trust_score' => $evaluation->trust_score_calibrated,
            'ml_risk_level' => $evaluation->risk_level,
            'ml_recommended_action' => $evaluation->recommended_action,
            'ml_agree_with_kdv' => $mlAgreement,
            'kdv_satisfied_with_ml' => array_key_exists('ml_action_correct', $validated)
                ? ((int) $validated['ml_action_correct']) === 1
                : $mlAgreement,
            'kdv_overridden_ml' => $validated['feedback_type'] === KdvFeedback::TYPE_OVERRIDE || !$mlAgreement,
        ]);
    }

    private function mapCampaignDecisionToTrainingAction(
        ?string $campaignStatus,
        ?string $mlAction,
        ?int $mlActionCorrect
    ): string {
        if ($campaignStatus === 'tu_choi') {
            return 'reject';
        }

        if ($mlActionCorrect === 1) {
            return match ($mlAction) {
                'APPROVE_WITH_NOTE' => 'approve_with_note',
                'REQUEST_ADDITIONAL_INFO' => 'request_info',
                'REJECT' => 'reject',
                default => 'approve',
            };
        }

        return 'approve';
    }
}

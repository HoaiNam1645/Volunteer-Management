<?php

namespace App\Services;

use App\Models\BaoCaoChienDich;
use App\Models\CampaignEvaluation;
use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\DanhGiaTnv;
use App\Models\NguoiDung;
use App\Models\VolunteerEvaluation;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TrustScoreService
{
    private string $mlServiceUrl;
    private int $cacheTtlSeconds;
    private int $volunteerCacheTtlSeconds;
    private int $httpTimeout;
    private bool $fallbackEnabled;
    private bool $mlServiceEnabled;
    private ?string $mlInternalKey;

    public function __construct()
    {
        $this->mlServiceUrl = config('services.ml_trust.url', 'http://127.0.0.1:8001');
        $this->cacheTtlSeconds = (int) config('services.ml_trust.cache_ttl', 3600);
        $this->volunteerCacheTtlSeconds = (int) config('services.ml_trust.volunteer_cache_ttl', 21600);
        $this->httpTimeout = (int) config('services.ml_trust.timeout', 10);
        $this->fallbackEnabled = (bool) config('services.ml_trust.fallback_enabled', true);
        $this->mlServiceEnabled = (bool) config('services.ml_trust.enabled', true);
        $this->mlInternalKey = config('services.ml_trust.internal_key');
    }

    public function evaluateCampaign(int $campaignId): array
    {
        $cacheKey = "campaign_evaluation:{$campaignId}";

        $cached = Cache::get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        $campaign = ChienDich::with('nguoiTao')->find($campaignId);
        if (!$campaign) {
            return [
                'success' => false,
                'error' => 'Campaign not found',
                'campaign_id' => $campaignId,
            ];
        }

        $result = $this->doEvaluateCampaign($campaign);

        Cache::put($cacheKey, $result, $this->cacheTtlSeconds);

        return $result;
    }

    public function getEvaluation(int $campaignId): ?array
    {
        $cacheKey = "campaign_evaluation:{$campaignId}";
        $cached = Cache::get($cacheKey);

        if ($cached !== null) {
            return $cached;
        }

        $evaluation = CampaignEvaluation::where('chien_dich_id', $campaignId)
            ->latest('evaluated_at')
            ->first();

        if (!$evaluation) {
            return null;
        }

        $result = $this->formatEvaluationForApi($evaluation);

        Cache::put($cacheKey, $result, $this->cacheTtlSeconds);

        return $result;
    }

    public function refreshEvaluation(int $campaignId): array
    {
        $this->invalidateCampaignCache($campaignId);

        $campaign = ChienDich::with('nguoiTao')->find($campaignId);
        if (!$campaign) {
            return [
                'success' => false,
                'error' => 'Campaign not found',
                'campaign_id' => $campaignId,
            ];
        }

        $result = $this->doEvaluateCampaign($campaign);

        Cache::put("campaign_evaluation:{$campaignId}", $result, $this->cacheTtlSeconds);

        return $result;
    }

    public function evaluateVolunteer(int $volunteerId): array
    {
        $cacheKey = "volunteer_evaluation:{$volunteerId}";

        $cached = Cache::get($cacheKey);
        if ($cached !== null) {
            return $cached;
        }

        $volunteer = NguoiDung::with([
            'dangKyThamGias',
            'chungChis',
            'kinhNghiems',
            'phanHoiTnvs',
        ])->find($volunteerId);

        if (!$volunteer) {
            return [
                'success' => false,
                'error' => 'Volunteer not found',
                'volunteer_id' => $volunteerId,
            ];
        }

        $result = $this->doEvaluateVolunteer($volunteer);

        Cache::put($cacheKey, $result, $this->volunteerCacheTtlSeconds);

        return $result;
    }

    public function invalidateCampaignCache(int $campaignId): void
    {
        Cache::forget("campaign_evaluation:{$campaignId}");
    }

    public function invalidateVolunteerCache(int $volunteerId): void
    {
        Cache::forget("volunteer_evaluation:{$volunteerId}");
    }

    public function invalidateCampaignCreatorCache(int $creatorId): void
    {
        $campaignIds = ChienDich::where('nguoi_tao_id', $creatorId)->pluck('id');

        foreach ($campaignIds as $id) {
            $this->invalidateCampaignCache($id);
        }
    }

    public function getMlServiceHealth(): array
    {
        try {
            $response = Http::timeout(5)->get("{$this->mlServiceUrl}/health");

            if ($response->successful()) {
                return [
                    'healthy' => true,
                    'data' => $response->json(),
                ];
            }

            return [
                'healthy' => false,
                'status' => $response->status(),
                'error' => 'ML service returned error',
            ];
        } catch (\Exception $e) {
            return [
                'healthy' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    public function getStatistics(): array
    {
        $total = CampaignEvaluation::count();
        $byRiskLevel = CampaignEvaluation::query()
            ->selectRaw('risk_level, COUNT(*) as count')
            ->whereNotNull('risk_level')
            ->groupBy('risk_level')
            ->pluck('count', 'risk_level')
            ->toArray();

        $byTrustLabel = CampaignEvaluation::query()
            ->selectRaw('trust_label, COUNT(*) as count')
            ->whereNotNull('trust_label')
            ->groupBy('trust_label')
            ->pluck('count', 'trust_label')
            ->toArray();

        $byAction = CampaignEvaluation::query()
            ->selectRaw('recommended_action, COUNT(*) as count')
            ->whereNotNull('recommended_action')
            ->groupBy('recommended_action')
            ->pluck('count', 'recommended_action')
            ->toArray();

        $avgTrustScore = CampaignEvaluation::whereNotNull('trust_score_calibrated')
            ->avg('trust_score_calibrated');

        $avgRiskScore = CampaignEvaluation::whereNotNull('risk_score')
            ->avg('risk_score');

        $sourceStats = CampaignEvaluation::query()
            ->selectRaw('evaluation_source, COUNT(*) as count')
            ->groupBy('evaluation_source')
            ->pluck('count', 'evaluation_source')
            ->toArray();

        $recentEvals = CampaignEvaluation::query()
            ->with('chienDich:id,tieu_de,trang_thai')
            ->whereIn('risk_level', ['HIGH', 'CRITICAL'])
            ->orWhere('is_anomaly', true)
            ->orderByDesc('evaluated_at')
            ->limit(10)
            ->get()
            ->map(fn ($eval) => [
                'campaign_id' => $eval->chien_dich_id,
                'tieu_de' => $eval->chienDich?->tieu_de,
                'risk_level' => $eval->risk_level,
                'trust_score' => (float) $eval->trust_score_calibrated,
                'is_anomaly' => $eval->is_anomaly,
                'evaluated_at' => $eval->evaluated_at?->toIso8601String(),
            ]);

        return [
            'total_evaluations' => $total,
            'avg_trust_score' => $avgTrustScore ? round((float) $avgTrustScore, 4) : null,
            'avg_risk_score' => $avgRiskScore ? round((float) $avgRiskScore, 4) : null,
            'by_risk_level' => $byRiskLevel,
            'by_trust_label' => $byTrustLabel,
            'by_recommended_action' => $byAction,
            'by_evaluation_source' => $sourceStats,
            'recent_high_risk' => $recentEvals,
        ];
    }

    // ==================== PRIVATE METHODS ====================

    private function doEvaluateCampaign(ChienDich $campaign): array
    {
        $creator = $campaign->nguoiTao;

        if ($this->mlServiceEnabled) {
            try {
                $response = $this->mlHttpClient()
                    ->post("{$this->mlServiceUrl}/api/v1/evaluate/campaign/{$campaign->id}");

                if ($response->successful()) {
                    $mlResult = $response->json();
                    $mlResult['evaluation_source'] = 'ml_service';

                    $this->persistEvaluation($campaign->id, $mlResult);

                    return $mlResult;
                }

                Log::warning('ML service returned error for campaign', [
                    'campaign_id' => $campaign->id,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            } catch (\Exception $e) {
                Log::error('ML service unavailable for campaign', [
                    'campaign_id' => $campaign->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if (!$this->fallbackEnabled) {
            return [
                'success' => false,
                'error' => 'ML service unavailable and fallback is disabled',
                'campaign_id' => $campaign->id,
            ];
        }

        Log::info('Using fallback rule-based evaluation for campaign', [
            'campaign_id' => $campaign->id,
        ]);

        $fallbackResult = $this->fallbackRuleBasedEvaluation($campaign);
        $fallbackResult['evaluation_source'] = 'fallback';

        $this->persistEvaluation($campaign->id, $fallbackResult);

        return $fallbackResult;
    }

    private function doEvaluateVolunteer(NguoiDung $volunteer): array
    {
        if ($this->mlServiceEnabled) {
            try {
                $response = $this->mlHttpClient()
                    ->post("{$this->mlServiceUrl}/api/v1/evaluate/volunteer/{$volunteer->id}");

                if ($response->successful()) {
                    $mlResult = $response->json();
                    $mlResult['evaluation_source'] = 'ml_service';

                    $this->persistVolunteerEvaluation($volunteer->id, $mlResult);

                    return $mlResult;
                }
            } catch (\Exception $e) {
                Log::error('ML service unavailable for volunteer', [
                    'volunteer_id' => $volunteer->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        if (!$this->fallbackEnabled) {
            return [
                'success' => false,
                'error' => 'ML service unavailable and fallback is disabled',
                'volunteer_id' => $volunteer->id,
            ];
        }

        $fallbackResult = $this->fallbackVolunteerEvaluation($volunteer);
        $fallbackResult['evaluation_source'] = 'fallback';

        $this->persistVolunteerEvaluation($volunteer->id, $fallbackResult);

        return $fallbackResult;
    }

    private function mlHttpClient()
    {
        $client = Http::timeout($this->httpTimeout)
            ->acceptJson();

        if (!empty($this->mlInternalKey)) {
            $client = $client->withHeaders([
                'X-Internal-Key' => $this->mlInternalKey,
            ]);
        }

        return $client;
    }

    private function fallbackRuleBasedEvaluation(ChienDich $campaign): array
    {
        $creator = $campaign->nguoiTao;
        $score = 0.5;
        $flags = [];
        $creatorAccountAge = null;

        // === CAMPAIGN FEATURES ===
        if ($campaign->anh_bia) {
            $score += 0.05;
        } else {
            $flags[] = $this->makeFlag('NO_COVER_IMAGE', 'LOW', 'INFORMATION_COMPLETENESS',
                'Chiến dịch không có ảnh bìa', 'Yêu cầu người tạo bổ sung ảnh bìa để tăng độ tin cậy', true);
        }

        $hasLocationCoords = $campaign->vi_do !== null && $campaign->kinh_do !== null;
        if ($hasLocationCoords) {
            $score += 0.10;
        } else {
            $flags[] = $this->makeFlag('MISSING_LOCATION_COORDS', 'MEDIUM', 'INFORMATION_COMPLETENESS',
                'Chiến dịch thiếu tọa độ địa điểm', 'Yêu cầu bổ sung tọa độ GPS của địa điểm tổ chức', false);
        }

        if ($campaign->han_dang_ky) {
            $score += 0.08;
        } else {
            $flags[] = $this->makeFlag('NO_REGISTRATION_DEADLINE', 'MEDIUM', 'SCHEDULE_REASONABLENESS',
                'Chiến dịch không có hạn đăng ký', 'Thêm hạn đăng ký để TNV có thể lên kế hoạch', false);
        }

        $descLength = mb_strlen($campaign->mo_ta ?? '');
        if ($descLength > 200) {
            $score += 0.05;
        } elseif ($descLength < 50) {
            $flags[] = $this->makeFlag('DESCRIPTION_TOO_SHORT', 'LOW', 'INFORMATION_COMPLETENESS',
                'Mô tả chiến dịch quá ngắn (' . $descLength . ' ký tự)',
                'Mô tả nên có ít nhất 50 ký tự để cung cấp đủ thông tin', true);
            $score -= 0.03;
        }

        $locationComplete = $campaign->dia_diem && $hasLocationCoords;
        if (!$locationComplete) {
            $flags[] = $this->makeFlag('INCOMPLETE_LOCATION', 'LOW', 'INFORMATION_COMPLETENESS',
                'Thông tin địa điểm chưa đầy đủ',
                'Bổ sung địa chỉ chi tiết và tọa độ GPS', true);
        }

        if ($campaign->so_luong_toi_da && $campaign->so_luong_toi_da >= $campaign->so_luong_toi_thieu) {
            $score += 0.03;
        } else {
            $flags[] = $this->makeFlag('INVALID_VOLUNTEER_COUNT', 'LOW', 'INFORMATION_COMPLETENESS',
                'Số lượng TNV tối thiểu/tối đa không hợp lệ',
                'Kiểm tra lại số lượng TNV cần tuyển', true);
        }

        $daysUntilStart = $campaign->ngay_bat_dau
            ? Carbon::today()->startOfDay()->diffInDays($campaign->ngay_bat_dau->startOfDay(), false)
            : null;

        if ($daysUntilStart !== null && $daysUntilStart < 3 && $daysUntilStart >= 0) {
            $flags[] = $this->makeFlag('VERY_SHORT_REGISTRATION_WINDOW', 'LOW', 'SCHEDULE_REASONABLENESS',
                "Hạn đăng ký chỉ còn {$daysUntilStart} ngày",
                'Xem xét gia hạn để thu hút thêm TNV', false);
        }

        if ($campaign->muc_do_uu_tien === 'khan_cap') {
            $flags[] = $this->makeFlag('URGENT_PRIORITY_CAMPAIGN', 'MEDIUM', 'SCHEDULE_REASONABLENESS',
                'Chiến dịch có mức ưu tiên khẩn cấp',
                'Kiểm tra kỹ thông tin vì mức ưu tiên cao', false);
        }

        // === CREATOR FEATURES ===
        if (!$creator) {
            $flags[] = $this->makeFlag('CREATOR_NOT_FOUND', 'CRITICAL', 'CREATOR_RELIABILITY',
                'Không tìm thấy thông tin người tạo', 'Không thể xác minh uy tín người tạo', false);
            $score -= 0.30;
        } else {
            if ($creator->xac_thuc_email_luc) {
                $score += 0.08;
            } else {
                $flags[] = $this->makeFlag('CREATOR_UNVERIFIED_EMAIL', 'MEDIUM', 'CREATOR_RELIABILITY',
                    'Email người tạo chưa được xác thực',
                    'Yêu cầu người tạo xác thực email', false);
                $score -= 0.05;
            }

            if ($creator->anh_dai_dien) {
                $score += 0.03;
            } else {
                $flags[] = $this->makeFlag('CREATOR_NO_AVATAR', 'LOW', 'CREATOR_RELIABILITY',
                    'Người tạo chưa có ảnh đại diện',
                    'Yêu cầu người tạo cập nhật ảnh đại diện', true);
            }

            $creatorAccountAge = $creator->tao_luc
                ? max(0, Carbon::parse($creator->tao_luc)->startOfDay()->diffInDays(Carbon::today()->startOfDay(), false))
                : null;

            $creatorCampaigns = $creator->chienDichs()->count();
            $creatorCampaignCancelled = $creator->chienDichs()
                ->where('trang_thai', 'da_huy')
                ->count();

            if ($creatorAccountAge !== null && $creatorAccountAge < 7) {
                $flags[] = $this->makeFlag('CREATOR_NEW_ACCOUNT', 'MEDIUM', 'CREATOR_RELIABILITY',
                    "Tài khoản người tạo mới tạo ({$creatorAccountAge} ngày)",
                    'Kiểm tra kỹ thông tin chiến dịch, yêu cầu bổ sung giấy tờ minh chứng', false);
                $score -= 0.10;
            } elseif ($creatorAccountAge !== null && $creatorAccountAge >= 30) {
                $score += 0.08;
            }

            if ($creatorCampaigns === 0) {
                $flags[] = $this->makeFlag('CREATOR_FIRST_CAMPAIGN', 'LOW', 'CREATOR_RELIABILITY',
                    'Đây là chiến dịch đầu tiên của người tạo',
                    'Kiểm tra kỹ thông tin, có thể yêu cầu bổ sung minh chứng', false);
                $score -= 0.05;
            } elseif ($creatorCampaigns > 10) {
                $score += 0.10;
            } elseif ($creatorCampaigns > 3) {
                $score += 0.05;
            }

            if ($creatorCampaigns > 0) {
                $creatorCancellationRate = $creatorCampaignCancelled / $creatorCampaigns;

                if ($creatorCancellationRate > 0.3) {
                    $flags[] = $this->makeFlag('CREATOR_HIGH_CANCELLATION_RATE', 'HIGH', 'CREATOR_RELIABILITY',
                        "Tỷ lệ hủy chiến dịch cao (" . round($creatorCancellationRate * 100) . "%)",
                        'Yêu cầu giải trình hoặc từ chối chiến dịch', false);
                    $score -= 0.15;
                } elseif ($creatorCancellationRate < 0.1) {
                    $score += 0.05;
                }
            }

            $creatorReportCount = BaoCaoChienDich::where('noi_dung', 'LIKE', '%' . $creator->id . '%')
                ->orWhereHas('chienDich', fn ($q) => $q->where('nguoi_tao_id', $creator->id))
                ->count();

            if ($creatorReportCount > 0) {
                $flags[] = $this->makeFlag('CREATOR_HAS_REPORTS', 'MEDIUM', 'CREATOR_RELIABILITY',
                    "Người tạo đã có {$creatorReportCount} báo cáo liên quan",
                    'Xem xét lịch sử báo cáo trước khi duyệt', false);
                $score -= 0.10;
            }

            $avgCreatorRating = DanhGiaTnv::whereHas('chienDich', fn ($q) => $q->where('nguoi_tao_id', $creator->id))
                ->avg('so_sao');

            if ($avgCreatorRating !== null) {
                if ($avgCreatorRating >= 4.5) {
                    $score += 0.10;
                } elseif ($avgCreatorRating >= 4.0) {
                    $score += 0.05;
                } elseif ($avgCreatorRating < 3.0 && $avgCreatorRating > 0) {
                    $flags[] = $this->makeFlag('CREATOR_LOW_RATING', 'MEDIUM', 'CREATOR_RELIABILITY',
                        "Điểm đánh giá trung bình thấp (" . round($avgCreatorRating, 1) . "/5.0)",
                        'Kiểm tra các chiến dịch trước của người tạo', false);
                    $score -= 0.08;
                }
            }
        }

        // === BEHAVIORAL FEATURES ===
        $totalRegistrations = DangKyThamGia::where('nguoi_dung_id', $campaign->nguoi_tao_id)->count();

        if ($totalRegistrations === 0 && $creator && $creatorAccountAge !== null && $creatorAccountAge > 30) {
            $flags[] = $this->makeFlag('CREATOR_NO_REGISTRATION_HISTORY', 'LOW', 'CREATOR_RELIABILITY',
                'Người tạo chưa từng đăng ký tham gia chiến dịch nào',
                'Cân nhắc yêu cầu thêm minh chứng uy tín', false);
        }

        // === CONTENT TEXT ANALYSIS (basic keyword check) ===
        $textLower = mb_strtolower(($campaign->mo_ta ?? '') . ' ' . ($campaign->tieu_de ?? ''));
        $riskKeywords = [
            'chuyển khoản' => 'HIGH',
            'đặt cọc' => 'HIGH',
            'thu phí' => 'HIGH',
            'phí tham gia' => 'HIGH',
            'nộp tiền' => 'HIGH',
            'sẽ thông báo sau' => 'HIGH',
            'gặp mặt trực tiếp sẽ nói' => 'HIGH',
            'bí mật' => 'MEDIUM',
            'không công khai' => 'MEDIUM',
            'zalo' => 'MEDIUM',
            'messenger' => 'MEDIUM',
        ];

        foreach ($riskKeywords as $keyword => $severity) {
            if (str_contains($textLower, $keyword)) {
                $flags[] = $this->makeFlag('RISK_KEYWORD_IN_CONTENT', $severity, 'CONTENT_SAFETY',
                    "Phát hiện từ khóa rủi ro: '{$keyword}' trong nội dung",
                    'Xác minh nội dung chiến dịch, yêu cầu giải trình nếu có yêu cầu thu tiền', false);
                $score -= 0.10;
                break;
            }
        }

        // === FINAL SCORE ===
        $score = max(0.0, min(1.0, $score));

        $riskLevel = $this->mapScoreToRiskLevel($score);
        $confidence = $this->mapScoreToConfidence($score);
        $trustLabel = $this->mapScoreToTrustLabel($score);
        $recommendedAction = $this->mapScoreToAction($score, $riskLevel);
        $decisionReason = $this->buildDecisionReason($score, $riskLevel, $flags, $creator);

        return [
            'campaign_id' => $campaign->id,
            'evaluation_timestamp' => now()->toIso8601String(),
            'evaluation_source' => 'fallback',

            'validation_result' => [
                'passed' => empty(array_filter($flags, fn ($f) => $f['severity'] === 'CRITICAL')),
                'critical_errors' => array_values(array_filter($flags, fn ($f) => $f['severity'] === 'CRITICAL')),
                'warnings' => array_values(array_filter($flags, fn ($f) => $f['severity'] !== 'CRITICAL')),
            ],

            'trust_score' => [
                'raw_score' => round($score, 4),
                'calibrated_probability' => round($score, 4),
                'label' => $trustLabel,
                'confidence' => $confidence,
            ],

            'volunteer_trust_score' => null,

            'risk_assessment' => [
                'overall_risk_level' => $riskLevel,
                'risk_score' => round(1.0 - $score, 4),
                'flags' => $flags,
                'anomaly_score' => null,
                'is_anomaly' => false,
                'anomaly_types' => [],
            ],

            'content_analysis' => [
                'text_risk_keyword_count' => count(array_filter($flags, fn ($f) => $f['category'] === 'CONTENT_SAFETY')),
                'text_risk_score' => $this->calculateFallbackTextRiskScore($flags),
                'vagueness_score' => $this->calculateFallbackVaguenessScore($campaign->mo_ta ?? ''),
                'safety_description_score' => $this->calculateFallbackSafetyDescriptionScore($campaign->mo_ta ?? ''),
                'risk_keywords_found' => [],
            ],

            'decision_support' => [
                'recommended_action' => $recommendedAction,
                'confidence' => $confidence,
                'reason' => $decisionReason,
                'questions_to_verify' => $this->buildQuestionsToVerify($flags),
            ],

            'shap_explanation' => null,

            'model_info' => [
                'campaign_model_version' => 'fallback_v1',
                'campaign_training_date' => null,
                'campaign_training_samples' => null,
                'campaign_calibration_method' => null,
                'campaign_mlflow_run_id' => null,
                'volunteer_model_version' => null,
                'anomaly_model_version' => null,
            ],

            '_fallback' => true,
        ];
    }

    private function fallbackVolunteerEvaluation(NguoiDung $volunteer): array
    {
        $totalRegs = $volunteer->dangKyThamGias()->count();
        $cancelled = $volunteer->dangKyThamGias()->where('trang_thai', 'da_huy')->count();
        $hoanThanh = $volunteer->dangKyThamGias()->where('trang_thai', 'hoan_thanh')->count();
        $daXacNhan = $volunteer->dangKyThamGias()->whereIn('trang_thai', ['da_duyet', 'da_xac_nhan', 'dang_tham_gia'])->count();

        $cancelRate = $totalRegs > 0 ? $cancelled / $totalRegs : 0;
        $completionRate = $totalRegs > 0 ? $hoanThanh / $totalRegs : 0;

        $avgRatingReceived = DanhGiaTnv::where('tinh_nguyen_vien_id', $volunteer->id)->avg('so_sao');
        $ratingCount = DanhGiaTnv::where('tinh_nguyen_vien_id', $volunteer->id)->count();

        $score = 0.5;
        $flags = [];

        if ($cancelRate < 0.1) {
            $score += 0.15;
        } elseif ($cancelRate > 0.3) {
            $flags[] = $this->makeFlag('HIGH_CANCELLATION_RATE', 'HIGH', 'VOLUNTEER_BEHAVIOR',
                "Tỷ lệ hủy đăng ký cao (" . round($cancelRate * 100) . "%)",
                'Theo dõi hoạt động, có thể hạn chế đăng ký nhiều chiến dịch cùng lúc', false);
            $score -= 0.15;
        }

        if ($completionRate >= 0.8) {
            $score += 0.10;
        }

        if ($volunteer->chungChis()->count() > 0) {
            $score += 0.08;
        }

        if ($volunteer->kinhNghiems()->count() > 0) {
            $score += 0.05;
        }

        if ($volunteer->anh_dai_dien) {
            $score += 0.03;
        }

        if ($volunteer->xac_thuc_email_luc) {
            $score += 0.05;
        }

        if ($avgRatingReceived !== null && $avgRatingReceived >= 4.5) {
            $score += 0.05;
        }

        $accountAge = $volunteer->tao_luc
            ? max(0, Carbon::parse($volunteer->tao_luc)->startOfDay()->diffInDays(Carbon::today()->startOfDay(), false))
            : null;

        if ($accountAge !== null && $accountAge < 7) {
            $flags[] = $this->makeFlag('NEW_ACCOUNT', 'LOW', 'VOLUNTEER_BEHAVIOR',
                "Tài khoản mới tạo ({$accountAge} ngày)",
                'Theo dõi hoạt động trong 30 ngày đầu', false);
        }

        $profileCompleteness = $this->calculateProfileCompleteness($volunteer);
        if ($profileCompleteness >= 0.8) {
            $score += 0.05;
        } elseif ($profileCompleteness < 0.4) {
            $flags[] = $this->makeFlag('LOW_PROFILE_COMPLETENESS', 'LOW', 'VOLUNTEER_BEHAVIOR',
                "Hồ sơ chưa hoàn thiện (" . round($profileCompleteness * 100) . "%)",
                'Nhắc TNV cập nhật đầy đủ thông tin hồ sơ', true);
        }

        $score = max(0.0, min(1.0, $score));

        return [
            'volunteer_id' => $volunteer->id,
            'evaluation_timestamp' => now()->toIso8601String(),
            'evaluation_source' => 'fallback',

            'trust_score' => [
                'raw_score' => round($score, 4),
                'calibrated_probability' => round($score, 4),
                'label' => $this->mapScoreToTrustLabel($score),
                'confidence' => $this->mapScoreToConfidence($score),
            ],

            'reliability_summary' => [
                'total_registrations' => $totalRegs,
                'cancelled_registrations' => $cancelled,
                'cancellation_rate' => round($cancelRate, 4),
                'completion_rate' => round($completionRate, 4),
                'avg_rating_received' => $avgRatingReceived ? round((float) $avgRatingReceived, 2) : null,
                'rating_count' => $ratingCount,
            ],

            'behavior_flags' => $flags,

            'model_info' => [
                'model_version' => 'fallback_v1',
                'evaluation_date' => now()->toIso8601String(),
            ],

            '_fallback' => true,
        ];
    }

    // ==================== PERSISTENCE ====================

    private function persistEvaluation(int $campaignId, array $data): CampaignEvaluation
    {
        return CampaignEvaluation::updateOrCreate(
            [
                'chien_dich_id' => $campaignId,
                'model_version' => $data['model_info']['campaign_model_version'] ?? $data['model_info']['campaign_model_version'] ?? 'unknown',
                'evaluated_at' => $data['evaluation_timestamp'] ?? now(),
            ],
            [
                'evaluation_source' => $data['evaluation_source'] ?? 'fallback',
                'trust_score_raw' => $data['trust_score']['raw_score'] ?? null,
                'trust_score_calibrated' => $data['trust_score']['calibrated_probability'] ?? null,
                'trust_label' => $data['trust_score']['label'] ?? null,
                'trust_confidence' => $data['trust_score']['confidence'] ?? null,
                'volunteer_trust_score' => $data['volunteer_trust_score'] ?? null,
                'volunteer_trust_label' => $data['volunteer_trust_score']['label'] ?? null,
                'risk_level' => $data['risk_assessment']['overall_risk_level'] ?? null,
                'risk_score' => $data['risk_assessment']['risk_score'] ?? null,
                'anomaly_score' => $data['risk_assessment']['anomaly_score'] ?? null,
                'is_anomaly' => $data['risk_assessment']['is_anomaly'] ?? false,
                'risk_flags' => $data['risk_assessment']['flags'] ?? [],
                'content_analysis' => $data['content_analysis'] ?? null,
                'anomaly_types' => $data['risk_assessment']['anomaly_types'] ?? [],
                'recommended_action' => $data['decision_support']['recommended_action'] ?? null,
                'decision_confidence' => $data['decision_support']['confidence'] ?? null,
                'decision_reason' => $data['decision_support']['reason'] ?? null,
                'questions_to_verify' => $data['decision_support']['questions_to_verify'] ?? [],
                'shap_summary' => $data['shap_explanation'] ?? null,
                'validation_result' => $data['validation_result'] ?? null,
            ]
        );
    }

    private function persistVolunteerEvaluation(int $volunteerId, array $data): VolunteerEvaluation
    {
        return VolunteerEvaluation::updateOrCreate(
            [
                'nguoi_dung_id' => $volunteerId,
                'model_version' => $data['model_info']['model_version'] ?? 'fallback_v1',
                'evaluated_at' => $data['evaluation_timestamp'] ?? now(),
            ],
            [
                'trust_score_raw' => $data['trust_score']['raw_score'] ?? null,
                'trust_score_calibrated' => $data['trust_score']['calibrated_probability'] ?? null,
                'trust_label' => $data['trust_score']['label'] ?? null,
                'trust_confidence' => $data['trust_score']['confidence'] ?? null,
                'reliability_summary' => $data['reliability_summary'] ?? null,
                'behavior_flags' => $data['behavior_flags'] ?? [],
                'shap_summary' => $data['shap_explanation'] ?? null,
            ]
        );
    }

    private function formatEvaluationForApi(CampaignEvaluation $evaluation): array
    {
        return [
            'campaign_id' => $evaluation->chien_dich_id,
            'evaluation_timestamp' => $evaluation->evaluated_at?->toIso8601String(),
            'evaluation_source' => $evaluation->evaluation_source,

            'validation_result' => $evaluation->validation_result,

            'trust_score' => [
                'raw_score' => (float) $evaluation->trust_score_raw,
                'calibrated_probability' => (float) $evaluation->trust_score_calibrated,
                'label' => $evaluation->trust_label,
                'confidence' => $evaluation->trust_confidence,
            ],

            'volunteer_trust_score' => $evaluation->volunteer_trust_score ? [
                'raw_score' => (float) $evaluation->volunteer_trust_score,
                'label' => $evaluation->volunteer_trust_label,
            ] : null,

            'risk_assessment' => [
                'overall_risk_level' => $evaluation->risk_level,
                'risk_score' => (float) $evaluation->risk_score,
                'flags' => $evaluation->risk_flags ?? [],
                'anomaly_score' => $evaluation->anomaly_score ? (float) $evaluation->anomaly_score : null,
                'is_anomaly' => $evaluation->is_anomaly,
                'anomaly_types' => $evaluation->anomaly_types ?? [],
            ],

            'content_analysis' => $evaluation->content_analysis,

            'decision_support' => [
                'recommended_action' => $evaluation->recommended_action,
                'confidence' => $evaluation->decision_confidence,
                'reason' => $evaluation->decision_reason,
                'questions_to_verify' => $evaluation->questions_to_verify ?? [],
            ],

            'shap_explanation' => $evaluation->shap_summary,

            'model_info' => [
                'campaign_model_version' => $evaluation->model_version,
                'campaign_training_date' => null,
                'campaign_training_samples' => null,
                'campaign_calibration_method' => null,
                'campaign_mlflow_run_id' => null,
            ],

            '_fallback' => $evaluation->isFallback(),
        ];
    }

    // ==================== HELPERS ====================

    private function makeFlag(
        string $code,
        string $severity,
        string $category,
        string $message,
        string $suggestion,
        bool $autoResolvable
    ): array {
        return [
            'code' => $code,
            'severity' => $severity,
            'category' => $category,
            'message' => $message,
            'suggestion' => $suggestion,
            'auto_resolvable' => $autoResolvable,
        ];
    }

    private function mapScoreToRiskLevel(float $score): string
    {
        return match (true) {
            $score >= 0.70 => 'LOW',
            $score >= 0.40 => 'MEDIUM',
            $score >= 0.20 => 'HIGH',
            default => 'CRITICAL',
        };
    }

    private function mapScoreToTrustLabel(float $score): string
    {
        return match (true) {
            $score >= 0.80 => 'RELIABLE_HIGH',
            $score >= 0.60 => 'RELIABLE',
            $score >= 0.40 => 'NEUTRAL',
            $score >= 0.20 => 'SUSPICIOUS',
            default => 'SUSPICIOUS_HIGH',
        };
    }

    private function mapScoreToConfidence(float $score): string
    {
        return match (true) {
            $score >= 0.75 || $score <= 0.25 => 'HIGH',
            $score >= 0.55 || $score <= 0.35 => 'MEDIUM',
            default => 'LOW',
        };
    }

    private function mapScoreToAction(float $score, string $riskLevel): string
    {
        if ($score >= 0.70 && $riskLevel === 'LOW') {
            return 'APPROVE';
        }

        if ($score >= 0.60 && in_array($riskLevel, ['LOW', 'MEDIUM'])) {
            return 'APPROVE_WITH_NOTE';
        }

        if ($score >= 0.30 && $riskLevel !== 'CRITICAL') {
            return 'REQUEST_ADDITIONAL_INFO';
        }

        return 'REJECT';
    }

    private function buildDecisionReason(float $score, string $riskLevel, array $flags, ?NguoiDung $creator): string
    {
        if ($score >= 0.70) {
            $reason = 'Chiến dịch đáp ứng đủ điều kiện tin cậy cơ bản.';
        } elseif ($score >= 0.50) {
            $reason = 'Chiến dịch có một số điểm cần lưu ý, kiểm duyệt viên nên xem xét trước khi duyệt.';
        } else {
            $reason = 'Chiến dịch có nhiều yếu tố rủi ro cần được xác minh kỹ trước khi duyệt.';
        }

        if ($creator) {
            $campaignCount = $creator->chienDichs()->count();
            $reason .= " Người tạo có {$campaignCount} chiến dịch trong hệ thống.";
        }

        $criticalCount = count(array_filter($flags, fn ($f) => $f['severity'] === 'CRITICAL'));
        $highCount = count(array_filter($flags, fn ($f) => $f['severity'] === 'HIGH'));

        if ($criticalCount > 0) {
            $reason .= " Có {$criticalCount} lỗi nghiêm trọng cần sửa trước khi duyệt.";
        } elseif ($highCount > 0) {
            $reason .= " Có {$highCount} cảnh báo cao cần xác minh.";
        }

        return $reason;
    }

    private function buildQuestionsToVerify(array $flags): array
    {
        $questions = [];

        $criticalFlags = array_filter($flags, fn ($f) => $f['severity'] === 'CRITICAL');
        $highFlags = array_filter($flags, fn ($f) => $f['severity'] === 'HIGH');

        if (!empty($criticalFlags)) {
            foreach ($criticalFlags as $flag) {
                $questions[] = $flag['suggestion'];
            }
        }

        if (!empty($highFlags)) {
            foreach ($highFlags as $flag) {
                $questions[] = $flag['suggestion'];
            }
        }

        if (count($questions) === 0) {
            $questions[] = 'Xác nhận địa điểm chi tiết với người tạo.';
            $questions[] = 'Kiểm tra giấy phép/quyền tổ chức nếu là hoạt động chính thức.';
        }

        return array_slice(array_unique($questions), 0, 5);
    }

    private function calculateFallbackTextRiskScore(array $flags): float
    {
        $riskKeywordCount = count(array_filter($flags, fn ($f) => ($f['category'] ?? null) === 'CONTENT_SAFETY'));
        return round(min(1.0, $riskKeywordCount * 0.25), 4);
    }

    private function calculateFallbackVaguenessScore(string $description): float
    {
        $descLength = mb_strlen(trim($description));

        $score = match (true) {
            $descLength <= 20 => 0.9,
            $descLength <= 50 => 0.7,
            $descLength <= 120 => 0.4,
            default => 0.2,
        };

        return round($score, 4);
    }

    private function calculateFallbackSafetyDescriptionScore(string $description): float
    {
        $descriptionLower = mb_strtolower($description);
        $safetyKeywords = [
            'an toàn',
            'bao hiem',
            'bảo hiểm',
            'hỗ trợ',
            'ho tro',
            'khẩn cấp',
            'khan cap',
            'liên hệ',
            'lien he',
            'quy trình',
            'quy trinh',
        ];

        $matches = 0;
        foreach ($safetyKeywords as $keyword) {
            if (str_contains($descriptionLower, $keyword)) {
                $matches++;
            }
        }

        return round(min(1.0, $matches / 3), 4);
    }

    private function calculateProfileCompleteness(NguoiDung $volunteer): float
    {
        $fields = [
            $volunteer->ho_ten,
            $volunteer->email,
            $volunteer->so_dien_thoai,
            $volunteer->anh_dai_dien,
            $volunteer->ngay_sinh,
            $volunteer->gioi_tinh,
            $volunteer->dia_chi_duong,
            $volunteer->vi_do,
            $volunteer->kinh_do,
        ];

        $filled = count(array_filter($fields, fn ($v) => $v !== null && $v !== ''));

        return $filled / count($fields);
    }
}

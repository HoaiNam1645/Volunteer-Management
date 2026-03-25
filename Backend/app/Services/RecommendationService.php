<?php

namespace App\Services;

use App\Models\ChienDich;
use App\Models\DangKyThamGia;
use App\Models\DanhGiaTnv;
use App\Models\NguoiDung;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;

class RecommendationService
{
    public function __construct(
        private readonly MatchingScoreService $matchingScoreService,
        private readonly DistanceService $distanceService,
    ) {
    }

    public function recommendCampaignsForVolunteer(NguoiDung $volunteer, int $limit = 12, array $filters = []): array
    {
        $campaigns = ChienDich::query()
            ->whereNull('xoa_luc')
            ->with([
                'kyNangs:id,ten',
                'loaiChienDich:id,ten,bieu_tuong,mau_sac',
                'nguoiTao:id,ho_ten,email',
                'dangKyThamGias:id,chien_dich_id,nguoi_dung_id,trang_thai',
            ]);

        if (!empty($filters['priority'])) {
            $campaigns->where('muc_do_uu_tien', $filters['priority']);
        }

        $campaignList = $campaigns->get();

        $recommendations = [];
        foreach ($campaignList as $campaign) {
            $campaignEligibility = $this->evaluateCampaignVisibilityForVolunteer($volunteer, $campaign);
            if (!$campaignEligibility['qualified']) {
                continue;
            }

            if ($this->hasScheduleConflict($volunteer->id, $campaign)) {
                continue;
            }

            $reliabilityStats = $this->buildVolunteerReliabilityStats($volunteer->id);
            $historyTypeIds = $this->fetchVolunteerHistoryTypeIds($volunteer->id);
            $match = $this->evaluateVolunteerCampaignMatch(
                $volunteer,
                $campaign,
                $historyTypeIds,
                $reliabilityStats,
                !empty($filters['nearby_only'])
            );

            if (!$this->shouldDisplayCampaignRecommendation($match, !empty($filters['nearby_only']))) {
                continue;
            }

            $recommendations[] = [
                'id' => $campaign->id,
                'tieu_de' => $campaign->tieu_de,
                'mo_ta' => $campaign->mo_ta,
                'dia_diem' => $campaign->dia_diem,
                'ngay_bat_dau' => optional($campaign->ngay_bat_dau)->format('Y-m-d'),
                'ngay_ket_thuc' => optional($campaign->ngay_ket_thuc)->format('Y-m-d'),
                'han_dang_ky' => optional($campaign->han_dang_ky)->format('Y-m-d'),
                'muc_do_uu_tien' => $campaign->muc_do_uu_tien,
                'so_luong_toi_da' => $campaign->so_luong_toi_da,
                'so_dang_ky' => $campaign->so_dang_ky,
                'so_luong_toi_thieu' => $campaign->so_luong_toi_thieu,
                'loai_chien_dich' => $campaign->loaiChienDich,
                'ky_nangs' => $campaign->kyNangs->map(fn ($item) => ['id' => $item->id, 'ten' => $item->ten])->values(),
                'nguoi_tao' => $campaign->nguoiTao,
                'distance_km' => $match['distance_km'],
                'final_score' => $match['final_score'],
                'match_level' => $this->matchingScoreService->getMatchLevel($match['final_score']),
                'score_breakdown' => $match['score_breakdown'],
                'reasons' => $match['campaign_reasons'],
                'warnings' => $match['warnings'],
                'badges' => $this->buildCampaignBadges($campaign, $match['distance_km'], $match['score_breakdown']['skill'], $match['final_score']),
            ];
        }

        usort($recommendations, function ($a, $b) {
            $scoreCompare = $b['final_score'] <=> $a['final_score'];
            if ($scoreCompare !== 0) {
                return $scoreCompare;
            }

            $distanceA = $a['distance_km'];
            $distanceB = $b['distance_km'];

            if ($distanceA === null && $distanceB === null) {
                return 0;
            }

            if ($distanceA === null) {
                return 1;
            }

            if ($distanceB === null) {
                return -1;
            }

            return $distanceA <=> $distanceB;
        });

        return array_slice($recommendations, 0, max(1, $limit));
    }

    public function recommendVolunteersForCampaign(NguoiDung $actor, ChienDich $campaign, int $limit = 30, bool $onlyAvailable = true): array
    {
        $result = $this->buildVolunteerRecommendationDataset($campaign, $onlyAvailable);

        return [
            'recommendations' => array_slice($result['recommendations'], 0, max(1, $limit)),
            'excluded' => $result['excluded'],
        ];
    }

    private function buildVolunteerRecommendationDataset(
        ChienDich $campaign,
        bool $onlyAvailable = true,
        ?NguoiDung $targetVolunteer = null,
        bool $nearbyOnly = false
    ): array {
        $campaign->loadMissing([
            'kyNangs:id,ten',
            'loaiChienDich:id,ten,bieu_tuong,mau_sac',
            'dangKyThamGias:id,chien_dich_id,nguoi_dung_id,trang_thai',
        ]);

        $existingRegistrations = $campaign->dangKyThamGias
            ->keyBy(fn ($item) => (int) $item->nguoi_dung_id);

        $volunteers = NguoiDung::query()
            ->whereNull('xoa_luc')
            ->where('vai_tro', 'tinh_nguyen_vien')
            ->whereNotNull('xac_thuc_email_luc')
            ->when($targetVolunteer, fn (Builder $query) => $query->where('id', $targetVolunteer->id))
            ->when(!$targetVolunteer, fn (Builder $query) => $query->whereNotIn('id', [$campaign->nguoi_tao_id]))
            ->when($onlyAvailable && !$targetVolunteer, fn (Builder $query) => $query->where(function (Builder $subQuery) {
                $subQuery->whereNull('trang_thai')->orWhere('trang_thai', 'hoat_dong');
            }))
            ->with([
                'kyNangs:id,ten',
                'khuVucs:id,ten',
                'lichRanhs:id,nguoi_dung_id,thu_trong_tuan',
                'kinhNghiems:id,nguoi_dung_id',
                'chungChis:id,nguoi_dung_id',
            ])
            ->get();

        $recommendations = [];
        $excluded = [];

        foreach ($volunteers as $volunteer) {
            $existingRegistration = $existingRegistrations->get((int) $volunteer->id);
            $hasActiveRegistration = $existingRegistration && !in_array($existingRegistration->trang_thai, ['da_huy', 'tu_choi'], true);
            $reliabilityStats = $this->buildVolunteerReliabilityStats($volunteer->id);
            $historyTypeIds = $this->fetchVolunteerHistoryTypeIds($volunteer->id);
            $match = $this->evaluateVolunteerCampaignMatch(
                $volunteer,
                $campaign,
                $historyTypeIds,
                $reliabilityStats,
                $nearbyOnly
            );

            if ($existingRegistration && in_array($existingRegistration->trang_thai, ['da_duyet', 'dang_tham_gia', 'hoan_thanh'], true)) {
                continue;
            }

            $campaignEligibility = $this->evaluateCampaignVisibilityForVolunteer($volunteer, $campaign, $hasActiveRegistration);
            if (!$campaignEligibility['qualified']) {
                $excluded[] = $this->mapExcludedVolunteer($volunteer, $campaignEligibility['reason'], $match, $existingRegistration?->trang_thai, $reliabilityStats);
                continue;
            }

            if (!$hasActiveRegistration && $this->hasScheduleConflict($volunteer->id, $campaign)) {
                $excluded[] = $this->mapExcludedVolunteer($volunteer, 'Đang có chiến dịch khác bị trùng lịch.', $match, $existingRegistration?->trang_thai, $reliabilityStats);
                continue;
            }

            if (!$match['qualified']) {
                $excluded[] = $this->mapExcludedVolunteer($volunteer, $match['reason'], $match, $existingRegistration?->trang_thai, $reliabilityStats);
                continue;
            }

            $recommendations[] = [
                'id' => $volunteer->id,
                'ho_ten' => $volunteer->ho_ten,
                'email' => $volunteer->email,
                'anh_dai_dien' => $volunteer->anh_dai_dien,
                'ky_nangs' => $volunteer->kyNangs->map(fn ($item) => ['id' => $item->id, 'ten' => $item->ten])->values(),
                'khu_vucs' => $volunteer->khuVucs->map(fn ($item) => ['id' => $item->id, 'ten' => $item->ten])->values(),
                'lich_ranh' => $match['volunteer_days'],
                'distance_km' => $match['distance_km'],
                'final_score' => $match['final_score'],
                'match_level' => $this->matchingScoreService->getMatchLevel($match['final_score']),
                'score_breakdown' => $match['score_breakdown'],
                'reasons' => $match['volunteer_reasons'],
                'campaign_reasons' => $match['campaign_reasons'],
                'warnings' => $match['warnings'],
                'reliability' => $reliabilityStats,
                'registration_status' => $existingRegistration?->trang_thai,
                'experience_count' => $match['experience_count'],
                'certificate_count' => $match['certificate_count'],
            ];
        }

        usort($recommendations, function ($a, $b) {
            $scoreCompare = $b['final_score'] <=> $a['final_score'];
            if ($scoreCompare !== 0) {
                return $scoreCompare;
            }

            $distanceA = $a['distance_km'];
            $distanceB = $b['distance_km'];

            if ($distanceA === null && $distanceB === null) {
                return 0;
            }

            if ($distanceA === null) {
                return 1;
            }

            if ($distanceB === null) {
                return -1;
            }

            return $distanceA <=> $distanceB;
        });

        return [
            'recommendations' => $recommendations,
            'excluded' => $excluded,
        ];
    }

    public function buildAllocationSuggestion(NguoiDung $actor, ChienDich $campaign): array
    {
        $result = $this->recommendVolunteersForCampaign($actor, $campaign, 50, true);
        $recommendations = $result['recommendations'];
        $recommended = array_values(array_filter($recommendations, fn ($item) => $item['final_score'] >= 50 && $item['final_score'] < 80));
        $primary = array_values(array_filter($recommendations, fn ($item) => $item['final_score'] >= 80));

        $minTarget = max(1, (int) ($campaign->so_luong_toi_thieu ?? 1));
        $confirmed = (int) ($campaign->so_xac_nhan ?? 0);
        $registered = (int) ($campaign->so_dang_ky ?? 0);

        $riskFlags = [];
        if (count($primary) < $minTarget) {
            $riskFlags[] = [
                'code' => 'high_risk',
                'message' => 'Thiếu ứng viên phù hợp so với số lượng tối thiểu của chiến dịch.',
            ];
        }

        if (!empty($recommendations)) {
            $farCount = count(array_filter($recommendations, fn ($item) => ($item['distance_km'] ?? 0) > 20));
            if ($farCount > 0 && $farCount >= ceil(count($recommendations) / 2)) {
                $riskFlags[] = [
                    'code' => 'distance_risk',
                    'message' => 'Phần lớn ứng viên phù hợp ở khá xa địa điểm chiến dịch.',
                ];
            }

            $partialAvailabilityCount = count(array_filter($recommendations, fn ($item) => ($item['score_breakdown']['availability'] ?? 0) < 100));
            if ($partialAvailabilityCount > 0 && $partialAvailabilityCount >= ceil(count($recommendations) / 2)) {
                $riskFlags[] = [
                    'code' => 'availability_risk',
                    'message' => 'Nhiều ứng viên chỉ khớp lịch rảnh một phần với chiến dịch.',
                ];
            }
        }

        return [
            'recommended_primary' => $primary,
            'recommended_backup' => [],
            'recommended' => $recommended,
            'excluded' => $result['excluded'],
            'resource_summary' => [
                'so_luong_toi_thieu' => $minTarget,
                'so_luong_toi_da' => (int) ($campaign->so_luong_toi_da ?? 0),
                'so_dang_ky_hien_tai' => $registered,
                'so_xac_nhan_hien_tai' => $confirmed,
                'so_tnv_de_xuat' => count($recommendations),
                'so_tnv_du_chuan' => count($primary),
            ],
            'risk_flags' => $riskFlags,
        ];
    }

    private function evaluateCampaignVisibilityForVolunteer(NguoiDung $volunteer, ChienDich $campaign, bool $ignoreExistingRegistration = false): array
    {
        $today = Carbon::today()->toDateString();
        $activeRegistrationVolunteerIds = $campaign->dangKyThamGias
            ->whereNotIn('trang_thai', ['da_huy', 'tu_choi'])
            ->pluck('nguoi_dung_id')
            ->map(fn ($id) => (int) $id)
            ->all();

        if (!is_null($campaign->xoa_luc)) {
            return ['qualified' => false, 'reason' => 'Chiến dịch này không còn hoạt động.'];
        }

        if ($campaign->trang_thai !== 'da_duyet') {
            return ['qualified' => false, 'reason' => 'Chiến dịch này chưa sẵn sàng để giới thiệu tới tình nguyện viên.'];
        }

        if ((int) $campaign->nguoi_tao_id === (int) $volunteer->id) {
            return ['qualified' => false, 'reason' => 'Bạn là người tạo chiến dịch này.'];
        }

        if ($campaign->han_dang_ky && Carbon::parse($campaign->han_dang_ky)->toDateString() < $today) {
            return ['qualified' => false, 'reason' => 'Chiến dịch đã hết hạn đăng ký.'];
        }

        if ($campaign->ngay_ket_thuc && Carbon::parse($campaign->ngay_ket_thuc)->toDateString() < $today) {
            return ['qualified' => false, 'reason' => 'Chiến dịch đã kết thúc.'];
        }

        if (
            !is_null($campaign->so_luong_toi_da)
            && (int) $campaign->so_luong_toi_da > 0
            && (int) ($campaign->so_dang_ky ?? 0) >= (int) $campaign->so_luong_toi_da
        ) {
            return ['qualified' => false, 'reason' => 'Chiến dịch hiện đã đủ số lượng đăng ký.'];
        }

        if (!$ignoreExistingRegistration && in_array((int) $volunteer->id, $activeRegistrationVolunteerIds, true)) {
            return ['qualified' => false, 'reason' => 'Bạn đã có đăng ký đang hoạt động với chiến dịch này.'];
        }

        return ['qualified' => true, 'reason' => null];
    }

    private function buildVolunteerReliabilityStats(int $volunteerId): array
    {
        $registrations = DangKyThamGia::query()
            ->where('nguoi_dung_id', $volunteerId)
            ->get(['trang_thai']);

        $avgRating = DanhGiaTnv::query()
            ->where('tinh_nguyen_vien_id', $volunteerId)
            ->avg('so_sao');

        return [
            'total' => $registrations->count(),
            'confirmed' => $registrations->whereIn('trang_thai', ['da_xac_nhan', 'da_duyet', 'dang_tham_gia', 'hoan_thanh'])->count(),
            'cancelled' => $registrations->where('trang_thai', 'da_huy')->count(),
            'avg_rating' => $avgRating ? round((float) $avgRating, 2) : 0,
        ];
    }

    private function fetchVolunteerHistoryTypeIds(int $volunteerId): array
    {
        return DangKyThamGia::query()
            ->where('nguoi_dung_id', $volunteerId)
            ->whereIn('trang_thai', ['da_xac_nhan', 'da_duyet', 'dang_tham_gia', 'hoan_thanh'])
            ->whereHas('chienDich', fn (Builder $query) => $query->whereNotNull('loai_chien_dich_id'))
            ->with('chienDich:id,loai_chien_dich_id')
            ->get()
            ->map(fn ($dangKy) => (int) optional($dangKy->chienDich)->loai_chien_dich_id)
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    private function hasScheduleConflict(int $volunteerId, ChienDich $campaign): bool
    {
        return DangKyThamGia::query()
            ->where('nguoi_dung_id', $volunteerId)
            ->whereIn('trang_thai', ['da_dang_ky', 'da_duyet', 'da_xac_nhan', 'dang_tham_gia'])
            ->whereHas('chienDich', function (Builder $query) use ($campaign) {
                $query->whereNull('xoa_luc')
                    ->where('id', '!=', $campaign->id)
                    ->where(function (Builder $dateQuery) use ($campaign) {
                        $dateQuery
                            ->whereBetween('ngay_bat_dau', [$campaign->ngay_bat_dau, $campaign->ngay_ket_thuc])
                            ->orWhereBetween('ngay_ket_thuc', [$campaign->ngay_bat_dau, $campaign->ngay_ket_thuc])
                            ->orWhere(function (Builder $coverQuery) use ($campaign) {
                                $coverQuery->where('ngay_bat_dau', '<=', $campaign->ngay_bat_dau)
                                    ->where('ngay_ket_thuc', '>=', $campaign->ngay_ket_thuc);
                            });
                    });
            })
            ->exists();
    }

    private function evaluateVolunteerCampaignMatch(
        NguoiDung $volunteer,
        ChienDich $campaign,
        array $historyTypeIds,
        array $reliabilityStats,
        bool $nearbyOnly = false
    ): array {
        $volunteerSkillIds = $volunteer->kyNangs->pluck('id')->map(fn ($id) => (int) $id)->all();
        $campaignSkillIds = $campaign->kyNangs->pluck('id')->map(fn ($id) => (int) $id)->all();
        $volunteerAreaIds = $volunteer->khuVucs->pluck('id')->map(fn ($id) => (int) $id)->all();
        $volunteerDays = $volunteer->lichRanhs->pluck('thu_trong_tuan')->filter()->values()->all();
        $experienceCount = $volunteer->kinhNghiems->count();
        $certificateCount = $volunteer->chungChis->count();
        $campaignWeekDays = $this->matchingScoreService->extractCampaignWeekdays($campaign);
        $matchedSkillCount = count(array_intersect($volunteerSkillIds, $campaignSkillIds));
        $distanceKm = $this->distanceService->haversine(
            $this->floatOrNull($volunteer->vi_do),
            $this->floatOrNull($volunteer->kinh_do),
            $this->floatOrNull($campaign->vi_do),
            $this->floatOrNull($campaign->kinh_do),
        );

        $breakdown = [
            'skill' => $this->matchingScoreService->calculateSkillScore($volunteerSkillIds, $campaignSkillIds),
            'availability' => $this->matchingScoreService->calculateAvailabilityScore($volunteerDays, $campaignWeekDays),
            'distance' => $this->distanceService->scoreFromDistance($distanceKm),
            'preference' => $this->matchingScoreService->calculatePreferenceScore([
                'campaign_area_id' => $campaign->khu_vuc_id,
                'volunteer_area_ids' => $volunteerAreaIds,
                'campaign_type_id' => $campaign->loai_chien_dich_id,
                'history_type_ids' => $historyTypeIds,
                'campaign_week_days' => $campaignWeekDays,
                'volunteer_days' => $volunteerDays,
                'time_preference' => $volunteer->khung_gio_uu_tien,
            ]),
            'reliability' => $this->matchingScoreService->calculateReliabilityScore($reliabilityStats),
            'profile_strength' => $this->matchingScoreService->calculateProfileStrengthScore($experienceCount, $certificateCount),
        ];

        $finalScore = $this->matchingScoreService->calculateFinalScore($breakdown);
        $qualification = $this->evaluateRecommendationQualification(
            $campaign,
            $campaignSkillIds,
            $matchedSkillCount,
            $campaignWeekDays,
            $breakdown['availability'],
            $distanceKm,
            $finalScore,
            $nearbyOnly
        );

        $warnings = $this->buildCampaignWarnings(
            $distanceKm,
            $breakdown['availability'],
            empty($volunteerSkillIds),
            empty($volunteerDays)
        );

        return [
            'qualified' => (bool) ($qualification['qualified'] ?? false),
            'reason' => $qualification['reason'] ?? null,
            'qualification_code' => $qualification['code'] ?? null,
            'distance_km' => $distanceKm,
            'final_score' => $finalScore,
            'score_breakdown' => $breakdown,
            'warnings' => $warnings,
            'campaign_reasons' => $this->buildCampaignReasons($campaign, $campaignSkillIds, $volunteerSkillIds, $distanceKm, $breakdown['availability']),
            'volunteer_reasons' => $this->buildVolunteerReasons(
                $campaign,
                $campaignSkillIds,
                $volunteerSkillIds,
                $distanceKm,
                $breakdown['availability'],
                $reliabilityStats,
                $experienceCount,
                $certificateCount
            ),
            'volunteer_days' => $volunteerDays,
            'experience_count' => $experienceCount,
            'certificate_count' => $certificateCount,
        ];
    }

    private function buildCampaignReasons(ChienDich $campaign, array $campaignSkillIds, array $volunteerSkillIds, ?float $distanceKm, float $availabilityScore): array
    {
        $reasons = [];
        $matchedSkillCount = count(array_intersect($campaignSkillIds, $volunteerSkillIds));

        if ($matchedSkillCount > 0) {
            $reasons[] = "Khớp {$matchedSkillCount}/" . max(count($campaignSkillIds), 1) . ' kỹ năng yêu cầu.';
        }

        if (empty($campaignSkillIds)) {
            $reasons[] = 'Chiến dịch này không yêu cầu kỹ năng chuyên môn bắt buộc.';
        }

        if ($distanceKm !== null && $distanceKm <= 10) {
            $reasons[] = "Địa điểm khá gần bạn ({$distanceKm} km).";
        }

        if ($availabilityScore >= 100) {
            $reasons[] = 'Lịch rảnh của bạn khớp hoàn toàn với thời gian chiến dịch.';
        } elseif ($availabilityScore > 0) {
            $reasons[] = 'Lịch rảnh của bạn khớp một phần với chiến dịch.';
        }

        if ($campaign->muc_do_uu_tien === 'khan_cap') {
            $reasons[] = 'Chiến dịch đang ở mức ưu tiên khẩn cấp.';
        }

        return array_slice($reasons, 0, 3);
    }

    private function buildCampaignBadges(ChienDich $campaign, ?float $distanceKm, float $skillScore, float $finalScore): array
    {
        $badges = [];

        if ($finalScore >= 80) {
            $badges[] = 'Rất phù hợp';
        }
        if ($distanceKm !== null && $distanceKm <= 10) {
            $badges[] = 'Gần bạn';
        }
        if ($skillScore >= 60) {
            $badges[] = 'Phù hợp kỹ năng';
        }
        if ($campaign->muc_do_uu_tien === 'khan_cap') {
            $badges[] = 'Cần gấp';
        }

        return array_values(array_unique($badges));
    }

    private function buildVolunteerReasons(
        ChienDich $campaign,
        array $campaignSkillIds,
        array $volunteerSkillIds,
        ?float $distanceKm,
        float $availabilityScore,
        array $reliabilityStats,
        int $experienceCount,
        int $certificateCount
    ): array
    {
        $reasons = [];
        $matchedSkillCount = count(array_intersect($campaignSkillIds, $volunteerSkillIds));

        if ($matchedSkillCount > 0) {
            $reasons[] = "Khớp {$matchedSkillCount}/" . max(count($campaignSkillIds), 1) . ' kỹ năng yêu cầu.';
        }

        if ($distanceKm !== null && $distanceKm <= 10) {
            $reasons[] = "Cách địa điểm chiến dịch {$distanceKm} km.";
        }

        if ($availabilityScore >= 100) {
            $reasons[] = 'Khớp hoàn toàn lịch rảnh với chiến dịch.';
        } elseif ($availabilityScore > 0) {
            $reasons[] = 'Khớp một phần lịch rảnh với chiến dịch.';
        }

        if (($reliabilityStats['avg_rating'] ?? 0) > 0) {
            $reasons[] = 'Có đánh giá tích cực từ các chiến dịch trước.';
        }

        if ($experienceCount > 0 || $certificateCount > 0) {
            $reasons[] = "Hồ sơ có {$experienceCount} kinh nghiệm và {$certificateCount} chứng chỉ hỗ trợ thêm cho mức độ phù hợp.";
        }

        return array_slice($reasons, 0, 4);
    }

    private function buildWarnings(?float $distanceKm, float $availabilityScore): array
    {
        $warnings = [];

        if ($distanceKm === null) {
            $warnings[] = 'Thiếu dữ liệu vị trí để tính khoảng cách.';
        }

        if ($distanceKm !== null && $distanceKm > 20) {
            $warnings[] = 'Khoảng cách khá xa so với địa điểm chiến dịch.';
        }

        if ($availabilityScore > 0 && $availabilityScore < 100) {
            $warnings[] = 'Chỉ khớp một phần lịch rảnh.';
        }

        return $warnings;
    }

    private function buildCampaignWarnings(?float $distanceKm, float $availabilityScore, bool $missingSkills, bool $missingAvailability): array
    {
        $warnings = $this->buildWarnings($distanceKm, $availabilityScore);

        if ($missingSkills) {
            $warnings[] = 'Bạn chưa cập nhật đầy đủ kỹ năng nên độ chính xác gợi ý còn hạn chế.';
        }

        if ($missingAvailability) {
            $warnings[] = 'Bạn chưa cập nhật lịch rảnh đầy đủ nên hệ thống chỉ gợi ý trong phạm vi hạn chế.';
        }

        return array_values(array_unique($warnings));
    }

    private function evaluateRecommendationQualification(
        ChienDich $campaign,
        array $campaignSkillIds,
        int $matchedSkillCount,
        array $campaignWeekDays,
        float $availabilityScore,
        ?float $distanceKm,
        float $finalScore,
        bool $nearbyOnly
    ): array {
        $policy = $this->getRecommendationPolicy($campaign->muc_do_uu_tien);

        if (!empty($campaignSkillIds)) {
            if ($matchedSkillCount <= 0) {
                return ['qualified' => false, 'reason' => 'Chưa có kỹ năng phù hợp với yêu cầu hiện tại của chiến dịch.', 'code' => 'no_skill_match'];
            }

            $skillCoverage = $matchedSkillCount / count($campaignSkillIds);
            if ($skillCoverage < $policy['min_skill_coverage']) {
                return [
                    'qualified' => false,
                    'reason' => "Mới đáp ứng {$matchedSkillCount}/" . count($campaignSkillIds) . ' kỹ năng cần thiết của chiến dịch.',
                    'code' => 'low_skill_coverage',
                ];
            }
        }

        if (!empty($campaignWeekDays)) {
            if ($availabilityScore <= 0) {
                return ['qualified' => false, 'reason' => 'Không khớp lịch rảnh với thời gian chiến dịch.', 'code' => 'no_availability_match'];
            }

            if ($availabilityScore < $policy['min_availability']) {
                return ['qualified' => false, 'reason' => 'Lịch rảnh hiện chỉ khớp một phần nhỏ nên khó tham gia ổn định.', 'code' => 'low_availability'];
            }
        }

        if ($nearbyOnly && ($distanceKm === null || $distanceKm > 20)) {
            return ['qualified' => false, 'reason' => 'Chiến dịch này không nằm trong phạm vi gần bạn.', 'code' => 'nearby_only_filter'];
        }

        if ($distanceKm !== null && $distanceKm > $policy['max_distance_km']) {
            return ['qualified' => false, 'reason' => "Khoảng cách hiện khá xa ({$distanceKm} km) so với mức phù hợp cho chiến dịch này.", 'code' => 'distance_too_far'];
        }

        if ($finalScore < $policy['minimum_score']) {
            return ['qualified' => false, 'reason' => 'Mức độ phù hợp tổng thể hiện còn thấp so với nhu cầu hiện tại của chiến dịch.', 'code' => 'score_too_low'];
        }

        return ['qualified' => true, 'reason' => null, 'code' => null];
    }

    private function shouldDisplayCampaignRecommendation(array $match, bool $nearbyOnly = false): bool
    {
        if ($match['qualified']) {
            return true;
        }

        if ($nearbyOnly && (($match['qualification_code'] ?? null) === 'nearby_only_filter')) {
            return false;
        }

        if (in_array($match['qualification_code'] ?? null, ['no_skill_match', 'no_availability_match'], true)) {
            return false;
        }

        return (float) ($match['final_score'] ?? 0) >= 50;
    }

    private function getRecommendationPolicy(?string $priority): array
    {
        return match ($priority) {
            'khan_cap' => [
                'min_skill_coverage' => 0.34,
                'min_availability' => 40,
                'max_distance_km' => 20,
                'minimum_score' => 45,
            ],
            'cao' => [
                'min_skill_coverage' => 0.5,
                'min_availability' => 50,
                'max_distance_km' => 25,
                'minimum_score' => 50,
            ],
            'thap' => [
                'min_skill_coverage' => 0.5,
                'min_availability' => 60,
                'max_distance_km' => 40,
                'minimum_score' => 55,
            ],
            default => [
                'min_skill_coverage' => 0.5,
                'min_availability' => 60,
                'max_distance_km' => 30,
                'minimum_score' => 55,
            ],
        };
    }

    private function mapExcludedVolunteer(
        NguoiDung $volunteer,
        string $reason,
        array $match,
        ?string $registrationStatus = null,
        array $reliabilityStats = []
    ): array
    {
        return [
            'id' => $volunteer->id,
            'ho_ten' => $volunteer->ho_ten,
            'email' => $volunteer->email,
            'anh_dai_dien' => $volunteer->anh_dai_dien,
            'ky_nangs' => $volunteer->kyNangs->map(fn ($item) => ['id' => $item->id, 'ten' => $item->ten])->values(),
            'khu_vucs' => $volunteer->khuVucs->map(fn ($item) => ['id' => $item->id, 'ten' => $item->ten])->values(),
            'lich_ranh' => $match['volunteer_days'] ?? [],
            'distance_km' => $match['distance_km'] ?? null,
            'final_score' => $match['final_score'] ?? 0,
            'match_level' => $this->matchingScoreService->getMatchLevel($match['final_score'] ?? 0),
            'score_breakdown' => $match['score_breakdown'] ?? null,
            'reasons' => $match['volunteer_reasons'] ?? [],
            'campaign_reasons' => $match['campaign_reasons'] ?? [],
            'warnings' => $match['warnings'] ?? [],
            'reliability' => $reliabilityStats,
            'registration_status' => $registrationStatus,
            'experience_count' => $match['experience_count'] ?? 0,
            'certificate_count' => $match['certificate_count'] ?? 0,
            'reason' => $reason,
        ];
    }

    private function floatOrNull($value): ?float
    {
        return is_numeric($value) ? (float) $value : null;
    }
}

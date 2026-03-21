<?php

namespace App\Services;

use App\Models\ChienDich;
use Carbon\Carbon;
use Carbon\CarbonPeriod;

class MatchingScoreService
{
    private const WEIGHT_SKILL = 0.30;
    private const WEIGHT_AVAILABILITY = 0.20;
    private const WEIGHT_DISTANCE = 0.30;
    private const WEIGHT_PREFERENCE = 0.05;
    private const WEIGHT_RELIABILITY = 0.05;
    private const WEIGHT_PROFILE_STRENGTH = 0.10;

    public function calculateSkillScore(array $sourceSkillIds, array $targetSkillIds): float
    {
        $sourceSkillIds = array_values(array_unique(array_map('intval', $sourceSkillIds)));
        $targetSkillIds = array_values(array_unique(array_map('intval', $targetSkillIds)));

        if (empty($targetSkillIds)) {
            return 50;
        }

        if (empty($sourceSkillIds)) {
            return 0;
        }

        $intersectionCount = count(array_intersect($sourceSkillIds, $targetSkillIds));
        if ($intersectionCount === 0) {
            return 0;
        }

        $coverage = $intersectionCount / count($targetSkillIds);
        $cosineDenominator = sqrt(count($sourceSkillIds) * count($targetSkillIds));
        $cosine = $cosineDenominator > 0 ? ($intersectionCount / $cosineDenominator) : 0;

        return round((($coverage * 0.7) + ($cosine * 0.3)) * 100, 2);
    }

    public function calculateAvailabilityScore(array $volunteerDays, array $campaignDays): float
    {
        $volunteerDays = array_values(array_unique($volunteerDays));
        $campaignDays = array_values(array_unique($campaignDays));

        if (empty($volunteerDays) || empty($campaignDays)) {
            return 0;
        }

        $matched = count(array_intersect($volunteerDays, $campaignDays));

        return round(($matched / count($campaignDays)) * 100, 2);
    }

    public function extractCampaignWeekdays(ChienDich $campaign): array
    {
        if (!$campaign->ngay_bat_dau || !$campaign->ngay_ket_thuc) {
            return [];
        }

        $start = Carbon::parse($campaign->ngay_bat_dau)->startOfDay();
        $end = Carbon::parse($campaign->ngay_ket_thuc)->startOfDay();

        if ($end->lt($start)) {
            return [];
        }

        $map = [
            Carbon::MONDAY => 'thu_hai',
            Carbon::TUESDAY => 'thu_ba',
            Carbon::WEDNESDAY => 'thu_tu',
            Carbon::THURSDAY => 'thu_nam',
            Carbon::FRIDAY => 'thu_sau',
            Carbon::SATURDAY => 'thu_bay',
            Carbon::SUNDAY => 'chu_nhat',
        ];

        $days = [];
        foreach (CarbonPeriod::create($start, $end) as $date) {
            $days[] = $map[$date->dayOfWeekIso] ?? null;
        }

        return array_values(array_filter(array_unique($days)));
    }

    public function calculatePreferenceScore(array $context): float
    {
        $score = 0;

        $campaignAreaId = (int) ($context['campaign_area_id'] ?? 0);
        $volunteerAreaIds = array_map('intval', $context['volunteer_area_ids'] ?? []);
        if ($campaignAreaId > 0 && in_array($campaignAreaId, $volunteerAreaIds, true)) {
            $score += 60;
        }

        $campaignTypeId = (int) ($context['campaign_type_id'] ?? 0);
        $historyTypeIds = array_map('intval', $context['history_type_ids'] ?? []);
        if ($campaignTypeId > 0 && in_array($campaignTypeId, $historyTypeIds, true)) {
            $score += 25;
        }

        $campaignWeekDays = $context['campaign_week_days'] ?? [];
        $volunteerDays = $context['volunteer_days'] ?? [];
        $timePreference = $context['time_preference'] ?? null;
        if ($timePreference && $timePreference !== 'linh_hoat' && !empty(array_intersect($campaignWeekDays, $volunteerDays))) {
            $score += 15;
        }

        return min(100, round($score, 2));
    }

    public function calculateReliabilityScore(array $stats): float
    {
        $total = (int) ($stats['total'] ?? 0);
        $confirmed = (int) ($stats['confirmed'] ?? 0);
        $cancelled = (int) ($stats['cancelled'] ?? 0);
        $avgRating = (float) ($stats['avg_rating'] ?? 0);

        if ($total === 0 && $avgRating <= 0) {
            return 50;
        }

        $confirmRate = $total > 0 ? $confirmed / $total : 0;
        $cancelRate = $total > 0 ? $cancelled / $total : 0;
        $ratingScore = $avgRating > 0 ? ($avgRating / 5) : 0.5;

        $score = 50 + ($confirmRate * 30) + ($ratingScore * 20) - ($cancelRate * 20);

        return max(0, min(100, round($score, 2)));
    }

    public function calculateProfileStrengthScore(int $experienceCount, int $certificateCount): float
    {
        $normalizedExperience = min(max($experienceCount, 0), 5) / 5;
        $normalizedCertificate = min(max($certificateCount, 0), 3) / 3;

        return round((($normalizedExperience * 0.7) + ($normalizedCertificate * 0.3)) * 100, 2);
    }

    public function calculateFinalScore(array $breakdown): float
    {
        return round(
            ($breakdown['skill'] ?? 0) * self::WEIGHT_SKILL
            + ($breakdown['availability'] ?? 0) * self::WEIGHT_AVAILABILITY
            + ($breakdown['distance'] ?? 0) * self::WEIGHT_DISTANCE
            + ($breakdown['preference'] ?? 0) * self::WEIGHT_PREFERENCE
            + ($breakdown['reliability'] ?? 0) * self::WEIGHT_RELIABILITY
            + ($breakdown['profile_strength'] ?? 0) * self::WEIGHT_PROFILE_STRENGTH,
            2
        );
    }

    public function getMatchLevel(float $score): string
    {
        if ($score >= 80) {
            return 'rat_phu_hop';
        }

        if ($score >= 60) {
            return 'phu_hop';
        }

        return 'can_nhac';
    }
}

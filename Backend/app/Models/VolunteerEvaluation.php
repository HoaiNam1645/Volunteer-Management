<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VolunteerEvaluation extends Model
{
    protected $table = 'volunteer_evaluations';

    const CREATED_AT = 'created_at';
    const UPDATED_AT = 'updated_at';

    protected $fillable = [
        'nguoi_dung_id',
        'model_version',
        'trust_score_raw',
        'trust_score_calibrated',
        'trust_label',
        'trust_confidence',
        'reliability_summary',
        'behavior_flags',
        'shap_summary',
        'evaluated_at',
    ];

    protected function casts(): array
    {
        return [
            'trust_score_raw' => 'decimal:4',
            'trust_score_calibrated' => 'decimal:4',
            'reliability_summary' => 'array',
            'behavior_flags' => 'array',
            'shap_summary' => 'array',
            'evaluated_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    const TRUST_LABELS = [
        'RELIABLE_HIGH' => 'Đáng tin cậy cao',
        'RELIABLE' => 'Đáng tin cậy',
        'NEUTRAL' => 'Trung lập',
        'SUSPICIOUS' => 'Đáng ngờ',
        'SUSPICIOUS_HIGH' => 'Đáng ngờ cao',
    ];

    const CONFIDENCE_LEVELS = [
        'HIGH' => 'Cao',
        'MEDIUM' => 'Trung bình',
        'LOW' => 'Thấp',
    ];

    // Relationships
    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }

    // Helpers
    public function getTrustLabelTextAttribute(): string
    {
        return self::TRUST_LABELS[$this->trust_label] ?? $this->trust_label ?? 'N/A';
    }

    public function getConfidenceTextAttribute(): string
    {
        return self::CONFIDENCE_LEVELS[$this->trust_confidence] ?? $this->trust_confidence ?? 'N/A';
    }

    public function isMlEvaluated(): bool
    {
        return str_starts_with($this->model_version, 'volunteer_trust_v');
    }

    public function isFallback(): bool
    {
        return $this->model_version === 'fallback_v1';
    }

    public function hasBehaviorFlags(): bool
    {
        return !empty($this->behavior_flags);
    }

    public function getFlagCountBySeverity(string $severity): int
    {
        if (empty($this->behavior_flags)) {
            return 0;
        }

        return collect($this->behavior_flags)->where('severity', $severity)->count();
    }

    public function getCancellationRate(): float
    {
        return (float) ($this->reliability_summary['cancellation_rate'] ?? 0);
    }

    public function getCompletionRate(): float
    {
        return (float) ($this->reliability_summary['completion_rate'] ?? 0);
    }

    public function getAvgRating(): float
    {
        return (float) ($this->reliability_summary['avg_rating_received'] ?? 0);
    }
}

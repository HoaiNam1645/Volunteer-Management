<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CampaignEvaluation extends Model
{
    protected $table = 'campaign_evaluations';

    const CREATED_AT = 'created_at';
    const UPDATED_AT = 'updated_at';

    protected $fillable = [
        'chien_dich_id',
        'model_version',
        'evaluation_source',
        'trust_score_raw',
        'trust_score_calibrated',
        'trust_label',
        'trust_confidence',
        'volunteer_trust_score',
        'volunteer_trust_label',
        'risk_level',
        'risk_score',
        'anomaly_score',
        'is_anomaly',
        'risk_flags',
        'content_analysis',
        'anomaly_types',
        'recommended_action',
        'decision_confidence',
        'decision_reason',
        'questions_to_verify',
        'shap_summary',
        'validation_result',
        'evaluated_at',
    ];

    protected function casts(): array
    {
        return [
            'trust_score_raw' => 'decimal:4',
            'trust_score_calibrated' => 'decimal:4',
            'volunteer_trust_score' => 'decimal:4',
            'risk_score' => 'decimal:4',
            'anomaly_score' => 'decimal:4',
            'is_anomaly' => 'boolean',
            'risk_flags' => 'array',
            'content_analysis' => 'array',
            'anomaly_types' => 'array',
            'questions_to_verify' => 'array',
            'shap_summary' => 'array',
            'validation_result' => 'array',
            'evaluated_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // Labels constants
    const TRUST_LABELS = [
        'RELIABLE_HIGH' => 'Đáng tin cậy cao',
        'RELIABLE' => 'Đáng tin cậy',
        'NEUTRAL' => 'Trung lập',
        'SUSPICIOUS' => 'Đáng ngờ',
        'SUSPICIOUS_HIGH' => 'Đáng ngờ cao',
    ];

    const RISK_LEVELS = [
        'LOW' => 'Thấp',
        'MEDIUM' => 'Trung bình',
        'HIGH' => 'Cao',
        'CRITICAL' => 'Nghiêm trọng',
    ];

    const RECOMMENDED_ACTIONS = [
        'APPROVE' => 'Duyệt',
        'APPROVE_WITH_NOTE' => 'Duyệt + Ghi chú',
        'REQUEST_ADDITIONAL_INFO' => 'Yêu cầu bổ sung',
        'REJECT' => 'Từ chối',
    ];

    const ACTION_LABELS = [
        'approve' => 'Duyệt',
        'approve_with_note' => 'Duyệt + Ghi chú',
        'request_info' => 'Yêu cầu bổ sung',
        'reject' => 'Từ chối',
    ];

    // Relationships
    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function evaluationLabels()
    {
        return $this->hasMany(EvaluationTrainingLabel::class, 'evaluation_id');
    }

    // Helpers
    public function getTrustLabelTextAttribute(): string
    {
        return self::TRUST_LABELS[$this->trust_label] ?? $this->trust_label ?? 'N/A';
    }

    public function getRiskLevelTextAttribute(): string
    {
        return self::RISK_LEVELS[$this->risk_level] ?? $this->risk_level ?? 'N/A';
    }

    public function getRecommendedActionTextAttribute(): string
    {
        return self::RECOMMENDED_ACTIONS[$this->recommended_action] ?? $this->recommended_action ?? 'N/A';
    }

    public function isMlEvaluated(): bool
    {
        return $this->evaluation_source === 'ml_service';
    }

    public function isFallback(): bool
    {
        return $this->evaluation_source === 'fallback';
    }

    public function hasHighRisk(): bool
    {
        return in_array($this->risk_level, ['HIGH', 'CRITICAL']);
    }

    public function hasFlags(): bool
    {
        return !empty($this->risk_flags);
    }

    public function getFlagCountBySeverity(string $severity): int
    {
        if (empty($this->risk_flags)) {
            return 0;
        }

        return collect($this->risk_flags)->where('severity', $severity)->count();
    }

    public function getCriticalFlagsCount(): int
    {
        return $this->getFlagCountBySeverity('CRITICAL');
    }

    public function getHighFlagsCount(): int
    {
        return $this->getFlagCountBySeverity('HIGH');
    }
}

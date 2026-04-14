<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EvaluationTrainingLabel extends Model
{
    protected $table = 'evaluation_training_labels';

    const CREATED_AT = 'created_at';
    public const UPDATED_AT = null;

    protected $fillable = [
        'chien_dich_id',
        'evaluation_id',
        'kdv_id',
        'kdv_action',
        'kdv_reason',
        'ml_trust_score',
        'ml_risk_level',
        'ml_recommended_action',
        'ml_agree_with_kdv',
        'kdv_satisfied_with_ml',
        'kdv_overridden_ml',
    ];

    protected function casts(): array
    {
        return [
            'ml_trust_score' => 'decimal:4',
            'ml_agree_with_kdv' => 'boolean',
            'kdv_satisfied_with_ml' => 'boolean',
            'kdv_overridden_ml' => 'boolean',
            'created_at' => 'datetime',
        ];
    }

    // KDV action constants
    const KDV_ACTIONS = [
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

    public function evaluation()
    {
        return $this->belongsTo(CampaignEvaluation::class, 'evaluation_id');
    }

    public function kdv()
    {
        return $this->belongsTo(NguoiDung::class, 'kdv_id');
    }

    // Helpers
    public function getKdvActionTextAttribute(): string
    {
        return self::KDV_ACTIONS[$this->kdv_action] ?? $this->kdv_action ?? 'N/A';
    }

    public function isAgreeWithMl(): bool
    {
        return $this->ml_agree_with_kdv === true;
    }

    public function isDisagreeWithMl(): bool
    {
        return $this->ml_agree_with_kdv === false;
    }

    public function isOverridden(): bool
    {
        return $this->kdv_overridden_ml === true;
    }

    public function isSatisfied(): bool
    {
        return $this->kdv_satisfied_with_ml === true;
    }

    public function getConfidenceLevelAttribute(): string
    {
        if ($this->ml_agree_with_kdv === null) {
            return 'N/A';
        }

        return $this->ml_agree_with_kdv ? 'HIGH' : 'LOW';
    }
}

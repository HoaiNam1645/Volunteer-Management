<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KdvFeedback extends Model
{
    protected $table = 'kdv_feedback';

    const CREATED_AT = 'created_at';
    const UPDATED_AT = 'updated_at';

    protected $fillable = [
        'chien_dich_id',
        'nguoi_dung_id',
        'feedback_type',
        'ml_action_correct',
        'final_trust_label_override',
        'kdv_notes',
        'overridden_fields',
        'feedback_at',
    ];

    protected function casts(): array
    {
        return [
            'ml_action_correct' => 'integer',
            'final_trust_label_override' => 'integer',
            'overridden_fields' => 'array',
            'feedback_at' => 'datetime',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    // Feedback type constants
    const TYPE_OVERRIDE = 'override';
    const TYPE_AGREE = 'agree';
    const TYPE_DISAGREE = 'disagree';
    const TYPE_CORRECT_ACTION = 'correct_action';

    const FEEDBACK_TYPES = [
        self::TYPE_OVERRIDE => 'Override ML decision',
        self::TYPE_AGREE => 'Agree with ML',
        self::TYPE_DISAGREE => 'Disagree with ML',
        self::TYPE_CORRECT_ACTION => 'Corrected ML action',
    ];

    // Relationships
    public function chienDich()
    {
        return $this->belongsTo(ChienDich::class, 'chien_dich_id');
    }

    public function nguoiDung()
    {
        return $this->belongsTo(NguoiDung::class, 'nguoi_dung_id');
    }

    public function campaignEvaluation()
    {
        return $this->belongsTo(CampaignEvaluation::class, 'chien_dich_id', 'chien_dich_id');
    }

    // Helpers
    public function isOverride(): bool
    {
        return $this->feedback_type === self::TYPE_OVERRIDE;
    }

    public function isAgree(): bool
    {
        return $this->feedback_type === self::TYPE_AGREE;
    }

    public function isDisagree(): bool
    {
        return $this->feedback_type === self::TYPE_DISAGREE;
    }

    public function isCorrectAction(): bool
    {
        return $this->feedback_type === self::TYPE_CORRECT_ACTION;
    }

    public function mlWasCorrect(): bool
    {
        return $this->ml_action_correct === 1;
    }

    public function mlWasWrong(): bool
    {
        return $this->ml_action_correct === 0;
    }
}

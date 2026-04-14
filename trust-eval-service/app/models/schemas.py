from pydantic import BaseModel, Field
from typing import Optional, Any
from datetime import datetime
from enum import Enum


class EvaluationSource(str, Enum):
    ml_service = "ml_service"
    fallback = "fallback"


class TrustLabel(str, Enum):
    RELIABLE_HIGH = "RELIABLE_HIGH"
    RELIABLE = "RELIABLE"
    NEUTRAL = "NEUTRAL"
    SUSPICIOUS = "SUSPICIOUS"
    SUSPICIOUS_HIGH = "SUSPICIOUS_HIGH"


class RiskLevel(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class Confidence(str, Enum):
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class RecommendedAction(str, Enum):
    APPROVE = "APPROVE"
    APPROVE_WITH_NOTE = "APPROVE_WITH_NOTE"
    REQUEST_ADDITIONAL_INFO = "REQUEST_ADDITIONAL_INFO"
    REJECT = "REJECT"


# ==================== RISK FLAG ====================

class RiskFlag(BaseModel):
    code: str
    severity: str = Field(..., pattern="^(LOW|MEDIUM|HIGH|CRITICAL)$")
    category: str
    message: str
    suggestion: str
    auto_resolvable: bool = False


# ==================== VALIDATION RESULT ====================

class ValidationResult(BaseModel):
    passed: bool
    critical_errors: list[RiskFlag] = Field(default_factory=list)
    warnings: list[RiskFlag] = Field(default_factory=list)


# ==================== TRUST SCORE ====================

class TrustScore(BaseModel):
    raw_score: Optional[float] = None
    calibrated_probability: Optional[float] = None
    label: Optional[str] = None
    confidence: Optional[str] = None


# ==================== VOLUNTEER TRUST SCORE ====================

class VolunteerTrustScore(BaseModel):
    raw_score: Optional[float] = None
    label: Optional[str] = None
    confidence: Optional[str] = None


# ==================== RISK ASSESSMENT ====================

class RiskAssessment(BaseModel):
    overall_risk_level: Optional[str] = None
    risk_score: Optional[float] = None
    flags: list[RiskFlag] = Field(default_factory=list)
    anomaly_score: Optional[float] = None
    is_anomaly: bool = False
    anomaly_types: list[str] = Field(default_factory=list)


# ==================== CONTENT ANALYSIS ====================

class ContentAnalysis(BaseModel):
    text_risk_keyword_count: int = 0
    text_risk_score: Optional[float] = None
    vagueness_score: Optional[float] = None
    safety_description_score: Optional[float] = None
    risk_keywords_found: list[str] = Field(default_factory=list)


# ==================== SHAP EXPLANATION ====================

class SHAPFactor(BaseModel):
    feature: str
    feature_display_name: Optional[str] = None
    contribution: float
    value: Any
    value_display: Optional[str] = None


class SHAPExplanation(BaseModel):
    base_value: float
    prediction: float
    top_positive_factors: list[SHAPFactor] = Field(default_factory=list)
    top_negative_factors: list[SHAPFactor] = Field(default_factory=list)
    feature_importance: list[dict] = Field(default_factory=list)


# ==================== DECISION SUPPORT ====================

class DecisionSupport(BaseModel):
    recommended_action: Optional[str] = None
    confidence: Optional[str] = None
    reason: Optional[str] = None
    questions_to_verify: list[str] = Field(default_factory=list)


# ==================== MODEL INFO ====================

class ModelInfo(BaseModel):
    campaign_model_version: Optional[str] = None
    campaign_training_date: Optional[str] = None
    campaign_training_samples: Optional[int] = None
    campaign_calibration_method: Optional[str] = None
    campaign_mlflow_run_id: Optional[str] = None
    volunteer_model_version: Optional[str] = None
    anomaly_model_version: Optional[str] = None


# ==================== FULL CAMPAIGN EVALUATION RESPONSE ====================

class CampaignEvaluationResponse(BaseModel):
    campaign_id: int
    evaluation_timestamp: str
    evaluation_source: str = "ml_service"

    validation_result: Optional[ValidationResult] = None

    trust_score: Optional[TrustScore] = None
    volunteer_trust_score: Optional[VolunteerTrustScore] = None

    risk_assessment: Optional[RiskAssessment] = None
    content_analysis: Optional[ContentAnalysis] = None

    decision_support: Optional[DecisionSupport] = None
    shap_explanation: Optional[SHAPExplanation] = None

    model_info: Optional[ModelInfo] = None

    class Config:
        populate_by_name = True


# ==================== VOLUNTEER EVALUATION ====================

class ReliabilitySummary(BaseModel):
    total_registrations: int = 0
    cancelled_registrations: int = 0
    cancellation_rate: float = 0.0
    completion_rate: float = 0.0
    avg_rating_received: Optional[float] = None
    rating_count: int = 0


class VolunteerEvaluationResponse(BaseModel):
    volunteer_id: int
    evaluation_timestamp: str
    evaluation_source: str = "ml_service"

    trust_score: Optional[TrustScore] = None
    reliability_summary: Optional[ReliabilitySummary] = None
    behavior_flags: list[RiskFlag] = Field(default_factory=list)
    shap_explanation: Optional[SHAPExplanation] = None

    model_info: Optional[ModelInfo] = None

    class Config:
        populate_by_name = True


# ==================== BATCH EVALUATION ====================

class BatchEvaluationItem(BaseModel):
    campaign_id: int
    status: str = "success"
    evaluation: Optional[CampaignEvaluationResponse] = None
    error: Optional[str] = None


class BatchEvaluationResponse(BaseModel):
    batch_id: str
    submitted_at: str
    completed_at: Optional[str] = None
    total: int
    succeeded: int = 0
    failed: int = 0
    results: list[BatchEvaluationItem] = Field(default_factory=list)


# ==================== HEALTH CHECK ====================

class HealthCheckResponse(BaseModel):
    status: str
    timestamp: str
    database: dict
    mlflow: dict
    models_loaded: dict
    version: str = "0.1.0"


# ==================== MODEL INFO RESPONSE ====================

class ModelInfoResponse(BaseModel):
    campaign_model_version: str
    campaign_training_date: Optional[str] = None
    campaign_training_samples: Optional[int] = None
    campaign_features_count: Optional[int] = None
    volunteer_model_version: str
    anomaly_model_version: str
    mlflow_tracking_uri: str

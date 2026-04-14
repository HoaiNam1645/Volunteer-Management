/**
 * TrustEval Frontend Types
 * Type definitions matching backend schemas (trust-eval-service/app/models/schemas.py)
 */

/**
 * @typedef {'ml_service' | 'fallback'} EvaluationSource
 */

/**
 * @typedef {'RELIABLE_HIGH' | 'RELIABLE' | 'NEUTRAL' | 'SUSPICIOUS' | 'SUSPICIOUS_HIGH'} TrustLabel
 */

/**
 * @typedef {'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'} RiskLevel
 */

/**
 * @typedef {'HIGH' | 'MEDIUM' | 'LOW'} Confidence
 */

/**
 * @typedef {'APPROVE' | 'APPROVE_WITH_NOTE' | 'REQUEST_ADDITIONAL_INFO' | 'REJECT'} RecommendedAction
 */

/**
 * @typedef {Object} RiskFlag
 * @property {string} code
 * @property {RiskLevel} severity
 * @property {string} category
 * @property {string} message
 * @property {string} suggestion
 * @property {boolean} [auto_resolvable]
 */

/**
 * @typedef {Object} ValidationResult
 * @property {boolean} passed
 * @property {RiskFlag[]} [critical_errors]
 * @property {RiskFlag[]} [warnings]
 */

/**
 * @typedef {Object} TrustScore
 * @property {number|null} [raw_score]
 * @property {number|null} [calibrated_probability]
 * @property {TrustLabel|null} [label]
 * @property {Confidence|null} [confidence]
 */

/**
 * @typedef {Object} VolunteerTrustScore
 * @property {number|null} [raw_score]
 * @property {TrustLabel|null} [label]
 * @property {Confidence|null} [confidence]
 */

/**
 * @typedef {Object} RiskAssessment
 * @property {RiskLevel|null} [overall_risk_level]
 * @property {number|null} [risk_score]
 * @property {RiskFlag[]} [flags]
 * @property {number|null} [anomaly_score]
 * @property {boolean} [is_anomaly]
 * @property {string[]} [anomaly_types]
 */

/**
 * @typedef {Object} ContentAnalysis
 * @property {number} [text_risk_keyword_count]
 * @property {number|null} [text_risk_score]
 * @property {number|null} [vagueness_score]
 * @property {number|null} [safety_description_score]
 * @property {string[]} [risk_keywords_found]
 */

/**
 * @typedef {Object} SHAPFactor
 * @property {string} feature
 * @property {string|null} [feature_display_name]
 * @property {number} contribution
 * @property {*} value
 * @property {string|null} [value_display]
 */

/**
 * @typedef {Object} SHAPExplanation
 * @property {number} base_value
 * @property {number} prediction
 * @property {SHAPFactor[]} [top_positive_factors]
 * @property {SHAPFactor[]} [top_negative_factors]
 * @property {Object[]} [feature_importance]
 */

/**
 * @typedef {Object} DecisionSupport
 * @property {RecommendedAction|null} [recommended_action]
 * @property {Confidence|null} [confidence]
 * @property {string|null} [reason]
 * @property {string[]} [questions_to_verify]
 */

/**
 * @typedef {Object} ModelInfo
 * @property {string|null} [campaign_model_version]
 * @property {string|null} [campaign_training_date]
 * @property {number|null} [campaign_training_samples]
 * @property {string|null} [campaign_calibration_method]
 * @property {string|null} [campaign_mlflow_run_id]
 * @property {string|null} [volunteer_model_version]
 * @property {string|null} [anomaly_model_version]
 */

/**
 * @typedef {Object} CampaignEvaluationResponse
 * @property {number} campaign_id
 * @property {string} evaluation_timestamp
 * @property {EvaluationSource} [evaluation_source]
 * @property {ValidationResult|null} [validation_result]
 * @property {TrustScore|null} [trust_score]
 * @property {VolunteerTrustScore|null} [volunteer_trust_score]
 * @property {RiskAssessment|null} [risk_assessment]
 * @property {ContentAnalysis|null} [content_analysis]
 * @property {DecisionSupport|null} [decision_support]
 * @property {SHAPExplanation|null} [shap_explanation]
 * @property {ModelInfo|null} [model_info]
 */

/**
 * @typedef {Object} ReliabilitySummary
 * @property {number} total_registrations
 * @property {number} cancelled_registrations
 * @property {number} cancellation_rate
 * @property {number} completion_rate
 * @property {number|null} [avg_rating_received]
 * @property {number} [rating_count]
 */

/**
 * @typedef {Object} VolunteerEvaluationResponse
 * @property {number} volunteer_id
 * @property {string} evaluation_timestamp
 * @property {EvaluationSource} [evaluation_source]
 * @property {TrustScore|null} [trust_score]
 * @property {ReliabilitySummary|null} [reliability_summary]
 * @property {RiskFlag[]} [behavior_flags]
 * @property {SHAPExplanation|null} [shap_explanation]
 * @property {ModelInfo|null} [model_info]
 */

/**
 * @typedef {Object} TrustEvalStatistics
 * @property {number} total_evaluations
 * @property {number|null} [avg_trust_score]
 * @property {number|null} [avg_risk_score]
 * @property {Object.<RiskLevel, number>} [by_risk_level]
 * @property {Object.<TrustLabel, number>} [by_trust_label]
 * @property {Object.<RecommendedAction, number>} [by_recommended_action]
 * @property {Object.<EvaluationSource, number>} [by_evaluation_source]
 * @property {Array<{
 *   campaign_id: number,
 *   tieu_de: string,
 *   risk_level: RiskLevel,
 *   trust_score: number,
 *   is_anomaly: boolean,
 *   evaluated_at: string
 * }>} [recent_high_risk]
 */

/**
 * @typedef {Object} TrustEvalApiResponse
 * @property {number} status
 * @property {string} message
 * @property {*} [data]
 * @property {number} [campaign_id]
 * @property {number} [volunteer_id]
 */

export default {};

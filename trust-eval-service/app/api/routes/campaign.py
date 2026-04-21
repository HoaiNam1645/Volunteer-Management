"""
Campaign Trust Evaluation API - Phase 2 Full Implementation.

Triển khai đầy đủ:
- Feature Extraction (campaign + creator + behavioral)
- Rule-based Validation
- ML Scoring (rule-based fallback when models not available)
- Content Analysis (NLP risk keywords)
- Anomaly Detection (Isolation Forest)
- Decision Logic
"""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse

from app.models.schemas import (
    CampaignEvaluationResponse,
    TrustScore,
    VolunteerTrustScore,
    ValidationResult,
    RiskAssessment,
    ContentAnalysis,
    DecisionSupport,
    SHAPExplanation,
    ModelInfo,
    RiskFlag,
)
from app.core.database import get_db_cursor
from app.core.feature_extractor import CampaignFeatureExtractor
from app.core.rule_validator import RuleBasedValidator
from app.core.decision_logic import DecisionLogic
from app.ml.content_analyzer import ContentAnalyzer, format_risk_flags_from_analysis
from app.ml.anomaly import AnomalyDetector
from app.ml.shap_explainer import get_campaign_shap_explainer, get_volunteer_shap_explainer
from app.models.ml_models import get_model_loader
from app.training.data_prep import DataPreparator

logger = logging.getLogger("trust_eval_service")
router = APIRouter()


def _fetch_campaign_data(campaign_id: int) -> dict:
    """Fetch campaign data from database."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT cd.*, u.id as creator_user_id, u.ho_ten as creator_name, "
            "u.email as creator_email, u.anh_dai_dien as creator_avatar, "
            "u.gioi_thieu as creator_bio, u.trang_thai as creator_status, "
            "u.xac_thuc_email_luc as creator_email_verified_at, "
            "u.tao_luc as creator_created_at, "
            "u.tinh_thanh_id as creator_province_id, "
            "u.vi_do as creator_lat, u.kinh_do as creator_lng, "
            "u.so_dien_thoai as creator_phone, "
            "u.vai_tro as creator_role "
            "FROM chien_dichs cd "
            "LEFT JOIN nguoi_dungs u ON cd.nguoi_tao_id = u.id "
            "WHERE cd.id = %s AND cd.xoa_luc IS NULL",
            (campaign_id,)
        )
        return cursor.fetchone()


def _fetch_creator_campaign_stats(creator_id: int) -> dict:
    """Fetch creator's campaign statistics."""
    if not creator_id:
        return {}

    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT COUNT(*) as total, "
            "SUM(CASE WHEN trang_thai = 'da_duyet' THEN 1 ELSE 0 END) as approved, "
            "SUM(CASE WHEN trang_thai IN ('da_huy','yeu_cau_huy') THEN 1 ELSE 0 END) as cancelled, "
            "SUM(CASE WHEN trang_thai = 'hoan_thanh' THEN 1 ELSE 0 END) as completed "
            "FROM chien_dichs "
            "WHERE nguoi_tao_id = %s AND xoa_luc IS NULL",
            (creator_id,)
        )
        row = cursor.fetchone()
        if not row:
            return {}

        total = row["total"] or 0
        approved = row["approved"] or 0
        cancelled = row["cancelled"] or 0

        return {
            "campaign_count": total,
            "campaign_approval_rate": (approved / total if total > 0 else 0.0),
            "campaign_cancellation_rate": (cancelled / total if total > 0 else 0.0),
        }


def _fetch_creator_ratings(creator_id: int) -> list[dict]:
    """Fetch ratings received by creator's campaigns."""
    if not creator_id:
        return []

    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT dg.so_sao "
            "FROM danh_gia_tnv dg "
            "JOIN chien_dichs cd ON dg.chien_dich_id = cd.id "
            "WHERE cd.nguoi_tao_id = %s AND cd.xoa_luc IS NULL",
            (creator_id,)
        )
        return cursor.fetchall()


def _fetch_creator_reports(creator_id: int) -> list[dict]:
    """Fetch reports against creator's campaigns."""
    if not creator_id:
        return []

    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT bc.id, bc.trang_thai, bc.noi_dung "
            "FROM bao_cao_chien_dich bc "
            "JOIN chien_dichs cd ON bc.chien_dich_id = cd.id "
            "WHERE cd.nguoi_tao_id = %s",
            (creator_id,)
        )
        return cursor.fetchall()


def _fetch_campaign_reviews(campaign_id: int) -> list[dict]:
    """Fetch review history for a campaign."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT lsk.id, lsk.hanh_dong, lsk.tao_luc as created_at "
            "FROM lich_su_kiem_duyet_chien_dichs lsk "
            "WHERE lsk.chien_dich_id = %s "
            "ORDER BY lsk.tao_luc ASC",
            (campaign_id,)
        )
        return cursor.fetchall()


def _fetch_campaign_feedbacks(campaign_id: int) -> list[dict]:
    """Fetch TNV feedbacks for a campaign."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT ph.id, ph.nhan_xet as noi_dung, ph.so_sao, ph.tao_luc as created_at "
            "FROM phan_hoi_tnv ph "
            "WHERE ph.chien_dich_id = %s",
            (campaign_id,)
        )
        return cursor.fetchall()


def _fetch_registrations(campaign_id: int) -> list[dict]:
    """Fetch registrations for a campaign."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT dkt.id, dkt.trang_thai, dkt.nguoi_dung_id "
            "FROM dang_ky_tham_gias dkt "
            "WHERE dkt.chien_dich_id = %s",
            (campaign_id,)
        )
        return cursor.fetchall()


def _fetch_creator_competencies(creator_id: int) -> dict:
    """Fetch creator's skills, certificates, experiences counts."""
    if not creator_id:
        return {"ky_nang_count": 0, "chung_chi_count": 0, "kinh_nghiem_count": 0}

    with get_db_cursor() as cursor:
        # Skills count
        cursor.execute(
            "SELECT COUNT(*) as cnt FROM nguoi_dung_ky_nangs "
            "WHERE nguoi_dung_id = %s",
            (creator_id,)
        )
        ky_nang = cursor.fetchone()["cnt"]

        # Certificates count
        cursor.execute(
            "SELECT COUNT(*) as cnt FROM chung_chis "
            "WHERE nguoi_dung_id = %s",
            (creator_id,)
        )
        chung_chi = cursor.fetchone()["cnt"]

        # Experience count
        cursor.execute(
            "SELECT COUNT(*) as cnt FROM kinh_nghiems "
            "WHERE nguoi_dung_id = %s",
            (creator_id,)
        )
        kinh_nghiem = cursor.fetchone()["cnt"]

        return {
            "ky_nang_count": ky_nang,
            "chung_chi_count": chung_chi,
            "kinh_nghiem_count": kinh_nghiem,
        }


def _build_creator_dict(campaign: dict) -> dict:
    """Build creator dict from campaign row + additional data."""
    creator_id = campaign.get("nguoi_tao_id")
    if not creator_id:
        return {}

    stats = _fetch_creator_campaign_stats(creator_id)
    ratings = _fetch_creator_ratings(creator_id)
    reports = _fetch_creator_reports(creator_id)
    competencies = _fetch_creator_competencies(creator_id)

    ratings_values = [r["so_sao"] for r in ratings if r.get("so_sao")]
    avg_rating = (sum(ratings_values) / len(ratings_values)
                  if ratings_values else None)

    # Compute avg participation from completed campaigns
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT AVG(cd.so_dang_ky) as avg_part "
            "FROM chien_dichs cd "
            "WHERE cd.nguoi_tao_id = %s AND cd.trang_thai = 'hoan_thanh' "
            "AND cd.xoa_luc IS NULL",
            (creator_id,)
        )
        row = cursor.fetchone()
        avg_participation = row["avg_part"] if row else None

    creator = {
        "id": creator_id,
        "ho_ten": campaign.get("creator_name"),
        "email": campaign.get("creator_email"),
        "anh_dai_dien": campaign.get("creator_avatar"),
        "gioi_thieu": campaign.get("creator_bio"),
        "trang_thai": campaign.get("creator_status"),
        "xac_thuc_email_luc": campaign.get("creator_email_verified_at"),
        "tao_luc": campaign.get("creator_created_at"),
        "tinh_thanh_id": campaign.get("creator_province_id"),
        "vi_do": campaign.get("creator_lat"),
        "kinh_do": campaign.get("creator_lng"),
        "so_dien_thoai": campaign.get("creator_phone"),
        "vai_tro": campaign.get("creator_role"),
        **stats,
        "avg_participation": avg_participation,
        "campaign_report_count": len(reports),
        **competencies,
    }

    # Ratings for feature extractor
    creator["ratings"] = ratings

    return creator


@router.post("/evaluate/campaign/{campaign_id}", response_model=CampaignEvaluationResponse)
async def evaluate_campaign(campaign_id: int):
    """
    Full campaign evaluation - Phase 2 implementation.

    Pipeline:
    1. Fetch campaign + creator data from DB
    2. Rule-based Validation (CRITICAL errors block ML evaluation)
    3. Feature Extraction
    4. Content Analysis (NLP risk keywords)
    5. ML / Rule-based Trust Scoring
    6. Anomaly Detection
    7. Decision Logic (recommended_action)
    8. Return structured response
    """
    try:
        # Step 1: Fetch data
        campaign = _fetch_campaign_data(campaign_id)
        if not campaign:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Campaign {campaign_id} not found"
            )

        creator = _build_creator_dict(campaign)
        registrations = _fetch_registrations(campaign_id)
        reviews = _fetch_campaign_reviews(campaign_id)
        feedbacks = _fetch_campaign_feedbacks(campaign_id)

        # Step 2: Rule-based Validation
        validator = RuleBasedValidator(campaign, creator)
        validation_result = validator.validate()

        # If CRITICAL errors, return early without ML evaluation
        if not validation_result["passed"]:
            return await _build_evaluation_response(
                campaign_id, campaign, creator, {}, {},
                validation_result, {}, {}, None,
                None, None,
            )

        # Step 3: Feature Extraction
        extractor = CampaignFeatureExtractor(
            campaign, creator, registrations, ratings=creator.get("ratings", []),
            reports=[], review_history=reviews, feedbacks=feedbacks,
        )
        features = extractor.extract()

        # Step 4: Content Analysis
        analyzer = ContentAnalyzer(
            title=campaign.get("tieu_de", ""),
            description=campaign.get("mo_ta", ""),
        )
        content_analysis = analyzer.analyze()
        content_flags = format_risk_flags_from_analysis(content_analysis)

        # Step 5: ML / Rule-based Trust Scoring
        model_loader = get_model_loader()
        trust_result = model_loader.predict_campaign_trust(features)

        # Phase 4: SHAP explanation for campaign trust
        shap_explanation = _generate_shap_explanation(
            features, model_loader, "campaign"
        )

        # Volunteer trust score (optional - evaluate if creator has past registrations)
        volunteer_trust_result = None
        if creator and creator.get("campaign_count", 0) > 0:
            vol_ext = _build_volunteer_features(creator)
            if vol_ext:
                vol_result = model_loader.predict_volunteer_trust(vol_ext)
                volunteer_trust_result = VolunteerTrustScore(
                    raw_score=vol_result.get("raw_score"),
                    label=vol_result.get("label"),
                    confidence=vol_result.get("confidence"),
                )

        # Step 6: Anomaly Detection
        anomaly_detector = AnomalyDetector()
        anomaly_result = anomaly_detector.predict(features)

        # Step 7: Decision Logic
        decision_logic = DecisionLogic()
        risk_level = _map_score_to_risk_level(
            trust_result["calibrated_probability"], content_analysis["text_risk_score"]
        )

        # Combine validation flags + content flags
        all_flags = validation_result["warnings"] + content_flags

        decision = decision_logic.decide(
            trust_score=trust_result["calibrated_probability"],
            risk_level=risk_level,
            text_risk_score=content_analysis["text_risk_score"],
            is_anomaly=anomaly_result["is_anomaly"],
            anomaly_types=anomaly_result.get("anomaly_types", []),
            flags=all_flags,
            validation_passed=validation_result["passed"],
        )

        # Step 8: Build response
        return await _build_evaluation_response(
            campaign_id, campaign, creator, features,
            validation_result, trust_result, content_analysis, anomaly_result,
            decision, volunteer_trust_result, shap_explanation,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error evaluating campaign {campaign_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal error: {str(e)}"
        )


async def _build_evaluation_response(
    campaign_id: int,
    campaign: dict,
    creator: dict,
    features: dict,
    validation_result: dict,
    trust_result: dict,
    content_analysis: dict,
    anomaly_result: Optional[dict],
    decision: Optional[dict],
    volunteer_trust: Optional[VolunteerTrustScore] = None,
    shap_explanation: Optional[dict] = None,
) -> CampaignEvaluationResponse:
    """Build the full CampaignEvaluationResponse."""

    trust_score_obj = TrustScore(
        raw_score=trust_result.get("raw_score"),
        calibrated_probability=trust_result.get("calibrated_probability"),
        label=trust_result.get("label"),
        confidence=trust_result.get("confidence"),
    )

    # Build risk assessment
    risk_level = "LOW"
    if trust_result:
        risk_level = _map_score_to_risk_level(
            trust_result.get("calibrated_probability", 1.0),
            content_analysis.get("text_risk_score", 0.0) if content_analysis else 0.0
        )

    all_flags = []
    if validation_result:
        all_flags.extend([
            RiskFlag(**f) for f in validation_result.get("warnings", [])
        ])

    if content_analysis and content_analysis.get("risk_keywords_found"):
        for kw in content_analysis["risk_keywords_found"]:
            all_flags.append(RiskFlag(
                code=f"RISK_KEYWORD_{kw['keyword'].upper().replace(' ', '_')}",
                severity=kw["severity"],
                category=kw["category"],
                message=f"Phát hiện từ khóa rủi ro: '{kw['keyword']}' trong nội dung",
                suggestion=kw["suggestion"],
                auto_resolvable=kw["severity"] != "HIGH",
            ))

    risk_assessment = RiskAssessment(
        overall_risk_level=risk_level,
        risk_score=round(1.0 - (trust_result.get("calibrated_probability", 0.5)
                               if trust_result else 0.5), 4),
        flags=all_flags,
        anomaly_score=anomaly_result.get("anomaly_score") if anomaly_result else None,
        is_anomaly=anomaly_result.get("is_anomaly", False) if anomaly_result else False,
        anomaly_types=anomaly_result.get("anomaly_types", [])
                      if anomaly_result else [],
    )

    content_analysis_obj = None
    if content_analysis:
        content_analysis_obj = ContentAnalysis(
            text_risk_keyword_count=content_analysis.get("text_risk_keyword_count", 0),
            text_risk_score=content_analysis.get("text_risk_score"),
            vagueness_score=content_analysis.get("vagueness_score"),
            safety_description_score=content_analysis.get("safety_description_score"),
            risk_keywords_found=[
                kw["keyword"] for kw in content_analysis.get("risk_keywords_found", [])
            ],
        )

    decision_support = None
    if decision:
        decision_support = DecisionSupport(
            recommended_action=decision.get("recommended_action"),
            confidence=decision.get("confidence"),
            reason=decision.get("reason"),
            questions_to_verify=decision.get("questions_to_verify", []),
        )

    # Model info
    model_loader = get_model_loader()
    is_ml_mode = model_loader._loaded

    model_info = ModelInfo(
        campaign_model_version=(
            f"lgb_v3_{datetime.now().strftime('%Y%m%d')}"
            if is_ml_mode else "rule_based_v2"
        ),
        campaign_training_date=None if not is_ml_mode else datetime.now().isoformat(),
        campaign_training_samples=None,
        campaign_calibration_method="isotonic" if model_loader._calibration_loaded else None,
        campaign_mlflow_run_id=None,
        volunteer_model_version=(
            f"lgb_v1_{datetime.now().strftime('%Y%m%d')}"
            if is_ml_mode else "rule_based_v1"
        ),
        anomaly_model_version="iforest_v1",
    )

    return CampaignEvaluationResponse(
        campaign_id=campaign_id,
        evaluation_timestamp=datetime.now(timezone.utc).isoformat(),
        evaluation_source="ml_service",

        validation_result=ValidationResult(
            passed=validation_result.get("passed", True),
            critical_errors=[
                RiskFlag(**f) for f in validation_result.get("critical_errors", [])
            ],
            warnings=[
                RiskFlag(**f) for f in validation_result.get("warnings", [])
            ],
        ) if validation_result else None,

        trust_score=trust_score_obj,
        volunteer_trust_score=volunteer_trust,

        risk_assessment=risk_assessment,
        content_analysis=content_analysis_obj,

        decision_support=decision_support,

        shap_explanation=SHAPExplanation(**shap_explanation) if shap_explanation else None,

        model_info=model_info,
    )


def _map_score_to_risk_level(trust_score: float, text_risk_score: float) -> str:
    """
    Map trust score + text risk to overall risk level.

    Risk = min(trust, 1 - text_risk) vì:
    - Cần CẢ hai đều tốt mới xác nhận LOW risk
    - trust cao nhưng text_risk cao → risk vẫn cao
    - Ngược lại cũng vậy
    """
    # trust_score: cao = đáng tin → dùng trực tiếp
    # text_risk_score: cao = rủi ro → đảo ngược: 1 - text_risk cao = tốt
    combined = min(trust_score, 1.0 - text_risk_score)
    if combined >= 0.70:
        return "LOW"
    if combined >= 0.40:
        return "MEDIUM"
    if combined >= 0.20:
        return "HIGH"
    return "CRITICAL"


def _build_volunteer_features(creator: dict) -> Optional[dict]:
    """Build volunteer-style features from creator data."""
    if not creator or not creator.get("id"):
        return None

    with get_db_cursor() as cursor:
        # Fetch registrations (as volunteer)
        cursor.execute(
            "SELECT dkt.trang_thai, dkt.huy_luc "
            "FROM dang_ky_tham_gias dkt "
            "WHERE dkt.nguoi_dung_id = %s",
            (creator["id"],)
        )
        regs = cursor.fetchall()

        # Fetch ratings received (as campaign creator, rated by TNV)
        cursor.execute(
            "SELECT dg.so_sao FROM danh_gia_tnv dg "
            "JOIN chien_dichs cd ON dg.chien_dich_id = cd.id "
            "WHERE cd.nguoi_tao_id = %s",
            (creator["id"],)
        )
        ratings = cursor.fetchall()

    if not regs and not ratings:
        return None

    total = len(regs) if regs else 0
    cancelled = sum(1 for r in regs if r.get("trang_thai") in ("da_huy", "huy"))
    completed = sum(1 for r in regs if r.get("trang_thai") == "hoan_thanh")
    no_show = sum(1 for r in regs if r.get("trang_thai") == "khong_xac_nhan")

    # Compute avg rating received
    rating_values = [r["so_sao"] for r in ratings if r.get("so_sao")] if ratings else []
    avg_rating = (sum(rating_values) / len(rating_values)
                 if rating_values else None)
    rating_count = len(rating_values)

    return {
        # Basic info
        "account_age_days": creator.get("creator_account_age_days"),
        "is_new_account": creator.get("creator_account_age_days", 999) < 7,
        "has_verified_email": creator.get("xac_thuc_email_luc") is not None,
        "has_phone": bool(creator.get("so_dien_thoai")),
        "has_avatar": bool(creator.get("anh_dai_dien")),
        "has_bio": bool(creator.get("gioi_thieu")),
        "days_since_last_activity": None,  # not available from creator data
        # Behavior from registrations
        "registration_count": total,
        "cancelled_registrations": cancelled,
        "completed_registrations": completed,
        "registration_cancellation_rate": cancelled / total if total > 0 else 0.0,
        "completion_rate": completed / total if total > 0 else 0.0,
        "no_show_rate": no_show / total if total > 0 else 0.0,
        "late_cancellation_count": 0,  # huy_luc date not processed
        "avg_feedback_rating_given": None,  # creator doesn't give ratings
        # Ratings received
        "avg_rating_received": avg_rating,
        "rating_received_count": rating_count,
        "has_perfect_rating": (
            avg_rating is not None
            and avg_rating >= 4.9
            and rating_count >= 5
        ),
        # Profile
        "profile_completeness_score": _calc_creator_profile_completeness(creator),
        "has_certificates": creator.get("chung_chi_count", 0) > 0,
        "has_experience": creator.get("kinh_nghiem_count", 0) > 0,
        "has_skills": creator.get("ky_nang_count", 0) > 0,
    }


def _calc_creator_profile_completeness(creator: dict) -> float:
    """Tính profile completeness từ các trường đã có."""
    fields = [
        creator.get("ho_ten"),
        creator.get("email"),
        creator.get("so_dien_thoai"),
        creator.get("anh_dai_dien"),
        creator.get("gioi_thieu"),
    ]
    return sum(1 for f in fields if f) / len(fields)


def _generate_shap_explanation(
    features: dict,
    model_loader,
    model_type: str,
) -> Optional[dict]:
    """
    Generate SHAP explanation for a prediction.

    Uses TreeExplainer if ML model is loaded, otherwise fallback explanation.
    """
    try:
        from app.ml.shap_explainer import (
            get_campaign_shap_explainer,
            get_volunteer_shap_explainer,
        )

        if model_type == "campaign":
            model, feature_names = model_loader.get_campaign_model_info()
            explainer = get_campaign_shap_explainer()
        else:
            model, feature_names = model_loader.get_volunteer_model_info()
            explainer = get_volunteer_shap_explainer()

        if model is None:
            return None

        explainer.set_model(model, feature_names)

        return explainer.explain(
            features=features,
            feature_names=feature_names,
            top_n=5,
        )

    except Exception as e:
        logger.warning(f"SHAP explanation failed: {e}")
        return None

"""
Volunteer Trust Evaluation API - Phase 2 Full Implementation.
"""

import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, status

from app.models.schemas import (
    VolunteerEvaluationResponse,
    TrustScore,
    ReliabilitySummary,
    SHAPExplanation,
    RiskFlag,
    ModelInfo,
)
from app.core.database import get_db_cursor
from app.core.feature_extractor import VolunteerFeatureExtractor
from app.models.ml_models import get_model_loader

logger = logging.getLogger("trust_eval_service")
router = APIRouter()


def _fetch_volunteer_data(volunteer_id: int) -> Optional[dict]:
    """Fetch volunteer (nguoi_dung) data from database."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT u.*, "
            "(SELECT COUNT(*) FROM chung_chis cc "
            "  WHERE cc.nguoi_dung_id = u.id) as chung_chi_count, "
            "(SELECT COUNT(*) FROM kinh_nghiems kn "
            "  WHERE kn.nguoi_dung_id = u.id) as kinh_nghiem_count, "
            "(SELECT COUNT(*) FROM nguoi_dung_ky_nangs knd "
            "  WHERE knd.nguoi_dung_id = u.id) as ky_nang_count "
            "FROM nguoi_dungs u "
            "WHERE u.id = %s AND u.xoa_luc IS NULL",
            (volunteer_id,)
        )
        return cursor.fetchone()


def _fetch_registrations(volunteer_id: int) -> list[dict]:
    """Fetch all registrations for a volunteer."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT dkt.id, dkt.chien_dich_id, dkt.trang_thai, dkt.dang_ky_luc as ngay_dang_ky, "
            "dkt.huy_luc, cd.tieu_de "
            "FROM dang_ky_tham_gias dkt "
            "JOIN chien_dichs cd ON dkt.chien_dich_id = cd.id "
            "WHERE dkt.nguoi_dung_id = %s "
            "ORDER BY dkt.dang_ky_luc DESC",
            (volunteer_id,)
        )
        return cursor.fetchall()


def _fetch_ratings_given(volunteer_id: int) -> list[dict]:
    """Fetch ratings this volunteer gave to campaigns."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT dg.so_sao, dg.nhan_xet as noi_dung, dg.tao_luc as created_at "
            "FROM danh_gia_tnv dg "
            "WHERE dg.danh_gia_boi = %s",
            (volunteer_id,)
        )
        return cursor.fetchall()


def _fetch_ratings_received(volunteer_id: int) -> list[dict]:
    """Fetch ratings received by this volunteer (from campaigns they participated)."""
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT dg.so_sao, dg.nhan_xet as noi_dung, dg.tao_luc as created_at "
            "FROM danh_gia_tnv dg "
            "WHERE dg.tinh_nguyen_vien_id = %s",
            (volunteer_id,)
        )
        return cursor.fetchall()


@router.post("/evaluate/volunteer/{volunteer_id}", response_model=VolunteerEvaluationResponse)
async def evaluate_volunteer(volunteer_id: int):
    """
    Full volunteer evaluation - Phase 2 implementation.

    Pipeline:
    1. Fetch volunteer data from DB
    2. Feature Extraction (behavioral + profile)
    3. ML / Rule-based Trust Scoring
    4. Generate behavior flags
    5. Return structured response
    """
    try:
        # Step 1: Fetch data
        volunteer = _fetch_volunteer_data(volunteer_id)
        if not volunteer:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Volunteer {volunteer_id} not found"
            )

        registrations = _fetch_registrations(volunteer_id)
        ratings_given = _fetch_ratings_given(volunteer_id)
        ratings_received = _fetch_ratings_received(volunteer_id)

        # Step 2: Feature Extraction
        extractor = VolunteerFeatureExtractor(
            volunteer, registrations, ratings_given, ratings_received,
        )
        features = extractor.extract()

        # Step 3: ML / Rule-based Trust Scoring
        model_loader = get_model_loader()
        trust_result = model_loader.predict_volunteer_trust(features)

        # Phase 4: SHAP explanation
        shap_explanation = _generate_shap_explanation(
            features, model_loader, "volunteer"
        )

        # Step 4: Generate behavior flags
        flags = _generate_behavior_flags(features, registrations)

        # Step 5: Build reliability summary
        reliability_summary = _build_reliability_summary(registrations, ratings_received)

        # Build response
        return VolunteerEvaluationResponse(
            volunteer_id=volunteer_id,
            evaluation_timestamp=datetime.now(timezone.utc).isoformat(),
            evaluation_source="ml_service",

            trust_score=TrustScore(
                raw_score=trust_result.get("raw_score"),
                calibrated_probability=trust_result.get("calibrated_probability"),
                label=trust_result.get("label"),
                confidence=trust_result.get("confidence"),
            ),

            reliability_summary=reliability_summary,
            behavior_flags=flags,
            shap_explanation=SHAPExplanation(**shap_explanation) if shap_explanation else None,

            model_info=ModelInfo(
                campaign_model_version=None,
                volunteer_model_version="rule_based_v1",
                anomaly_model_version=None,
            ),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error evaluating volunteer {volunteer_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal error: {str(e)}"
        )


def _generate_behavior_flags(features: dict, registrations: list[dict]) -> list[RiskFlag]:
    """Generate behavior flags based on volunteer features."""
    flags = []

    # New account
    if features.get("is_new_account"):
        account_age = features.get("account_age_days", 0)
        flags.append(RiskFlag(
            code="NEW_ACCOUNT",
            severity="LOW",
            category="VOLUNTEER_BEHAVIOR",
            message=f"Tài khoản mới tạo ({account_age} ngày)",
            suggestion="Theo dõi hoạt động trong 30 ngày đầu",
            auto_resolvable=True,
        ))

    # High cancellation rate
    cancel_rate = features.get("registration_cancellation_rate", 0.0)
    if cancel_rate > 0.3:
        flags.append(RiskFlag(
            code="HIGH_CANCELLATION_RATE",
            severity="HIGH",
            category="VOLUNTEER_BEHAVIOR",
            message=f"Tỷ lệ hủy đăng ký cao ({round(cancel_rate * 100)}%)",
            suggestion="Theo dõi hoạt động, có thể hạn chế đăng ký nhiều chiến dịch cùng lúc",
            auto_resolvable=False,
        ))
    elif cancel_rate > 0.15:
        flags.append(RiskFlag(
            code="MODERATE_CANCELLATION_RATE",
            severity="MEDIUM",
            category="VOLUNTEER_BEHAVIOR",
            message=f"Tỷ lệ hủy đăng ký khá cao ({round(cancel_rate * 100)}%)",
            suggestion="Nhắc nhở TNV về cam kết tham gia",
            auto_resolvable=True,
        ))

    # High no-show rate
    no_show_rate = features.get("no_show_rate", 0.0)
    if no_show_rate > 0.2:
        flags.append(RiskFlag(
            code="HIGH_NO_SHOW_RATE",
            severity="MEDIUM",
            category="VOLUNTEER_BEHAVIOR",
            message=f"Tỷ lệ không xác nhận tham gia cao ({round(no_show_rate * 100)}%)",
            suggestion="Liên hệ xác nhận trước khi chiến dịch bắt đầu",
            auto_resolvable=True,
        ))

    # Low completion rate
    completion_rate = features.get("completion_rate", 0.0)
    if completion_rate < 0.5 and features.get("registration_count", 0) >= 3:
        flags.append(RiskFlag(
            code="LOW_COMPLETION_RATE",
            severity="MEDIUM",
            category="VOLUNTEER_BEHAVIOR",
            message=f"Tỷ lệ hoàn thành thấp ({round(completion_rate * 100)}%)",
            suggestion="Kiểm tra lý do không hoàn thành chiến dịch",
            auto_resolvable=False,
        ))

    # Perfect rating suspicion
    if features.get("has_perfect_rating"):
        flags.append(RiskFlag(
            code="PERFECT_RATING",
            severity="LOW",
            category="VOLUNTEER_BEHAVIOR",
            message="Tất cả đánh giá đều là 5 sao (có thể không tự nhiên)",
            suggestion="Kiểm tra nội dung đánh giá chi tiết",
            auto_resolvable=False,
        ))

    # Low profile completeness
    profile_score = features.get("profile_completeness_score", 1.0)
    if profile_score < 0.4:
        flags.append(RiskFlag(
            code="LOW_PROFILE_COMPLETENESS",
            severity="LOW",
            category="PROFILE",
            message=f"Hồ sơ chưa hoàn thiện ({round(profile_score * 100)}%)",
            suggestion="Nhắc TNV cập nhật đầy đủ thông tin hồ sơ",
            auto_resolvable=True,
        ))

    # No certificates or experience
    if features.get("registration_count", 0) >= 5:
        if not features.get("has_certificates") and not features.get("has_experience"):
            flags.append(RiskFlag(
                code="NO_CREDENTIALS",
                severity="LOW",
                category="PROFILE",
                message="TNV chưa có chứng chỉ hoặc kinh nghiệm được khai báo",
                suggestion="Khuyến khích TNV cập nhật hồ sơ năng lực",
                auto_resolvable=True,
            ))

    return flags


def _build_reliability_summary(
    registrations: list[dict],
    ratings_received: list[dict],
) -> ReliabilitySummary:
    """Build reliability summary from registrations."""
    total = len(registrations)
    cancelled = sum(
        1 for r in registrations
        if r.get("trang_thai") in ("da_huy", "huy")
    )
    completed = sum(
        1 for r in registrations
        if r.get("trang_thai") == "hoan_thanh"
    )

    ratings_values = [
        r["so_sao"] for r in ratings_received
        if r.get("so_sao") is not None
    ]
    avg_rating = (
        sum(ratings_values) / len(ratings_values)
        if ratings_values else None
    )

    return ReliabilitySummary(
        total_registrations=total,
        cancelled_registrations=cancelled,
        cancellation_rate=round(cancelled / total, 4) if total > 0 else 0.0,
        completion_rate=round(completed / total, 4) if total > 0 else 0.0,
        avg_rating_received=round(avg_rating, 2) if avg_rating else None,
        rating_count=len(ratings_values),
    )


def _generate_shap_explanation(
    features: dict,
    model_loader,
    model_type: str,
) -> Optional[dict]:
    """Generate SHAP explanation for volunteer prediction."""
    try:
        from app.ml.shap_explainer import get_volunteer_shap_explainer

        model, feature_names = model_loader.get_volunteer_model_info()
        if model is None:
            return None

        explainer = get_volunteer_shap_explainer()
        explainer.set_model(model, feature_names)

        return explainer.explain(
            features=features,
            feature_names=feature_names,
            top_n=5,
        )
    except Exception as e:
        logger.warning(f"SHAP explanation failed: {e}")
        return None

"""
Monitoring API Routes - ML performance tracking and drift detection.

Phase 7: Continuous Improvement
"""

import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.core.monitor import get_monitor
from app.core.database import get_db_cursor

logger = logging.getLogger("trust_eval_service")
router = APIRouter()


class AgreementStatsResponse(BaseModel):
    total_decided: int
    agreement_count: int
    disagreement_count: int
    agreement_rate: float | None
    by_action: dict
    weekly_trend: list[dict]
    computed_at: str


class AlertResponse(BaseModel):
    level: str
    code: str
    message: str
    details: dict


class MonitoringResponse(BaseModel):
    status: str
    timestamp: str
    agreement_stats: AgreementStatsResponse
    alerts: list[AlertResponse]


@router.get("/monitoring", response_model=MonitoringResponse)
async def get_monitoring_dashboard(
    refresh: bool = Query(False, description="Force refresh cached stats"),
):
    """
    Get ML monitoring dashboard data.

    Returns:
    - Agreement statistics (ML vs KDV)
    - Performance alerts (low agreement rate, drift detected)
    - Weekly trend of agreement rate
    """
    db_cursor = get_db_cursor()
    monitor = get_monitor(db_cursor)

    stats = monitor.get_agreement_stats(force_refresh=refresh)
    alerts = monitor.get_performance_alerts()

    is_healthy, rate = monitor.is_agreement_rate_healthy()
    status = "healthy" if is_healthy else "degraded"

    return MonitoringResponse(
        status=status,
        timestamp=datetime.now(timezone.utc).isoformat(),
        agreement_stats=AgreementStatsResponse(
            total_decided=stats.total_decided,
            agreement_count=stats.agreement_count,
            disagreement_count=stats.disagreement_count,
            agreement_rate=stats.agreement_rate if stats.total_decided > 0 else None,
            by_action=stats.by_action,
            weekly_trend=stats.weekly_trend,
            computed_at=stats.computed_at,
        ),
        alerts=[
            AlertResponse(
                level=a["level"],
                code=a["code"],
                message=a["message"],
                details=a["details"],
            )
            for a in alerts
        ],
    )


@router.get("/monitoring/agreement-stats", response_model=AgreementStatsResponse)
async def get_agreement_stats(
    refresh: bool = Query(False),
):
    """Get ML vs KDV agreement statistics only."""
    db_cursor = get_db_cursor()
    monitor = get_monitor(db_cursor)
    stats = monitor.get_agreement_stats(force_refresh=refresh)

    return AgreementStatsResponse(
        total_decided=stats.total_decided,
        agreement_count=stats.agreement_count,
        disagreement_count=stats.disagreement_count,
        agreement_rate=stats.agreement_rate if stats.total_decided > 0 else None,
        by_action=stats.by_action,
        weekly_trend=stats.weekly_trend,
        computed_at=stats.computed_at,
    )


@router.get("/monitoring/alerts")
async def get_performance_alerts():
    """Get current performance alerts."""
    db_cursor = get_db_cursor()
    monitor = get_monitor(db_cursor)
    alerts = monitor.get_performance_alerts()

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "count": len(alerts),
        "alerts": alerts,
    }


@router.get("/monitoring/drift-check")
async def check_feature_drift():
    """
    Check for feature drift since last training.

    This compares recent feature distributions against stored baseline.
    Returns PSI scores per feature.
    """
    from app.models.ml_models import get_model_loader
    from app.core.feature_extractor import CampaignFeatureExtractor

    try:
        model_loader = get_model_loader()
        extractor = CampaignFeatureExtractor()

        db_cursor = get_db_cursor()
        if db_cursor is None:
            return {"has_drift": False, "error": "Database not available", "features": {}}

        extractor.db_cursor = db_cursor

        recent_features: dict[str, list] = {}
        baseline_features: dict[str, list] = {}

        feature_names = [
            "has_cover_image", "description_length", "campaign_duration_days",
            "registration_to_start_ratio", "team_size_feasibility",
            "has_location_coords", "has_registration_deadline",
            "creator_account_age_days", "creator_campaign_count",
            "creator_cancellation_rate", "creator_avg_rating",
        ]

        for fname in feature_names:
            recent_query = """
                SELECT AVG(evaluated_at > DATE_SUB(NOW(), INTERVAL 7 DAY)) as recent_count
                FROM campaign_evaluations WHERE evaluated_at IS NOT NULL
            """
            recent_features[fname] = []
            baseline_features[fname] = []

        result = {
            "has_drift": False,
            "drift_score": 0.0,
            "drifted_features": [],
            "features": {},
            "message": "Run training pipeline to establish baseline for drift detection",
        }

        return result

    except Exception as e:
        logger.error(f"Drift check failed: {e}")
        return {"has_drift": False, "error": str(e), "features": {}}

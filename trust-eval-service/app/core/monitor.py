"""
ML Monitoring Service - Track model performance, agreement rates, and drift.

Phase 7: Continuous Improvement

Responsibilities:
- Track ML vs KDV agreement rate over time
- Detect model drift via feature distribution changes
- Compute and cache per-action agreement rates
- Generate alerts when agreement rate drops below threshold
- Provide API endpoint for monitoring dashboard
"""

import logging
from datetime import datetime, timezone, timedelta
from typing import Optional
from dataclasses import dataclass, field

logger = logging.getLogger("trust_eval_service")


@dataclass
class AgreementStats:
    total_decided: int = 0
    agreement_count: int = 0
    disagreement_count: int = 0
    agreement_rate: float = 0.0
    by_action: dict = field(default_factory=dict)
    weekly_trend: list[dict] = field(default_factory=list)
    computed_at: str = ""


@dataclass
class DriftDetectionResult:
    has_drift: bool = False
    drift_score: float = 0.0
    drifted_features: list[str] = field(default_factory=list)
    details: dict = field(default_factory=dict)


class MLMonitor:
    """
    Monitor ML model performance and detect data/concept drift.

    Tracks:
    - ML vs KDV agreement rate by action type
    - Weekly trend of agreement rate
    - Feature distribution drift (PSI-based)
    - Model calibration quality over time
    """

    AGREEMENT_RATE_THRESHOLD = 0.80
    DRIFT_PSI_THRESHOLD = 0.20

    def __init__(self, db_cursor=None):
        self.db_cursor = db_cursor
        self._stats_cache: Optional[AgreementStats] = None
        self._stats_cache_at: Optional[datetime] = None
        self._stats_cache_ttl_seconds = 300

    def get_agreement_stats(self, force_refresh: bool = False) -> AgreementStats:
        """Compute ML vs KDV agreement statistics."""
        if (
            not force_refresh
            and self._stats_cache is not None
            and self._stats_cache_at is not None
            and (datetime.now(timezone.utc) - self._stats_cache_at).total_seconds() < self._stats_cache_ttl_seconds
        ):
            return self._stats_cache

        stats = self._compute_agreement_stats()
        self._stats_cache = stats
        self._stats_cache_at = datetime.now(timezone.utc)
        return stats

    def _compute_agreement_stats(self) -> AgreementStats:
        """Query database for agreement statistics."""
        if self.db_cursor is None:
            return AgreementStats(computed_at=datetime.now(timezone.utc).isoformat())

        stats = AgreementStats(computed_at=datetime.now(timezone.utc).isoformat())

        query = """
            SELECT
                COUNT(*) as total_decided,
                SUM(CASE WHEN ml_agreement = 1 THEN 1 ELSE 0 END) as agreement_count,
                SUM(CASE WHEN ml_agreement = 0 THEN 1 ELSE 0 END) as disagreement_count
            FROM campaign_evaluations
            WHERE ml_agreement IS NOT NULL
        """
        try:
            self.db_cursor.execute(query)
            row = self.db_cursor.fetchone()
            if row:
                stats.total_decided = int(row[0] or 0)
                stats.agreement_count = int(row[1] or 0)
                stats.disagreement_count = int(row[2] or 0)
                if stats.total_decided > 0:
                    stats.agreement_rate = round(stats.agreement_count / stats.total_decided, 4)
        except Exception as e:
            logger.warning(f"Failed to compute agreement stats: {e}")

        by_action_query = """
            SELECT
                recommended_action,
                ml_agreement,
                COUNT(*) as count
            FROM campaign_evaluations
            WHERE ml_agreement IS NOT NULL
            GROUP BY recommended_action, ml_agreement
            ORDER BY recommended_action
        """
        try:
            self.db_cursor.execute(by_action_query)
            rows = self.db_cursor.fetchall()
            action_map: dict = {}
            for row in rows:
                action = row[0] or "UNKNOWN"
                agreed = bool(row[1])
                count = int(row[2] or 0)
                if action not in action_map:
                    action_map[action] = {"total": 0, "agreed": 0, "disagreed": 0}
                action_map[action]["total"] += count
                if agreed:
                    action_map[action]["agreed"] += count
                else:
                    action_map[action]["disagreed"] += count
            stats.by_action = action_map
        except Exception as e:
            logger.warning(f"Failed to compute by-action stats: {e}")

        weekly_query = """
            SELECT
                DATE(kdv_decided_at) as date,
                COUNT(*) as total,
                SUM(CASE WHEN ml_agreement = 1 THEN 1 ELSE 0 END) as agreed
            FROM campaign_evaluations
            WHERE ml_agreement IS NOT NULL
              AND kdv_decided_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY DATE(kdv_decided_at)
            ORDER BY date
        """
        try:
            self.db_cursor.execute(weekly_query)
            rows = self.db_cursor.fetchall()
            stats.weekly_trend = [
                {
                    "date": str(row[0]),
                    "total": int(row[1] or 0),
                    "agreed": int(row[2] or 0),
                    "rate": round(int(row[2] or 0) / int(row[1] or 1), 4),
                }
                for row in rows
            ]
        except Exception as e:
            logger.warning(f"Failed to compute weekly trend: {e}")

        return stats

    def is_agreement_rate_healthy(self) -> tuple[bool, Optional[float]]:
        """Check if current agreement rate is above threshold."""
        stats = self.get_agreement_stats()
        if stats.total_decided < 10:
            return True, None
        healthy = stats.agreement_rate >= self.AGREEMENT_RATE_THRESHOLD
        return healthy, stats.agreement_rate

    def get_performance_alerts(self) -> list[dict]:
        """Generate alerts for performance issues."""
        alerts = []
        stats = self.get_agreement_stats()

        if stats.total_decided >= 10:
            healthy, rate = self.is_agreement_rate_healthy()
            if not healthy:
                alerts.append({
                    "level": "warning",
                    "code": "LOW_AGREEMENT_RATE",
                    "message": f"ML agreement rate ({rate:.1%}) below threshold ({self.AGREEMENT_RATE_THRESHOLD:.1%})",
                    "details": {
                        "current_rate": rate,
                        "threshold": self.AGREEMENT_RATE_THRESHOLD,
                        "total_decided": stats.total_decided,
                    },
                })

            for action, data in stats.by_action.items():
                if data["total"] >= 5:
                    action_rate = data["agreed"] / data["total"]
                    if action_rate < 0.70:
                        alerts.append({
                            "level": "warning",
                            "code": f"LOW_AGREEMENT_FOR_ACTION_{action}",
                            "message": f"Agreement rate for action '{action}' is {action_rate:.1%} ({data['agreed']}/{data['total']})",
                            "details": data,
                        })

        if stats.weekly_trend:
            recent = stats.weekly_trend[-3:]
            if len(recent) >= 2:
                first_rate = recent[0].get("rate", 0)
                last_rate = recent[-1].get("rate", 0)
                drop = first_rate - last_rate
                if drop > 0.10 and last_rate < self.AGREEMENT_RATE_THRESHOLD:
                    alerts.append({
                        "level": "critical",
                        "code": "AGREEMENT_RATE_DROPPING",
                        "message": f"Agreement rate dropped {drop:.1%} over last {len(recent)} days",
                        "details": {"trend": recent},
                    })

        return alerts

    def compute_feature_drift(self, feature_name: str, current_values: list, baseline_values: list) -> float:
        """
        Compute Population Stability Index (PSI) for a feature.

        PSI < 0.1: no significant drift
        PSI 0.1-0.2: moderate drift, monitor
        PSI > 0.2: significant drift, investigate
        """
        import numpy as np

        def _psi(expected: np.ndarray, actual: np.ndarray, buckets: int = 10) -> float:
            if len(expected) == 0 or len(actual) == 0:
                return 0.0

            breakpoints = np.percentile(expected, np.linspace(0, 100, buckets + 1))
            breakpoints[0] = -float("inf")
            breakpoints[-1] = float("inf")

            expected_perc = np.histogram(expected, breakpoints)[0] / len(expected)
            actual_perc = np.histogram(actual, breakpoints)[0] / len(actual)

            expected_perc = np.clip(expected_perc, 0.0001, None)
            actual_perc = np.clip(actual_perc, 0.0001, None)

            psi_value = np.sum((actual_perc - expected_perc) * np.log(actual_perc / expected_perc))
            return float(psi_value)

        try:
            import numpy as np
            current_arr = np.array(current_values, dtype=float)
            baseline_arr = np.array(baseline_values, dtype=float)

            current_arr = current_arr[~np.isnan(current_arr)]
            baseline_arr = baseline_arr[~np.isnan(baseline_arr)]

            if len(current_arr) < 10 or len(baseline_arr) < 10:
                return 0.0

            return _psi(baseline_arr, current_arr)
        except Exception as e:
            logger.warning(f"Failed to compute PSI for {feature_name}: {e}")
            return 0.0

    def detect_model_drift(self, recent_features: dict[str, list], baseline_features: dict[str, list]) -> DriftDetectionResult:
        """Detect feature drift across multiple features."""
        result = DriftDetectionResult()
        drifted_features = []

        for feature_name in recent_features:
            if feature_name not in baseline_features:
                continue

            psi = self.compute_feature_drift(
                feature_name,
                recent_features[feature_name],
                baseline_features[feature_name],
            )

            if psi > self.DRIFT_PSI_THRESHOLD:
                drifted_features.append(feature_name)
                logger.warning(f"Feature drift detected for '{feature_name}': PSI={psi:.4f}")

        result.drifted_features = drifted_features
        result.has_drift = len(drifted_features) > 0
        result.drift_score = sum(
            self.compute_feature_drift(
                recent_features[f],
                baseline_features[f],
            )
            for f in drifted_features
        ) / max(len(drifted_features), 1)

        result.details = {
            f: round(self.compute_feature_drift(recent_features[f], baseline_features[f]), 4)
            for f in drifted_features
        }

        return result


def get_monitor(db_cursor=None) -> MLMonitor:
    return MLMonitor(db_cursor)

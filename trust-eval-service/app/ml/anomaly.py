"""
Anomaly Detection using Isolation Forest.

Phát hiện các mẫu hành vi bất thường mà luật cứng và model supervised khó phát hiện.

Configuration:
- contamination: 0.05 (5% outlier dự kiến)
- n_estimators: 200
- max_samples: 'auto'
- random_state: 42
"""

import logging
from typing import Optional

import numpy as np

logger = logging.getLogger("trust_eval_service")


class AnomalyDetector:
    """
    Phát hiện bất thường trên campaign behavioral features.

    Sử dụng Isolation Forest để nhận diện các mẫu hành vi bất thường.
    """

    # Feature names used for anomaly detection
    ANOMALY_FEATURES = [
        "creator_account_age_days",
        "creator_campaign_count",
        "creator_previous_cancellation_rate",
        "creator_report_count",
        "days_until_start",
        "registration_ratio",
        "confirmation_ratio",
        "is_created_during_office_hours",
        "is_created_on_weekend",
        "is_created_late_night",
        "content_edit_frequency",
        "campaign_duration_days",
        "registration_window_days",
    ]

    def __init__(self, contamination: float = 0.05, random_state: int = 42):
        self.contamination = contamination
        self.random_state = random_state
        self._model = None
        self._feature_means: Optional[dict] = None
        self._feature_stds: Optional[dict] = None
        self._is_trained = False

    def train(self, features_list: list[dict]) -> bool:
        """
        Train the anomaly detector on a list of feature dictionaries.

        In production this would be trained periodically on historical data.
        For Phase 2, we use a lightweight approach with statistical profiling
        when no model is available.
        """
        if len(features_list) < 10:
            logger.warning(
                f"Not enough data to train anomaly detector ({len(features_list)} samples). "
                "Using statistical profiling fallback."
            )
            return False

        try:
            from sklearn.ensemble import IsolationForest

            # Build feature matrix
            matrix = self._build_feature_matrix(features_list)
            if matrix is None or len(matrix) < 10:
                return False

            # Fit Isolation Forest
            self._model = IsolationForest(
                contamination=self.contamination,
                n_estimators=200,
                max_samples="auto",
                random_state=self.random_state,
                n_jobs=-1,
            )
            self._model.fit(matrix)

            # Compute feature statistics for Z-score fallback
            self._feature_means = np.mean(matrix, axis=0).tolist()
            self._feature_stds = np.std(matrix, axis=0).tolist()

            self._is_trained = True
            logger.info(
                f"Anomaly detector trained on {len(features_list)} samples. "
                f"Contamination: {self.contamination}"
            )
            return True

        except ImportError:
            logger.warning("scikit-learn not available, using statistical profiling only.")
            return False
        except Exception as e:
            logger.error(f"Error training anomaly detector: {e}", exc_info=True)
            return False

    def predict(self, features: dict) -> dict:
        """
        Detect anomalies for a single campaign's features.

        Returns:
            dict with:
            - anomaly_score: float (càng âm = càng bất thường)
            - is_anomaly: bool (threshold = -0.5)
            - anomaly_types: list[str] (các loại bất thường phát hiện được)
        """
        if self._is_trained and self._model is not None:
            return self._predict_with_model(features)
        else:
            return self._predict_statistical(features)

    def _predict_with_model(self, features: dict) -> dict:
        """Predict using trained Isolation Forest."""
        vector = self._build_feature_vector(features)
        if vector is None:
            return self._predict_statistical(features)

        try:
            score = self._model.score_samples(vector.reshape(1, -1))[0]
            anomaly_score = round(float(score), 4)
            is_anomaly = anomaly_score < -0.5

            anomaly_types = self._explain_anomaly(features)

            return {
                "anomaly_score": anomaly_score,
                "is_anomaly": bool(is_anomaly),
                "anomaly_types": anomaly_types,
            }
        except Exception as e:
            logger.error(f"Error in anomaly prediction: {e}", exc_info=True)
            return self._predict_statistical(features)

    def _predict_statistical(self, features: dict) -> dict:
        """
        Statistical profiling fallback using Z-score.
        Used when Isolation Forest is not trained or unavailable.
        """
        anomaly_types = []
        z_score_sum = 0.0
        z_count = 0

        # Check individual features for anomalies
        checks = [
            ("NEW_ACCOUNT_CREATION",
             features.get("creator_account_age_days") is not None
             and features.get("creator_account_age_days") < 14
             and features.get("description_quality_score", 0) > 0.5,
             "Tài khoản mới tạo nhưng mô tả chiến dịch bài bản (machine-generated suspicion)"),

            ("HIGH_CANCELLATION_RATE",
             features.get("creator_previous_cancellation_rate", 0) > 0.30,
             "Tỷ lệ hủy chiến dịch cao bất thường (> 30%)"),

            ("LATE_NIGHT_CREATION",
             features.get("is_created_late_night") is True,
             "Chiến dịch được tạo vào ban đêm (02:00-05:00)"),

            ("WEEKEND_CREATION_WITH_PERFECT_CONTENT",
             features.get("is_created_on_weekend") is True
             and features.get("description_quality_score", 0) > 0.7,
             "Chiến dịch được tạo cuối tuần với mô tả hoàn hảo (đáng ngờ)"),

            ("GHOST_REGISTRATIONS",
             features.get("ghost_registration_suspicion") is True,
             "Tỷ lệ đăng ký cao nhưng tỷ lệ xác nhận thấp (ghost registrations)"),

            ("TOO_SHORT_REGISTRATION_WINDOW",
             features.get("registration_window_days") is not None
             and features.get("registration_window_days") < 1,
             "Thời gian đăng ký quá ngắn (< 1 ngày)"),

            ("ZERO_REGISTRATION_FOR_OLD_CAMPAIGN",
             features.get("registration_count", 0) == 0
             and features.get("days_until_start", 999) > 7,
             "Chiến dịch cũ nhưng không có ai đăng ký"),

            ("HIGH_CAMPAIGN_COUNT_NEW_ACCOUNT",
             features.get("creator_account_age_days", 999) < 14
             and features.get("creator_campaign_count", 0) >= 3,
             "Tài khoản mới nhưng tạo nhiều chiến dịch"),

            ("MANY_EDIT_BEFORE_START",
             features.get("content_edit_frequency", 0) > 5
             and features.get("days_until_start", 999) < 3,
             "Nhiều lần chỉnh sửa sát ngày bắt đầu"),
        ]

        for check_name, condition, description in checks:
            if condition:
                anomaly_types.append(check_name)

        # Z-score for numeric features
        if self._feature_means and self._feature_stds:
            numeric_features = [
                ("creator_account_age_days", features.get("creator_account_age_days")),
                ("creator_campaign_count", features.get("creator_campaign_count")),
                ("creator_previous_cancellation_rate",
                 features.get("creator_previous_cancellation_rate")),
                ("creator_report_count", features.get("creator_report_count")),
            ]

            for i, (name, value) in enumerate(numeric_features):
                if value is not None and self._feature_stds[i] > 0:
                    z = abs(value - self._feature_means[i]) / self._feature_stds[i]
                    z_score_sum += z
                    z_count += 1

        avg_z = z_score_sum / z_count if z_count > 0 else 0.0
        # Map Z-score to anomaly score (higher Z = more anomalous, score is negative for IF consistency)
        anomaly_score = round(-avg_z * 0.1, 4)

        return {
            "anomaly_score": anomaly_score,
            "is_anomaly": len(anomaly_types) >= 2 or avg_z > 3.0,
            "anomaly_types": anomaly_types,
        }

    def _explain_anomaly(self, features: dict) -> list[str]:
        """Explain why a campaign is flagged as anomalous."""
        anomaly_types = []

        # Account age + content quality mismatch
        if (features.get("creator_account_age_days", 999) < 14
                and features.get("description_quality_score", 0) > 0.5):
            anomaly_types.append("NEW_ACCOUNT_CREATION")

        # High cancellation rate
        if features.get("creator_previous_cancellation_rate", 0) > 0.30:
            anomaly_types.append("HIGH_CANCELLATION_RATE")

        # Late night creation
        if features.get("is_created_late_night"):
            anomaly_types.append("LATE_NIGHT_CREATION")

        # Ghost registrations
        if features.get("ghost_registration_suspicion"):
            anomaly_types.append("GHOST_REGISTRATIONS")

        # Many edits before start
        if (features.get("content_edit_frequency", 0) > 5
                and features.get("days_until_start", 999) < 3):
            anomaly_types.append("MANY_EDITS_BEFORE_START")

        # Location mismatch (creator location vs campaign location)
        # This requires additional data - placeholder
        if features.get("location_distance_km") and features.get("location_distance_km") > 200:
            anomaly_types.append("LOCATION_MISMATCH")

        return anomaly_types

    def _build_feature_matrix(self, features_list: list[dict]) -> Optional[np.ndarray]:
        """Build a feature matrix from a list of feature dicts."""
        matrix = []
        for f in features_list:
            vector = self._build_feature_vector(f)
            if vector is not None:
                matrix.append(vector)
        if not matrix:
            return None
        return np.array(matrix)

    def _build_feature_vector(self, features: dict) -> Optional[np.ndarray]:
        """Build a feature vector from a feature dict."""
        vector = []
        for feat_name in self.ANOMALY_FEATURES:
            val = features.get(feat_name)
            if val is None:
                vector.append(0.0)
            elif isinstance(val, bool):
                vector.append(1.0 if val else 0.0)
            else:
                vector.append(float(val))
        return np.array(vector) if vector else None

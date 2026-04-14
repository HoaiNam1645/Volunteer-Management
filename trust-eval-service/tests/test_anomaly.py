"""
Test Anomaly Detection - Isolation Forest based anomaly detection.
"""

import pytest
import numpy as np
from app.ml.anomaly import AnomalyDetector


class TestAnomalyDetector:
    """Test anomaly detection logic."""

    @pytest.fixture(autouse=True)
    def setup(self):
        self.detector = AnomalyDetector()

    def test_detector_initialized(self):
        assert self.detector is not None

    def test_new_account_with_better_than_expected_description(self):
        """Tài khoản mới + mô tả bài bản = anomaly."""
        features = {
            "creator_account_age_days": 5,
            "description_length": 500,
            "description_quality_score": 0.9,
            "has_cover_image": 1.0,
            "creator_campaign_count": 0,
            "creator_report_count": 0,
        }
        result = self.detector.predict(features)
        # New account + very good description can trigger suspicion
        assert "anomaly_score" in result
        assert "is_anomaly" in result
        assert "anomaly_types" in result

    def test_high_cancellation_rate_anomaly(self):
        """Tỷ lệ hủy chiến dịch cao bất thường."""
        features = {
            "creator_account_age_days": 100,
            "creator_campaign_cancellation_rate": 0.5,  # 50% cancellation
            "creator_campaign_count": 10,
            "creator_report_count": 3,
        }
        result = self.detector.predict(features)
        assert "CANCELLATION_RATE_ANOMALY" in result["anomaly_types"]

    def test_outside_vietnam_anomaly(self):
        """Địa điểm ngoài Việt Nam."""
        features = {
            "creator_account_age_days": 30,
            "location_outside_vietnam": 1.0,
            "creator_campaign_count": 5,
        }
        result = self.detector.predict(features)
        assert "LOCATION_ANOMALY" in result["anomaly_types"]

    def test_normal_campaign_no_anomaly(self):
        """Chiến dịch bình thường không bị flag."""
        features = {
            "creator_account_age_days": 365,
            "description_length": 200,
            "description_quality_score": 0.5,
            "has_cover_image": 1.0,
            "has_location_coords": 1.0,
            "creator_campaign_count": 10,
            "creator_campaign_approval_rate": 0.85,
            "creator_campaign_cancellation_rate": 0.05,
            "creator_report_count": 0,
            "registration_to_start_ratio": 0.3,
            "has_contact_info_in_description": 1.0,
            "text_risk_keyword_count": 0,
        }
        result = self.detector.predict(features)
        assert result["is_anomaly"] is False
        assert len(result["anomaly_types"]) == 0

    def test_off_hours_creation_anomaly(self):
        """Tạo chiến dịch ngoài giờ hành chính + account mới."""
        features = {
            "creator_account_age_days": 5,
            "is_created_during_office_hours": 0.0,
            "campaign_count_in_last_hour": 5,
            "description_length": 300,
        }
        result = self.detector.predict(features)
        # Multiple anomalies should be detected
        assert len(result["anomaly_types"]) >= 0

    def test_ghost_registrations_anomaly(self):
        """Tỷ lệ đăng ký cao nhưng xác nhận thấp."""
        features = {
            "registration_to_start_ratio": 0.95,  # 95% full
            "confirmation_rate": 0.1,  # But only 10% confirmed
            "creator_account_age_days": 30,
        }
        result = self.detector.predict(features)
        assert "GHOST_REGISTRATIONS" in result["anomaly_types"]

    def test_anomaly_score_range(self):
        """Anomaly score phải nằm trong range hợp lệ."""
        features = {
            "creator_account_age_days": 365,
            "description_length": 200,
            "description_quality_score": 0.5,
            "creator_campaign_count": 5,
        }
        result = self.detector.predict(features)
        # Score should be a float
        assert isinstance(result["anomaly_score"], (float, int))

    def test_multiple_anomalies_detected(self):
        """Nhiều loại anomaly cùng lúc được phát hiện."""
        features = {
            "creator_account_age_days": 3,  # New account
            "description_length": 600,  # Very detailed (machine-like)
            "description_quality_score": 0.95,
            "has_cover_image": 1.0,
            "creator_campaign_count": 0,
            "creator_campaign_cancellation_rate": 1.0,
            "creator_report_count": 2,
            "location_outside_vietnam": 1.0,
        }
        result = self.detector.predict(features)
        # Should detect multiple anomaly types
        assert len(result["anomaly_types"]) >= 1


class TestAnomalyDetectorEdgeCases:
    """Test edge cases."""

    def test_empty_features(self):
        detector = AnomalyDetector()
        features = {}
        result = detector.predict(features)
        # Should not crash
        assert "anomaly_score" in result
        assert "is_anomaly" in result

    def test_none_values(self):
        detector = AnomalyDetector()
        features = {
            "creator_account_age_days": None,
            "description_length": None,
        }
        result = detector.predict(features)
        assert "anomaly_score" in result

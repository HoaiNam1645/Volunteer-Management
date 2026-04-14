"""
Test Feature Extraction - Campaign và Volunteer Feature Extractors.
"""

import pytest
from datetime import date, timedelta
from app.core.feature_extractor import CampaignFeatureExtractor


class TestCampaignFeatureExtractor:
    """Test campaign feature extraction."""

    def test_extract_all_features(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(
            campaign=sample_campaign,
            creator=sample_creator,
            registrations=[],
            ratings=sample_creator["ratings"],
            reports=[],
            review_history=[],
            feedbacks=[],
        )
        features = extractor.extract()

        # Should have all expected feature keys
        expected_features = [
            "has_cover_image",
            "description_length",
            "has_location_coords",
            "has_schedule",
            "has_registration_deadline",
            "creator_account_age_days",
            "creator_has_verified_email",
            "creator_campaign_count",
            "registration_to_start_ratio",
        ]

        for feat in expected_features:
            assert feat in features, f"Missing feature: {feat}"

    def test_has_cover_image_true(self, sample_campaign, sample_creator):
        campaign = sample_campaign.copy()
        campaign["anh_bia"] = "https://example.com/image.jpg"
        extractor = CampaignFeatureExtractor(campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["has_cover_image"] == 1.0

    def test_has_cover_image_false(self, sample_campaign, sample_creator):
        campaign = sample_campaign.copy()
        campaign["anh_bia"] = None
        extractor = CampaignFeatureExtractor(campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["has_cover_image"] == 0.0

    def test_description_length(self, sample_campaign, sample_creator):
        campaign = sample_campaign.copy()
        campaign["mo_ta"] = "A" * 200
        extractor = CampaignFeatureExtractor(campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["description_length"] == 200

    def test_creator_account_age(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["creator_account_age_days"] > 0
        assert features["creator_account_age_days"] >= 0

    def test_creator_is_new_account(self, sample_campaign, suspicious_creator):
        # Suspicious creator has account age < 7 days
        extractor = CampaignFeatureExtractor(sample_campaign, suspicious_creator, [], [], [], [])
        features = extractor.extract()
        assert features["is_new_account"] == 1.0

    def test_creator_verified_email(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["creator_has_verified_email"] == 1.0

    def test_creator_unverified_email(self, sample_campaign, suspicious_creator):
        # suspicious_creator has no email verification
        campaign = sample_campaign.copy()
        campaign["nguoi_tao_id"] = suspicious_creator["id"]
        extractor = CampaignFeatureExtractor(campaign, suspicious_creator, [], [], [], [])
        features = extractor.extract()
        assert features["creator_has_verified_email"] == 0.0

    def test_registration_ratio(self, sample_campaign, sample_creator):
        registrations = [
            {"id": 1, "trang_thai": "da_xac_nhan"},
            {"id": 2, "trang_thai": "da_xac_nhan"},
            {"id": 3, "trang_thai": "dang_ky"},
        ]
        extractor = CampaignFeatureExtractor(
            sample_campaign, sample_creator, registrations, [], [], []
        )
        features = extractor.extract()
        # 3 registrations / 50 max = 0.06
        assert features["registration_to_start_ratio"] == pytest.approx(0.06, rel=0.1)

    def test_campaign_duration_days(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        # Duration should be positive
        assert features["campaign_duration_days"] > 0

    def test_is_created_during_office_hours(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        # Created at is 30 days ago, so not during office hours
        assert "is_created_during_office_hours" in features

    def test_rating_features(self, sample_campaign, sample_creator):
        ratings = [
            {"so_sao": 5},
            {"so_sao": 4},
            {"so_sao": 5},
        ]
        extractor = CampaignFeatureExtractor(
            sample_campaign, sample_creator, [], ratings, [], []
        )
        features = extractor.extract()
        assert features["creator_volunteer_rating_avg"] == pytest.approx(4.67, rel=0.1)
        assert features["creator_volunteer_rating_count"] == 3

    def test_report_count(self, sample_campaign, sample_creator):
        reports = [
            {"id": 1},
            {"id": 2},
        ]
        extractor = CampaignFeatureExtractor(
            sample_campaign, sample_creator, [], [], reports, []
        )
        features = extractor.extract()
        assert features["creator_report_count"] == 2

    def test_team_size_feasibility(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        # 50 volunteers / 5 days = 10/day, should be reasonable
        assert "team_size_feasibility" in features


class TestFeatureExtractorEdgeCases:
    """Test edge cases in feature extraction."""

    def test_no_creator(self, sample_campaign, empty_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, empty_creator, [], [], [], [])
        features = extractor.extract()
        # Should not crash, should return defaults
        assert "has_cover_image" in features

    def test_no_registrations(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["registration_to_start_ratio"] == 0.0

    def test_no_ratings(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert features["creator_volunteer_rating_avg"] is None
        assert features["creator_volunteer_rating_count"] == 0

    def test_all_zero_registrations(self, sample_campaign, sample_creator):
        campaign = sample_campaign.copy()
        campaign["so_dang_ky"] = 0
        campaign["so_luong_toi_da"] = 0
        extractor = CampaignFeatureExtractor(campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        # Should not divide by zero
        assert features["registration_to_start_ratio"] == 0.0

    def test_description_quality_score(self, sample_campaign, sample_creator):
        extractor = CampaignFeatureExtractor(sample_campaign, sample_creator, [], [], [], [])
        features = extractor.extract()
        assert 0.0 <= features["description_quality_score"] <= 1.0

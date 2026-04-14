"""
Test Rule-based Validation Layer.

Kiểm tra tất cả các rule validation:
- Title: không rỗng, 10-200 ký tự
- Description: không rỗng, tối thiểu 50 ký tự
- Location: không rỗng
- Coordinates: phải nằm trong Việt Nam
- Schedule: ngày bắt đầu >= hôm nay, ngày kết thúc >= ngày bắt đầu
- Registration deadline: trong khoảng [hôm nay, ngày bắt đầu]
- Counts: so_luong_toi_da >= so_luong_toi_thieu >= 1
- Creator: tồn tại, hoạt động, email đã xác thực
- Campaign type: loai_chien_dich_id không rỗng
"""

import pytest
from datetime import date, timedelta
from app.core.rule_validator import RuleBasedValidator, ValidationRule


class TestTitleValidation:
    """Test title validation rules."""

    def test_title_empty_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["tieu_de"] = ""
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        errors = result["critical_errors"]
        assert any(e["code"] == "TITLE_EMPTY" for e in errors)

    def test_title_none_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["tieu_de"] = None
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        errors = result["critical_errors"]
        assert any(e["code"] == "TITLE_EMPTY" for e in errors)

    def test_title_too_short_is_medium(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["tieu_de"] = "Ngắn"
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "TITLE_TOO_SHORT" for w in warnings)

    def test_title_valid_length(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["tieu_de"] = "Chiến dịch tình nguyện mùa hè xanh 2026"
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        codes = [w["code"] for w in result["warnings"]]
        assert "TITLE_TOO_SHORT" not in codes

    def test_title_too_long_is_low(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["tieu_de"] = "X" * 250
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "TITLE_TOO_LONG" for w in warnings)


class TestDescriptionValidation:
    """Test description validation rules."""

    def test_description_empty_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["mo_ta"] = ""
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "DESCRIPTION_EMPTY" for e in result["critical_errors"])

    def test_description_too_short_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["mo_ta"] = "Mô tả ngắn"
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "DESCRIPTION_TOO_SHORT" for w in warnings)

    def test_description_valid(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["mo_ta"] = "A" * 60
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        codes = [w["code"] for w in result["warnings"]]
        assert "DESCRIPTION_TOO_SHORT" not in codes


class TestLocationValidation:
    """Test location validation rules."""

    def test_location_empty_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["dia_diem"] = ""
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "LOCATION_EMPTY" for e in result["critical_errors"])

    def test_coords_missing_is_medium(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["vi_do"] = None
        campaign["kinh_do"] = None
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "COORDS_MISSING" for w in warnings)

    def test_coords_outside_vietnam(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["vi_do"] = 50.0   # Outside Vietnam
        campaign["kinh_do"] = 120.0
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "COORDS_OUTSIDE_VIETNAM" for w in warnings)

    def test_coords_inside_vietnam(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["vi_do"] = 21.0
        campaign["kinh_do"] = 105.5
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        codes = [w["code"] for w in result["warnings"]]
        assert "COORDS_OUTSIDE_VIETNAM" not in codes


class TestScheduleValidation:
    """Test schedule validation rules."""

    def test_start_date_past_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["ngay_bat_dau"] = (date.today() - timedelta(days=1)).isoformat()
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "DATE_START_IN_PAST" for e in result["critical_errors"])

    def test_end_before_start_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["ngay_bat_dau"] = (date.today() + timedelta(days=10)).isoformat()
        campaign["ngay_ket_thuc"] = (date.today() + timedelta(days=5)).isoformat()
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "DATE_END_BEFORE_START" for e in result["critical_errors"])

    def test_duration_too_long_is_low(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["ngay_bat_dau"] = date.today().isoformat()
        campaign["ngay_ket_thuc"] = (date.today() + timedelta(days=400)).isoformat()
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "DATE_DURATION_TOO_LONG" for w in warnings)


class TestRegistrationDeadlineValidation:
    """Test registration deadline validation rules."""

    def test_deadline_missing_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["han_dang_ky"] = None
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "REG_DEADLINE_MISSING" for w in warnings)

    def test_deadline_in_past_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["han_dang_ky"] = (date.today() - timedelta(days=1)).isoformat()
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "REG_DEADLINE_IN_PAST" for w in warnings)

    def test_deadline_after_start_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["han_dang_ky"] = (date.today() + timedelta(days=15)).isoformat()
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "REG_DEADLINE_AFTER_START" for w in warnings)


class TestCountValidation:
    """Test volunteer count validation rules."""

    def test_max_less_than_min_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["so_luong_toi_da"] = 5
        campaign["so_luong_toi_thieu"] = 10
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "COUNT_MAX_LESS_THAN_MIN" for w in warnings)

    def test_min_less_than_one_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["so_luong_toi_thieu"] = 0
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "COUNT_MIN_INVALID" for w in warnings)


class TestCreatorValidation:
    """Test creator validation rules."""

    def test_creator_missing_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["nguoi_tao_id"] = None
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "CREATOR_MISSING" for e in result["critical_errors"])

    def test_creator_not_found_is_critical(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["nguoi_tao_id"] = 999
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        assert result["passed"] is False
        assert any(e["code"] == "CREATOR_NOT_FOUND" for e in result["critical_errors"])

    def test_creator_not_active_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        creator = empty_creator.copy()
        creator["id"] = 100
        creator["trang_thai"] = "bi_khoa"
        validator = RuleBasedValidator(campaign, creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "CREATOR_NOT_ACTIVE" for w in warnings)

    def test_creator_email_unverified_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        creator = empty_creator.copy()
        creator["id"] = 100
        creator["trang_thai"] = "hoat_dong"
        creator["xac_thuc_email_luc"] = None
        validator = RuleBasedValidator(campaign, creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "CREATOR_EMAIL_UNVERIFIED" for w in warnings)


class TestCampaignTypeValidation:
    """Test campaign type validation rules."""

    def test_type_missing_is_high(self, sample_campaign, empty_creator):
        campaign = sample_campaign.copy()
        campaign["loai_chien_dich_id"] = None
        validator = RuleBasedValidator(campaign, empty_creator)
        result = validator.validate()
        warnings = result["warnings"]
        assert any(w["code"] == "TYPE_MISSING" for w in warnings)


class TestValidCampaign:
    """Test a fully valid campaign passes validation."""

    def test_valid_campaign_passes(self, sample_campaign, sample_creator):
        validator = RuleBasedValidator(sample_campaign, sample_creator)
        result = validator.validate()
        # Should pass (no CRITICAL errors)
        assert result["passed"] is True
        # Should still have LOW warnings for things like no cover image, etc.
        # but no CRITICAL errors
        for err in result["critical_errors"]:
            assert err["severity"] != "CRITICAL"


class TestSuspiciousCampaign:
    """Test a suspicious campaign is properly flagged."""

    def test_suspicious_campaign_has_critical_errors(self, suspicious_campaign, suspicious_creator):
        validator = RuleBasedValidator(suspicious_campaign, suspicious_creator)
        result = validator.validate()
        # Should have CRITICAL errors
        assert result["passed"] is False
        assert len(result["critical_errors"]) > 0


class TestValidationRuleToDict:
    """Test ValidationRule.to_dict()."""

    def test_to_dict_format(self):
        rule = ValidationRule(
            code="TITLE_EMPTY",
            severity="CRITICAL",
            field="tieu_de",
            message="Tên chiến dịch không được để trống",
            suggestion="Yêu cầu nhập tên",
            auto_resolvable=True,
        )
        d = rule.to_dict()
        assert d["code"] == "TITLE_EMPTY"
        assert d["severity"] == "CRITICAL"
        assert d["field"] == "tieu_de"
        assert d["message"] == "Tên chiến dịch không được để trống"
        assert d["suggestion"] == "Yêu cầu nhập tên"
        assert d["auto_resolvable"] is True
        assert "category" in d

    def test_category_inference(self):
        # TITLE prefix → INFORMATION_COMPLETENESS
        rule = ValidationRule("TITLE_ABC", "LOW", "tieu_de", "msg", "sug")
        assert rule.to_dict()["category"] == "INFORMATION_COMPLETENESS"

        # LOCATION prefix → LOCATION
        rule = ValidationRule("LOCATION_XYZ", "LOW", "dia_diem", "msg", "sug")
        assert rule.to_dict()["category"] == "LOCATION"

        # DATE prefix → SCHEDULE_REASONABLENESS
        rule = ValidationRule("DATE_START_MISSING", "CRITICAL", "ngay", "msg", "sug")
        assert rule.to_dict()["category"] == "SCHEDULE_REASONABLENESS"

        # CREATOR prefix → CREATOR_RELIABILITY
        rule = ValidationRule("CREATOR_NOT_FOUND", "CRITICAL", "nguoi", "msg", "sug")
        assert rule.to_dict()["category"] == "CREATOR_RELIABILITY"

        # Unknown prefix → GENERAL
        rule = ValidationRule("UNKNOWN_CODE", "LOW", "field", "msg", "sug")
        assert rule.to_dict()["category"] == "GENERAL"

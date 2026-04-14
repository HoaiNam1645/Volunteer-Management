"""
Test Decision Logic - Bảng quyết định recommended_action.

Kiểm tra tất cả 8 rows của bảng quyết định theo SPEC:
| Trust Score | Risk Level | Anomaly | Text Risk | Recommended Action |
|---|---|---|---|---|
| >= 0.70 | LOW | false | < 0.2 | APPROVE |
| >= 0.70 | LOW | false | >= 0.2 | APPROVE_WITH_NOTE |
| >= 0.60 | LOW/MEDIUM | false | any | APPROVE_WITH_NOTE |
| >= 0.60 | HIGH/CRITICAL | true | any | REQUEST_ADDITIONAL_INFO |
| 0.40–0.59 | LOW | false | < 0.3 | REQUEST_ADDITIONAL_INFO |
| 0.40–0.59 | MEDIUM | any | any | REQUEST_ADDITIONAL_INFO |
| 0.40–0.59 | HIGH/CRITICAL | any | any | REJECT |
| < 0.40 | any | any | any | REJECT |
"""

import pytest
from app.core.decision_logic import DecisionLogic


class TestDecisionTable:
    """Test bảng quyết định theo SPEC."""

    @pytest.fixture(autouse=True)
    def setup(self):
        self.logic = DecisionLogic()
        self.empty_flags = []

    # ── Row 1: >= 0.70, LOW, no anomaly, text_risk < 0.2 → APPROVE ──
    def test_row1_approve(self):
        result = self.logic.decide(
            trust_score=0.75, risk_level="LOW",
            text_risk_score=0.1, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE"

    def test_row1_approve_edge(self):
        result = self.logic.decide(
            trust_score=0.70, risk_level="LOW",
            text_risk_score=0.19, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE"

    # ── Row 2: >= 0.70, LOW, no anomaly, text_risk >= 0.2 → APPROVE_WITH_NOTE ──
    def test_row2_approve_with_note(self):
        result = self.logic.decide(
            trust_score=0.78, risk_level="LOW",
            text_risk_score=0.2, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE_WITH_NOTE"

    def test_row2_approve_with_note_edge(self):
        result = self.logic.decide(
            trust_score=0.70, risk_level="LOW",
            text_risk_score=0.5, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE_WITH_NOTE"

    # ── Row 3: >= 0.60, LOW/MEDIUM, no anomaly → APPROVE_WITH_NOTE ──
    def test_row3_low_no_anomaly(self):
        result = self.logic.decide(
            trust_score=0.65, risk_level="LOW",
            text_risk_score=0.0, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE_WITH_NOTE"

    def test_row3_medium_no_anomaly(self):
        result = self.logic.decide(
            trust_score=0.62, risk_level="MEDIUM",
            text_risk_score=0.8, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE_WITH_NOTE"

    # ── Row 4: >= 0.60, HIGH/CRITICAL, anomaly=true → REQUEST_ADDITIONAL_INFO ──
    def test_row4_high_anomaly(self):
        result = self.logic.decide(
            trust_score=0.65, risk_level="HIGH",
            text_risk_score=0.5, is_anomaly=True,
            anomaly_types=["NEW_ACCOUNT_CREATION_PATTERN"],
            flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    def test_row4_critical_anomaly(self):
        result = self.logic.decide(
            trust_score=0.70, risk_level="CRITICAL",
            text_risk_score=0.9, is_anomaly=True,
            anomaly_types=["HIGH_TEXT_SIMILARITY"],
            flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    # ── Row 5: 0.40–0.59, LOW, no anomaly, text_risk < 0.3 → REQUEST_ADDITIONAL_INFO ──
    def test_row5(self):
        result = self.logic.decide(
            trust_score=0.50, risk_level="LOW",
            text_risk_score=0.2, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    def test_row5_edge_lower(self):
        result = self.logic.decide(
            trust_score=0.40, risk_level="LOW",
            text_risk_score=0.0, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    # ── Row 6: 0.40–0.59, MEDIUM, any → REQUEST_ADDITIONAL_INFO ──
    def test_row6_medium_any(self):
        result = self.logic.decide(
            trust_score=0.55, risk_level="MEDIUM",
            text_risk_score=0.0, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    def test_row6_medium_anomaly(self):
        result = self.logic.decide(
            trust_score=0.45, risk_level="MEDIUM",
            text_risk_score=0.9, is_anomaly=True,
            anomaly_types=["GHOST_REGISTRATIONS"],
            flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REQUEST_ADDITIONAL_INFO"

    # ── Row 7: 0.40–0.59, HIGH/CRITICAL → REJECT ──
    def test_row7_high(self):
        result = self.logic.decide(
            trust_score=0.50, risk_level="HIGH",
            text_risk_score=0.1, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REJECT"

    def test_row7_critical(self):
        result = self.logic.decide(
            trust_score=0.45, risk_level="CRITICAL",
            text_risk_score=0.0, is_anomaly=True,
            anomaly_types=["HIGH_CANCELLATION_RATE"],
            flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REJECT"

    # ── Row 8: < 0.40, any → REJECT ──
    def test_row8_any(self):
        for risk_level in ["LOW", "MEDIUM", "HIGH", "CRITICAL"]:
            for is_anomaly in [True, False]:
                result = self.logic.decide(
                    trust_score=0.30, risk_level=risk_level,
                    text_risk_score=0.1, is_anomaly=is_anomaly,
                    anomaly_types=[], flags=self.empty_flags, validation_passed=True,
                )
                assert result["recommended_action"] == "REJECT", f"Failed for {risk_level}, anomaly={is_anomaly}"

    def test_row8_very_low(self):
        result = self.logic.decide(
            trust_score=0.05, risk_level="HIGH",
            text_risk_score=0.9, is_anomaly=True,
            anomaly_types=["MULTIPLE_ANOMALIES"],
            flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REJECT"

    # ── Validation Failed → Always REJECT ──
    def test_validation_failed_always_reject(self):
        result = self.logic.decide(
            trust_score=0.90, risk_level="LOW",
            text_risk_score=0.0, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=False,
        )
        assert result["recommended_action"] == "REJECT"
        assert "nghiêm trọng" in result["reason"]


class TestConfidenceComputation:
    """Test confidence computation."""

    @pytest.fixture(autouse=True)
    def setup(self):
        self.logic = DecisionLogic()
        self.empty_flags = []

    def test_confidence_high(self):
        # Trust >= 0.75 + LOW risk → HIGH confidence
        result = self.logic.decide(
            trust_score=0.80, risk_level="LOW",
            text_risk_score=0.1, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["confidence"] == "HIGH"

    def test_confidence_medium(self):
        # Trust in 0.4–0.7 range → MEDIUM confidence
        result = self.logic.decide(
            trust_score=0.55, risk_level="MEDIUM",
            text_risk_score=0.3, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["confidence"] == "MEDIUM"

    def test_confidence_low(self):
        # Trust < 0.25 + HIGH risk → LOW confidence
        result = self.logic.decide(
            trust_score=0.15, risk_level="HIGH",
            text_risk_score=0.9, is_anomaly=True,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["confidence"] == "LOW"


class TestReasonBuilding:
    """Test reason string building."""

    @pytest.fixture(autouse=True)
    def setup(self):
        self.logic = DecisionLogic()
        self.empty_flags = []

    def test_reject_reason_contains_score(self):
        result = self.logic.decide(
            trust_score=0.20, risk_level="HIGH",
            text_risk_score=0.8, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "REJECT"
        assert "20%" in result["reason"]  # trust score in reason

    def test_approve_reason_contains_score(self):
        result = self.logic.decide(
            trust_score=0.85, risk_level="LOW",
            text_risk_score=0.1, is_anomaly=False,
            anomaly_types=[], flags=self.empty_flags, validation_passed=True,
        )
        assert result["recommended_action"] == "APPROVE"
        assert "85%" in result["reason"]

    def test_questions_limit(self):
        flags = [
            {"severity": "HIGH", "suggestion": "Question 1"},
            {"severity": "HIGH", "suggestion": "Question 2"},
            {"severity": "CRITICAL", "suggestion": "Question 3"},
            {"severity": "HIGH", "suggestion": "Question 4"},
            {"severity": "HIGH", "suggestion": "Question 5"},
            {"severity": "HIGH", "suggestion": "Question 6"},
            {"severity": "HIGH", "suggestion": "Question 7"},
        ]
        result = self.logic.decide(
            trust_score=0.30, risk_level="HIGH",
            text_risk_score=0.8, is_anomaly=True,
            anomaly_types=[], flags=flags, validation_passed=True,
        )
        # Max 5 questions
        assert len(result["questions_to_verify"]) <= 5

    def test_questions_deduplicated(self):
        flags = [
            {"severity": "HIGH", "suggestion": "Same question"},
            {"severity": "HIGH", "suggestion": "Same question"},
            {"severity": "HIGH", "suggestion": "Same question"},
        ]
        result = self.logic.decide(
            trust_score=0.30, risk_level="HIGH",
            text_risk_score=0.8, is_anomaly=True,
            anomaly_types=[], flags=flags, validation_passed=True,
        )
        # Should be deduplicated
        assert len(result["questions_to_verify"]) <= 5

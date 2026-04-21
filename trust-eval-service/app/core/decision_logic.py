"""
Decision Logic - Tổng hợp tất cả điểm số và rules để sinh recommended_action.

Bảng quyết định:
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

from typing import Optional


class DecisionLogic:
    """
    Tổng hợp tất cả signals để sinh recommended_action.

    Input:
    - trust_score: float (0.0-1.0)
    - risk_level: str (LOW, MEDIUM, HIGH, CRITICAL)
    - text_risk_score: float (0.0-1.0)
    - is_anomaly: bool
    - anomaly_types: list[str]
    - flags: list[dict]
    - validation_passed: bool

    Output:
    - recommended_action: str
    - confidence: str (HIGH, MEDIUM, LOW)
    - reason: str
    - questions_to_verify: list[str]
    """

    def decide(
        self,
        trust_score: float,
        risk_level: str,
        text_risk_score: float,
        is_anomaly: bool,
        anomaly_types: list[str],
        flags: list[dict],
        validation_passed: bool,
    ) -> dict:
        """
        Sinh quyết định cuối cùng.
        """
        # If validation failed (CRITICAL errors), always REJECT
        if not validation_passed:
            return self._reject(
                reason="Chiến dịch không đáp ứng các điều kiện bắt buộc. "
                       "Vui lòng sửa các lỗi nghiêm trọng trước khi gửi duyệt.",
                confidence="LOW",
                flags=flags,
            )

        # Apply decision table
        action = self._apply_decision_table(
            trust_score, risk_level, text_risk_score, is_anomaly
        )

        if action == "REJECT":
            return self._reject(
                reason=self._build_reject_reason(trust_score, risk_level, flags),
                confidence=self._compute_confidence(trust_score, risk_level),
                flags=flags,
            )

        if action == "REQUEST_ADDITIONAL_INFO":
            return self._request_info(
                reason=self._build_request_info_reason(trust_score, risk_level, flags),
                confidence=self._compute_confidence(trust_score, risk_level),
                flags=flags,
            )

        if action == "APPROVE_WITH_NOTE":
            return self._approve_with_note(
                reason=self._build_approve_reason(trust_score, risk_level),
                confidence=self._compute_confidence(trust_score, risk_level),
                flags=flags,
            )

        # APPROVE
        return self._approve(
            reason=self._build_approve_reason(trust_score, risk_level),
            confidence=self._compute_confidence(trust_score, risk_level),
            flags=flags,
        )

    def _apply_decision_table(
        self,
        trust_score: float,
        risk_level: str,
        text_risk_score: float,
        is_anomaly: bool,
    ) -> str:
        """Apply the decision table from SPEC."""
        # Row 1: >= 0.70, LOW, no anomaly, text_risk < 0.2
        if trust_score >= 0.70 and risk_level == "LOW" and not is_anomaly and text_risk_score < 0.2:
            return "APPROVE"

        # Row 2: >= 0.70, LOW, no anomaly, text_risk >= 0.2
        if trust_score >= 0.70 and risk_level == "LOW" and not is_anomaly and text_risk_score >= 0.2:
            return "APPROVE_WITH_NOTE"

        # Row 3: >= 0.60, LOW or MEDIUM, no anomaly
        if trust_score >= 0.60 and risk_level in ("LOW", "MEDIUM") and not is_anomaly:
            return "APPROVE_WITH_NOTE"

        # Row 4: >= 0.60, HIGH or CRITICAL, is_anomaly=True
        # NOTE: Trường hợp HIGH/CRITICAL nhưng is_anomaly=False
        #       không match Row 4 → fallback default: REQUEST_ADDITIONAL_INFO (đúng kết quả)
        if trust_score >= 0.60 and risk_level in ("HIGH", "CRITICAL") and is_anomaly:
            return "REQUEST_ADDITIONAL_INFO"

        # Row 5: 0.40-0.59, LOW, no anomaly, text_risk < 0.3
        if 0.40 <= trust_score < 0.60 and risk_level == "LOW" and not is_anomaly and text_risk_score < 0.3:
            return "REQUEST_ADDITIONAL_INFO"

        # Row 6: 0.40-0.59, MEDIUM, any
        if 0.40 <= trust_score < 0.60 and risk_level == "MEDIUM":
            return "REQUEST_ADDITIONAL_INFO"

        # Row 7: 0.40-0.59, HIGH or CRITICAL
        # NOTE: Không cần text_risk check vì HIGH/CRITICAL đã serious enough để reject
        if 0.40 <= trust_score < 0.60 and risk_level in ("HIGH", "CRITICAL"):
            return "REJECT"

        # Row 8: < 0.40, any
        if trust_score < 0.40:
            return "REJECT"

        # Default fallback
        return "REQUEST_ADDITIONAL_INFO"

    def _compute_confidence(self, trust_score: float, risk_level: str) -> str:
        """Tính confidence của quyết định."""
        if risk_level in ("LOW", "HIGH") and (trust_score >= 0.75 or trust_score < 0.25):
            return "HIGH"
        if risk_level == "MEDIUM" or (0.4 <= trust_score <= 0.7):
            return "MEDIUM"
        return "LOW"

    # ============================================================
    # ACTION BUILDERS
    # ============================================================

    def _approve(
        self, reason: str, confidence: str, flags: list[dict]
    ) -> dict:
        return {
            "recommended_action": "APPROVE",
            "confidence": confidence,
            "reason": reason,
            "questions_to_verify": self._build_verify_questions(flags, "APPROVE"),
        }

    def _approve_with_note(
        self, reason: str, confidence: str, flags: list[dict]
    ) -> dict:
        return {
            "recommended_action": "APPROVE_WITH_NOTE",
            "confidence": confidence,
            "reason": reason,
            "questions_to_verify": self._build_verify_questions(flags, "APPROVE_WITH_NOTE"),
        }

    def _request_info(
        self, reason: str, confidence: str, flags: list[dict]
    ) -> dict:
        return {
            "recommended_action": "REQUEST_ADDITIONAL_INFO",
            "confidence": confidence,
            "reason": reason,
            "questions_to_verify": self._build_verify_questions(flags, "REQUEST_ADDITIONAL_INFO"),
        }

    def _reject(
        self, reason: str, confidence: str, flags: list[dict]
    ) -> dict:
        return {
            "recommended_action": "REJECT",
            "confidence": confidence,
            "reason": reason,
            "questions_to_verify": self._build_verify_questions(flags, "REJECT"),
        }

    # ============================================================
    # REASON BUILDERS
    # ============================================================

    def _build_reject_reason(
        self, trust_score: float, risk_level: str, flags: list[dict]
    ) -> str:
        reasons = []

        if trust_score < 0.40:
            reasons.append(
                f"Điểm tin cậy rất thấp ({trust_score:.0%})"
            )

        if risk_level in ("HIGH", "CRITICAL"):
            reasons.append(
                f"Mức rủi ro {self._risk_level_text(risk_level)}"
            )

        critical_count = len([f for f in flags if f.get("severity") == "CRITICAL"])
        high_count = len([f for f in flags if f.get("severity") == "HIGH"])

        if critical_count > 0:
            reasons.append(f"Có {critical_count} lỗi nghiêm trọng chưa được giải quyết")
        elif high_count > 0:
            reasons.append(f"Có {high_count} cảnh báo cao cần xác minh")

        if not reasons:
            reasons.append("Chiến dịch không đáp ứng đủ điều kiện tin cậy")

        return ". ".join(reasons) + ". Cần được xem xét lại."

    def _build_request_info_reason(
        self, trust_score: float, risk_level: str, flags: list[dict]
    ) -> str:
        reasons = []

        if 0.40 <= trust_score < 0.60:
            reasons.append(
                f"Điểm tin cậy ở mức trung bình ({trust_score:.0%})"
            )

        if risk_level == "MEDIUM":
            reasons.append("Có một số yếu tố rủi ro cần xác minh thêm")

        high_count = len([f for f in flags if f.get("severity") == "HIGH"])
        medium_count = len([f for f in flags if f.get("severity") == "MEDIUM"])

        if high_count > 0:
            reasons.append(f"Có {high_count} cảnh báo cao cần kiểm tra")
        if medium_count > 0:
            reasons.append(f"Có {medium_count} cảnh báo trung bình cần xác nhận")

        if not reasons:
            reasons.append("Chiến dịch có một số thông tin cần được xác minh thêm")

        return ". ".join(reasons) + ". KDV nên yêu cầu bổ sung thông tin."

    def _build_approve_reason(
        self, trust_score: float, risk_level: str
    ) -> str:
        parts = [
            f"Điểm tin cậy {trust_score:.0%}.",
        ]
        if risk_level == "LOW":
            parts.append("Mức rủi ro thấp.")
            parts.append("Các thông tin cơ bản đáp ứng yêu cầu.")
        elif risk_level == "MEDIUM":
            parts.append("Mức rủi ro trung bình, có thể duyệt với ghi chú.")
        return " ".join(parts)

    def _risk_level_text(self, level: str) -> str:
        return {"LOW": "thấp", "MEDIUM": "trung bình",
                "HIGH": "cao", "CRITICAL": "nghiêm trọng"}.get(level, level)

    # ============================================================
    # QUESTIONS TO VERIFY
    # ============================================================

    def _build_verify_questions(
        self, flags: list[dict], action: str
    ) -> list[str]:
        """Build list of questions to verify based on flags."""
        questions = []

        # Add questions from HIGH and CRITICAL flags
        for flag in flags:
            sev = flag.get("severity", "")
            if sev in ("CRITICAL", "HIGH"):
                suggestion = flag.get("suggestion", "")
                if suggestion:
                    questions.append(suggestion)

        # Add standard questions based on action
        if action in ("APPROVE", "APPROVE_WITH_NOTE"):
            standard_qs = [
                "Xác nhận địa điểm chi tiết với người tạo.",
                "Kiểm tra giấy phép/quyền tổ chức nếu là hoạt động chính thức.",
            ]
        elif action == "REQUEST_ADDITIONAL_INFO":
            standard_qs = [
                "Liên hệ người tạo để xác minh thông tin chi tiết.",
                "Yêu cầu bổ sung tài liệu minh chứng nếu cần.",
                "Kiểm tra lịch sử hoạt động của người tạo trong hệ thống.",
            ]
        else:  # REJECT
            standard_qs = [
                "Thông báo cho người tạo về các vấn đề cần sửa.",
                "Hướng dẫn người tạo cập nhật thông tin chiến dịch.",
            ]

        # Merge, deduplicate, limit
        all_qs = questions + standard_qs
        seen = set()
        unique_qs = []
        for q in all_qs:
            if q not in seen:
                seen.add(q)
                unique_qs.append(q)

        return unique_qs[:5]

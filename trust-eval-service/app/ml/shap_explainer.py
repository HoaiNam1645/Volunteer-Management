"""
SHAP Explainability - SHAP-based model explanation.

Phase 4: Uses TreeExplainer for LightGBM models to generate per-evaluation
SHAP explanations with top positive/negative factors.
"""

import logging
from typing import Optional, Any

import numpy as np

logger = logging.getLogger("trust_eval_service")


class SHAPExplainer:
    """
    SHAP-based explainer using TreeExplainer for LightGBM.

    Generates per-evaluation explanations:
    - Top positive factors (features pushing toward RELIABLE)
    - Top negative factors (features pushing toward SUSPICIOUS)
    - Base value, prediction, and overall feature importance

    For rule-based fallback, returns a simplified explanation.
    """

    CAMPAIGN_FEATURE_DISPLAY_NAMES = {
        "has_cover_image": "Có ảnh bìa",
        "gallery_image_count": "Số ảnh gallery",
        "description_length": "Độ dài mô tả",
        "description_word_count": "Số từ mô tả",
        "description_quality_score": "Chất lượng mô tả",
        "location_completeness": "Hoàn thiện địa điểm",
        "has_location_coords": "Có tọa độ",
        "coords_in_vietnam": "Tọa độ trong Việt Nam",
        "schedule_completeness": "Hoàn thiện lịch trình",
        "days_until_start": "Ngày đến lúc bắt đầu",
        "campaign_duration_days": "Thời lượng chiến dịch",
        "registration_window_days": "Thời gian đăng ký",
        "reg_deadline_reasonable": "Hạn đăng ký hợp lý",
        "team_size_feasibility": "Quy mô nhóm khả thi",
        "max_volunteers": "Số TNV tối đa",
        "min_volunteers": "Số TNV tối thiểu",
        "volunteer_range_valid": "Khoảng TNV hợp lệ",
        "is_urgent_priority": "Ưu tiên khẩn cấp",
        "has_contact_info_in_desc": "Có thông tin liên hệ",
        "text_contains_external_urls": "Chứa URL ngoài",
        "external_url_count": "Số URL ngoài",
        "skill_requirements_clarity": "Yêu cầu kỹ năng rõ ràng",
        "campaign_status_code": "Mã trạng thái chiến dịch",
        "registration_count": "Số đăng ký",
        "confirmed_count": "Số xác nhận",
        "registration_ratio": "Tỷ lệ đăng ký",
        "confirmation_ratio": "Tỷ lệ xác nhận",
        "creator_account_age_days": "Tuổi tài khoản người tạo",
        "creator_has_verified_email": "Email đã xác thực",
        "creator_has_verified_phone": "SĐT đã xác thực",
        "creator_has_avatar": "Có ảnh đại diện",
        "creator_has_bio": "Có giới thiệu",
        "creator_campaign_count": "Số chiến dịch đã tạo",
        "creator_campaign_approval_rate": "Tỷ lệ duyệt chiến dịch",
        "creator_previous_cancellation_rate": "Tỷ lệ hủy chiến dịch",
        "creator_volunteer_rating_avg": "Điểm đánh giá TB từ TNV",
        "creator_volunteer_rating_count": "Số đánh giá TNV",
        "creator_avg_campaign_participation": "TB TNV tham gia",
        "creator_report_count": "Số báo cáo",
        "creator_location_complete": "Địa điểm người tạo đầy đủ",
        "creator_profile_completeness": "Hoàn thiện hồ sơ người tạo",
        "creator_ky_nang_count": "Số kỹ năng",
        "creator_chung_chi_count": "Số chứng chỉ",
        "creator_kinh_nghiem_count": "Số kinh nghiệm",
        "creator_is_active": "Tài khoản hoạt động",
        "is_created_during_office_hours": "Tạo trong giờ hành chính",
        "is_created_on_weekend": "Tạo vào cuối tuần",
        "is_created_late_night": "Tạo ban đêm",
        "creation_hour": "Giờ tạo",
        "creation_weekday": "Ngày trong tuần tạo",
        "content_edit_frequency": "Tần suất chỉnh sửa",
        "recent_edit_before_start": "Chỉnh sửa gần đây trước khi bắt đầu",
        "registration_to_start_ratio": "Tỷ lệ đăng ký / bắt đầu",
        "ghost_registration_suspicion": "Nghi vấn đăng ký ma",
        "vagueness_short_sentence_ratio": "Tỷ lệ câu ngắn mơ hồ",
        "vagueness_generic_phrase_count": "Số cụm từ chung chung",
        "vagueness_score": "Điểm mơ hồ",
        "safety_description_score": "Điểm mô tả an toàn",
    }

    VOLUNTEER_FEATURE_DISPLAY_NAMES = {
        "account_age_days": "Tuổi tài khoản",
        "is_new_account": "Tài khoản mới",
        "has_verified_email": "Email đã xác thực",
        "has_phone": "Có SĐT",
        "has_avatar": "Có ảnh đại diện",
        "has_bio": "Có giới thiệu bản thân",
        "days_since_last_activity": "Ngày từ hoạt động cuối",
        "registration_count": "Số lần đăng ký",
        "cancelled_registrations": "Số lần hủy đăng ký",
        "completed_registrations": "Số lần hoàn thành",
        "registration_cancellation_rate": "Tỷ lệ hủy đăng ký",
        "completion_rate": "Tỷ lệ hoàn thành",
        "no_show_rate": "Tỷ lệ không xác nhận",
        "late_cancellation_count": "Số lần hủy muộn",
        "avg_feedback_rating_given": "TB điểm đánh giá đã cho",
        "avg_rating_received": "TB điểm đánh giá nhận được",
        "rating_received_count": "Số đánh giá nhận được",
        "has_perfect_rating": "Toàn điểm 5 sao",
        "profile_completeness_score": "Điểm hoàn thiện hồ sơ",
        "has_certificates": "Có chứng chỉ",
        "has_experience": "Có kinh nghiệm",
        "has_skills": "Có kỹ năng",
    }

    def __init__(self, model_type: str = "campaign"):
        self.model_type = model_type
        self._explainer = None
        self._model = None
        self._feature_names: list[str] = []

    def set_model(self, model, feature_names: Optional[list[str]] = None):
        """
        Set the LightGBM model and initialize TreeExplainer.

        Args:
            model: LightGBM Booster model
            feature_names: List of feature names matching model columns
        """
        self._model = model
        self._feature_names = feature_names or []

        try:
            import shap
            self._explainer = shap.TreeExplainer(model)
            logger.debug(f"SHAP TreeExplainer initialized for {self.model_type} model")
        except ImportError:
            logger.warning("SHAP not available, using fallback explanations")
            self._explainer = None
        except Exception as e:
            logger.warning(f"Failed to initialize SHAP explainer: {e}")
            self._explainer = None

    def explain(
        self,
        features: dict[str, Any],
        feature_names: Optional[list[str]] = None,
        base_value: Optional[float] = None,
        top_n: int = 5,
    ) -> dict[str, Any]:
        """
        Generate SHAP explanation for a single prediction.

        Args:
            features: Feature dict from feature extractor
            feature_names: Ordered list of feature names (from model)
            base_value: Pre-computed base value (expected value)
            top_n: Number of top positive/negative factors to return

        Returns:
            SHAPExplanation dict with top factors, base_value, prediction
        """
        names = feature_names or self._feature_names
        if not names:
            return self._fallback_explanation(features)

        values = [features.get(fn, 0.0) for fn in names]

        # Try SHAP explanation
        if self._explainer is not None and self._model is not None:
            try:
                return self._shap_explanation(values, names, base_value, top_n)
            except Exception as e:
                logger.warning(f"SHAP explanation failed: {e}, using fallback")
                return self._fallback_explanation(features)

        return self._fallback_explanation(features)

    def _shap_explanation(
        self,
        values: list[float],
        feature_names: list[str],
        base_value: Optional[float],
        top_n: int,
    ) -> dict[str, Any]:
        """Compute SHAP values and build explanation."""
        import shap

        X = np.array([values], dtype=np.float64)

        # Get SHAP values
        shap_values = self._explainer.shap_values(X)
        # For binary classification, shap_values may be a list of [neg_class, pos_class]
        # We want the positive class (reliable) SHAP values
        if isinstance(shap_values, list):
            shap_vals = shap_values[1] if len(shap_values) > 1 else shap_values[0]
        else:
            shap_vals = shap_values[0] if shap_values.ndim > 1 else shap_values

        # Base value
        if base_value is None:
            try:
                base_value = float(self._explainer.expected_value)
                if isinstance(base_value, (list, np.ndarray)):
                    base_value = float(base_value[1]) if len(base_value) > 1 else float(base_value[0])
            except Exception:
                base_value = 0.5

        # Prediction = base + sum(shap_values)
        prediction = float(base_value + shap_vals.sum())
        prediction = max(0.0, min(1.0, prediction))

        # Build SHAP factor list
        display_map = (
            self.CAMPAIGN_FEATURE_DISPLAY_NAMES
            if self.model_type == "campaign"
            else self.VOLUNTEER_FEATURE_DISPLAY_NAMES
        )

        factors = []
        for i, (name, shap_val) in enumerate(zip(feature_names, shap_vals)):
            raw_val = values[i]
            factors.append({
                "feature": name,
                "feature_display_name": display_map.get(name, name),
                "contribution": float(shap_val),
                "value": float(raw_val) if raw_val is not None else None,
                "value_display": self._format_value(name, raw_val),
            })

        # Sort by absolute contribution
        factors_sorted = sorted(factors, key=lambda x: abs(x["contribution"]), reverse=True)

        # Separate positive (pushing toward reliable) and negative (pushing suspicious)
        pos_factors = [f for f in factors_sorted if f["contribution"] > 0.0001][:top_n]
        neg_factors = [f for f in factors_sorted if f["contribution"] < -0.0001]
        neg_factors = sorted(neg_factors, key=lambda x: x["contribution"])[:top_n]

        # Feature importance (by absolute SHAP value)
        importance = [
            {
                "feature": f["feature"],
                "feature_display_name": f["feature_display_name"],
                "shap_value": round(f["contribution"], 6),
                "abs_shap_value": round(abs(f["contribution"]), 6),
            }
            for f in factors_sorted[:20]
        ]

        return {
            "base_value": round(float(base_value), 4),
            "prediction": round(prediction, 4),
            "top_positive_factors": pos_factors,
            "top_negative_factors": neg_factors,
            "feature_importance": importance,
        }

    def _fallback_explanation(self, features: dict[str, Any]) -> dict[str, Any]:
        """
        Generate simplified explanation when SHAP is unavailable.

        Uses feature values directly to identify top positive/negative factors.
        """
        display_map = (
            self.CAMPAIGN_FEATURE_DISPLAY_NAMES
            if self.model_type == "campaign"
            else self.VOLUNTEER_FEATURE_DISPLAY_NAMES
        )

        # Known positive indicators (higher = more reliable)
        positive_indicators = [
            "has_cover_image", "has_location_coords", "creator_has_verified_email",
            "creator_has_avatar", "reg_deadline_reasonable", "has_contact_info_in_desc",
            "schedule_completeness", "skill_requirements_clarity", "creator_is_active",
            "coords_in_vietnam", "location_completeness", "creator_location_complete",
            "has_avatar", "has_phone", "has_verified_email", "has_bio",
            "has_certificates", "has_experience", "has_skills",
        ]

        # Known negative indicators (higher = more suspicious)
        negative_indicators = [
            "creator_previous_cancellation_rate", "creator_report_count",
            "ghost_registration_suspicion", "vagueness_score",
            "vagueness_short_sentence_ratio", "vagueness_generic_phrase_count",
            "registration_cancellation_rate", "no_show_rate",
            "is_created_late_night", "content_edit_frequency",
        ]

        factors = []
        for name, raw_val in features.items():
            if raw_val is None:
                continue

            # Positive contribution
            if name in positive_indicators:
                if isinstance(raw_val, bool):
                    contrib = 0.05 if raw_val else -0.02
                elif isinstance(raw_val, (int, float)):
                    contrib = float(raw_val) * 0.02
                else:
                    contrib = 0.0

                factors.append({
                    "feature": name,
                    "feature_display_name": display_map.get(name, name),
                    "contribution": contrib,
                    "value": bool(raw_val) if isinstance(raw_val, bool) else float(raw_val),
                    "value_display": self._format_value(name, raw_val),
                })

            # Negative contribution
            elif name in negative_indicators:
                if isinstance(raw_val, bool):
                    contrib = -0.05 if raw_val else 0.0
                elif isinstance(raw_val, (int, float)):
                    contrib = -float(raw_val) * 0.03
                else:
                    contrib = 0.0

                factors.append({
                    "feature": name,
                    "feature_display_name": display_map.get(name, name),
                    "contribution": contrib,
                    "value": float(raw_val) if raw_val is not None else None,
                    "value_display": self._format_value(name, raw_val),
                })

        # Sort by absolute contribution
        factors_sorted = sorted(factors, key=lambda x: abs(x["contribution"]), reverse=True)
        pos_factors = [f for f in factors_sorted if f["contribution"] > 0.0001][:5]
        neg_factors = sorted(
            [f for f in factors_sorted if f["contribution"] < -0.0001],
            key=lambda x: x["contribution"]
        )[:5]

        base_value = 0.5
        prediction = base_value + sum(f["contribution"] for f in factors)
        prediction = max(0.0, min(1.0, prediction))

        importance = [
            {
                "feature": f["feature"],
                "feature_display_name": f["feature_display_name"],
                "shap_value": round(f["contribution"], 6),
                "abs_shap_value": round(abs(f["contribution"]), 6),
            }
            for f in factors_sorted[:20]
        ]

        return {
            "base_value": base_value,
            "prediction": round(prediction, 4),
            "top_positive_factors": pos_factors,
            "top_negative_factors": neg_factors,
            "feature_importance": importance,
        }

    @staticmethod
    def _format_value(name: str, value: Any) -> str:
        """Format a feature value for human-readable display."""
        if value is None:
            return "N/A"

        if isinstance(value, bool):
            return "Có" if value else "Không"

        if isinstance(value, float):
            # Percentages
            if name.endswith("_rate") or name.endswith("_ratio") or name.endswith("_score"):
                return f"{value:.1%}"
            # Counts
            if name.endswith("_count") or name.endswith("_days"):
                return f"{value:.0f}"
            # Probabilities / scores
            return f"{value:.2f}"

        if isinstance(value, int):
            if name.endswith("_days"):
                return f"{value} ngày"
            return str(value)

        return str(value)


# Global explainer instances (lazy-initialized)
_campaign_explainer: Optional[SHAPExplainer] = None
_volunteer_explainer: Optional[SHAPExplainer] = None


def get_campaign_shap_explainer() -> SHAPExplainer:
    global _campaign_explainer
    if _campaign_explainer is None:
        _campaign_explainer = SHAPExplainer(model_type="campaign")
    return _campaign_explainer


def get_volunteer_shap_explainer() -> SHAPExplainer:
    global _volunteer_explainer
    if _volunteer_explainer is None:
        _volunteer_explainer = SHAPExplainer(model_type="volunteer")
    return _volunteer_explainer

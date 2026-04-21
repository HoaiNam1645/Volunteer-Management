"""
Campaign Feature Extractor - Trích xuất features từ campaign data và creator data.

Nhóm 1 - Campaign Features (đặc trưng chiến dịch)
Nhóm 2 - Creator Features (uy tín người tạo)
Nhóm 3 - Behavioral Features (hành vi)
Nhóm 4 - Content Quality (chất lượng nội dung)
"""

import re
from datetime import datetime, date, timezone
from typing import Optional, Any


class CampaignFeatureExtractor:
    """Trích xuất feature vector từ campaign + creator data."""

    # Vietnam geographic boundary
    VIETNAM_LAT_MIN = 8.4
    VIETNAM_LAT_MAX = 23.4
    VIETNAM_LNG_MIN = 102.1
    VIETNAM_LNG_MAX = 109.5

    def __init__(self, campaign: dict, creator: Optional[dict] = None,
                 registrations: Optional[list[dict]] = None,
                 ratings: Optional[list[dict]] = None,
                 reports: Optional[list[dict]] = None,
                 review_history: Optional[list[dict]] = None,
                 feedbacks: Optional[list[dict]] = None):
        self.campaign = campaign
        self.creator = creator or {}
        self.registrations = registrations or []
        self.ratings = ratings or []
        self.reports = reports or []
        self.review_history = review_history or []
        self.feedbacks = feedbacks or []
        self.today = date.today()

    def extract(self) -> dict[str, Any]:
        """Trích xuất tất cả features và trả về dict."""
        features = {}

        # Nhóm 1: Campaign Features
        features.update(self._extract_campaign_features())

        # Nhóm 2: Creator Features
        features.update(self._extract_creator_features())

        # Nhóm 3: Behavioral Features
        features.update(self._extract_behavioral_features())

        # Nhóm 4: Content Quality Features (text analysis)
        features.update(self._extract_content_quality_features())

        return features

    # ============================================================
    # NHÓM 1: CAMPAIGN FEATURES
    # ============================================================

    def _extract_campaign_features(self) -> dict[str, Any]:
        c = self.campaign
        features = {}

        # --- Basic Info ---
        features["has_cover_image"] = bool(c.get("anh_bia"))
        features["gallery_image_count"] = 0  # placeholder: gallery table not available yet

        # --- Description Length ---
        desc = c.get("mo_ta") or ""
        features["description_length"] = len(desc)
        features["description_word_count"] = len(desc.split()) if desc else 0

        # --- Description Quality Score (Jaccard-like similarity) ---
        desc_lower = desc.lower()
        good_keywords = [
            "tình nguyện", "hỗ trợ", "cộng đồng", "giúp đỡ", "bảo vệ",
            "môi trường", "giáo dục", "y tế", "an sinh", "xã hội",
            "vệ sinh", "quyên góp", "hiến máu", "dạy học", "người già",
            "trẻ em", "khuyết tật", "phụ nữ", "nghèo", "đói",
        ]
        matches = sum(1 for kw in good_keywords if kw in desc_lower)
        features["description_quality_score"] = min(1.0, matches / 10.0)

        # --- Location Completeness ---
        has_address = bool(c.get("dia_diem"))
        has_coords = c.get("vi_do") is not None and c.get("kinh_do") is not None
        features["location_completeness"] = (0.0 if not has_address
                                             else 0.5 if has_address and not has_coords
                                             else 1.0 if has_address and has_coords
                                             else 0.0)
        features["has_location_coords"] = has_coords
        features["has_address"] = has_address

        # --- Vietnam coordinate validation ---
        lat = c.get("vi_do")
        lng = c.get("kinh_do")
        if lat is not None and lng is not None:
            features["coords_in_vietnam"] = (
                self.VIETNAM_LAT_MIN <= lat <= self.VIETNAM_LAT_MAX
                and self.VIETNAM_LNG_MIN <= lng <= self.VIETNAM_LNG_MAX
            )
        else:
            features["coords_in_vietnam"] = None

        # --- Schedule Completeness ---
        has_start = c.get("ngay_bat_dau") is not None
        has_end = c.get("ngay_ket_thuc") is not None
        features["schedule_completeness"] = 1.0 if (has_start and has_end) else 0.0

        # --- Temporal features ---
        start_date = self._parse_date(c.get("ngay_bat_dau"))
        end_date = self._parse_date(c.get("ngay_ket_thuc"))
        reg_deadline = self._parse_date(c.get("han_dang_ky"))

        if start_date:
            features["days_until_start"] = (start_date - self.today).days
        else:
            features["days_until_start"] = None

        if start_date and end_date:
            features["campaign_duration_days"] = (end_date - start_date).days
        else:
            features["campaign_duration_days"] = None

        # --- Registration window ---
        if reg_deadline and start_date:
            features["registration_window_days"] = (start_date - reg_deadline).days
        else:
            features["registration_window_days"] = None

        # Registration deadline reasonable (> 3 days before start)
        if features["registration_window_days"] is not None:
            features["reg_deadline_reasonable"] = features["registration_window_days"] >= 3
        else:
            features["reg_deadline_reasonable"] = None

        # --- Team size feasibility ---
        max_vol = c.get("so_luong_toi_da")
        min_vol = c.get("so_luong_toi_thieu")
        duration = features["campaign_duration_days"]

        if max_vol and duration and duration > 0:
            # Reasonable if max volunteers per day <= 50
            features["team_size_feasibility"] = max_vol / duration <= 50
        else:
            features["team_size_feasibility"] = None

        features["max_volunteers"] = max_vol
        features["min_volunteers"] = min_vol
        features["volunteer_range_valid"] = (
            (max_vol is not None and min_vol is not None and max_vol >= min_vol >= 1)
        )

        # --- Priority ---
        features["is_urgent_priority"] = c.get("muc_do_uu_tien") == "khan_cap"

        # --- Contact info in description ---
        contact_keywords = ["email", "điện thoại", "số điện thoại", "liên hệ",
                            "hotline", "phone", "gọi"]
        features["has_contact_info_in_desc"] = any(
            kw in desc_lower for kw in contact_keywords
        )

        # --- External URLs in description ---
        url_pattern = re.compile(
            r'https?://[^\s<>"{}|\\^`\[\]]+', re.IGNORECASE
        )
        urls = url_pattern.findall(desc)
        features["text_contains_external_urls"] = len(urls) > 0
        features["external_url_count"] = len(urls)

        # --- Skill requirements clarity ---
        skill_keywords = ["kỹ năng", "kinh nghiệm", "yêu cầu", "điều kiện",
                         "chứng chỉ", "năng lực"]
        features["skill_requirements_clarity"] = any(
            kw in desc_lower for kw in skill_keywords
        )

        # --- Campaign status ---
        features["campaign_status"] = c.get("trang_thai")

        # --- Registration stats ---
        features["registration_count"] = c.get("so_dang_ky", 0)
        features["confirmed_count"] = c.get("so_xac_nhan", 0)
        if max_vol and max_vol > 0:
            features["registration_ratio"] = features["registration_count"] / max_vol
        else:
            features["registration_ratio"] = None
        if features["registration_count"] > 0:
            features["confirmation_ratio"] = (
                features["confirmed_count"] / features["registration_count"]
            )
        else:
            features["confirmation_ratio"] = None

        return features

    # ============================================================
    # NHÓM 2: CREATOR FEATURES
    # ============================================================

    def _extract_creator_features(self) -> dict[str, Any]:
        cr = self.creator
        features = {}

        if not cr or not cr.get("id"):
            return self._empty_creator_features()

        # --- Account age ---
        created_at = self._parse_date(cr.get("tao_luc"))
        if created_at:
            features["creator_account_age_days"] = (self.today - created_at).days
        else:
            features["creator_account_age_days"] = None

        # --- Identity verification ---
        features["creator_has_verified_email"] = cr.get("xac_thuc_email_luc") is not None
        features["creator_has_verified_phone"] = bool(cr.get("so_dien_thoai"))
        features["creator_has_avatar"] = bool(cr.get("anh_dai_dien"))
        features["creator_has_bio"] = bool(cr.get("gioi_thieu"))

        # --- Campaign history ---
        features["creator_campaign_count"] = cr.get("campaign_count", 0)
        features["creator_campaign_approval_rate"] = cr.get("campaign_approval_rate", 0.0)
        features["creator_previous_cancellation_rate"] = cr.get(
            "campaign_cancellation_rate", 0.0
        )

        # --- Creator ratings from volunteers ---
        if self.ratings:
            ratings_values = [r.get("so_sao") for r in self.ratings if r.get("so_sao")]
            features["creator_volunteer_rating_avg"] = (
                sum(ratings_values) / len(ratings_values) if ratings_values else None
            )
            features["creator_volunteer_rating_count"] = len(ratings_values)
        else:
            features["creator_volunteer_rating_avg"] = None
            features["creator_volunteer_rating_count"] = 0

        # --- Average participation ---
        features["creator_avg_campaign_participation"] = cr.get("avg_participation")

        # --- Creator reports ---
        features["creator_report_count"] = len(self.reports)

        # --- Creator location ---
        features["creator_location_complete"] = (
            bool(cr.get("tinh_thanh_id")) and
            cr.get("vi_do") is not None and cr.get("kinh_do") is not None
        )

        # --- Creator profile completeness ---
        profile_fields = [
            cr.get("ho_ten"),
            cr.get("email"),
            cr.get("so_dien_thoai"),
            cr.get("anh_dai_dien"),
            cr.get("gioi_thieu"),
        ]
        features["creator_profile_completeness"] = (
            sum(1 for f in profile_fields if f) / len(profile_fields)
        )

        # --- Creator skills/certs/experience ---
        features["creator_ky_nang_count"] = cr.get("ky_nang_count", 0)
        features["creator_chung_chi_count"] = cr.get("chung_chi_count", 0)
        features["creator_kinh_nghiem_count"] = cr.get("kinh_nghiem_count", 0)

        # --- Creator account status ---
        features["creator_is_active"] = cr.get("trang_thai") == "hoat_dong"

        return features

    def _empty_creator_features(self) -> dict[str, Any]:
        return {
            "creator_account_age_days": None,
            "creator_has_verified_email": False,
            "creator_has_verified_phone": False,
            "creator_has_avatar": False,
            "creator_has_bio": False,
            "creator_campaign_count": 0,
            "creator_campaign_approval_rate": 0.0,
            "creator_previous_cancellation_rate": 0.0,
            "creator_volunteer_rating_avg": None,
            "creator_volunteer_rating_count": 0,
            "creator_avg_campaign_participation": None,
            "creator_report_count": 0,
            "creator_location_complete": False,
            "creator_profile_completeness": 0.0,
            "creator_ky_nang_count": 0,
            "creator_chung_chi_count": 0,
            "creator_kinh_nghiem_count": 0,
            "creator_is_active": False,
        }

    # ============================================================
    # NHÓM 3: BEHAVIORAL FEATURES
    # ============================================================

    def _extract_behavioral_features(self) -> dict[str, Any]:
        features = {}

        # --- Campaign creation time analysis ---
        created_at = self.campaign.get("tao_luc")
        if created_at:
            if isinstance(created_at, str):
                try:
                    dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                except ValueError:
                    dt = None
            else:
                dt = created_at
        else:
            dt = None

        if dt:
            hour = dt.hour
            weekday = dt.weekday()  # 0=Mon, 5=Sat, 6=Sun

            features["is_created_during_office_hours"] = 8 <= hour < 18
            features["is_created_on_weekend"] = weekday >= 5
            features["is_created_late_night"] = 2 <= hour < 5
            features["creation_hour"] = hour
            features["creation_weekday"] = weekday
        else:
            features["is_created_during_office_hours"] = None
            features["is_created_on_weekend"] = None
            features["is_created_late_night"] = None
            features["creation_hour"] = None
            features["creation_weekday"] = None

        # --- Content edit frequency (placeholder - review history) ---
        features["content_edit_frequency"] = len(self.review_history)

        # --- Recent edit before start (within 48h) ---
        if self.review_history:
            last_edit = self.review_history[-1].get("created_at") if self.review_history else None
            if last_edit and self.campaign.get("ngay_bat_dau"):
                edit_date = self._parse_date(last_edit)
                start_date = self._parse_date(self.campaign.get("ngay_bat_dau"))
                if edit_date and start_date:
                    # So sánh bằng ngày thay vì giờ (date object không có total_seconds)
                    days_before = (start_date - edit_date).days
                    features["recent_edit_before_start"] = 0 < days_before <= 2
                else:
                    features["recent_edit_before_start"] = None
            else:
                features["recent_edit_before_start"] = None
        else:
            features["recent_edit_before_start"] = False

        # --- Registration-to-start ratio ---
        max_vol = self.campaign.get("so_luong_toi_da", 0)
        reg_count = self.campaign.get("so_dang_ky", 0)
        if max_vol and max_vol > 0:
            features["registration_to_start_ratio"] = reg_count / max_vol
        else:
            features["registration_to_start_ratio"] = None

        # --- Ghost registrations: high reg ratio but low confirm ratio ---
        reg_ratio = features.get("registration_to_start_ratio")
        confirm_ratio = features.get("confirmation_ratio")
        if reg_ratio is not None and confirm_ratio is not None:
            features["ghost_registration_suspicion"] = (
                reg_ratio > 0.9 and confirm_ratio < 0.3
            )
        else:
            features["ghost_registration_suspicion"] = False

        return features

    # ============================================================
    # NHÓM 4: CONTENT QUALITY FEATURES (NLP)
    # ============================================================

    def _extract_content_quality_features(self) -> dict[str, Any]:
        features = {}

        desc = self.campaign.get("mo_ta") or ""
        title = self.campaign.get("tieu_de") or ""
        full_text = f"{title} {desc}".lower()

        # --- External URLs ---
        url_pattern = re.compile(
            r'https?://[^\s<>"{}|\\^`\[\]]+', re.IGNORECASE
        )
        urls = url_pattern.findall(desc)
        features["text_contains_external_urls"] = len(urls) > 0
        features["external_url_count"] = len(urls)

        # --- Vagueness Score ---
        # Sentences shorter than 10 chars, generic phrases ratio
        sentences = re.split(r'[.!?\n]+', desc)
        short_sentences = sum(1 for s in sentences if len(s.strip()) < 10)
        total_sentences = len([s for s in sentences if s.strip()])
        features["vagueness_short_sentence_ratio"] = (
            short_sentences / total_sentences if total_sentences > 0 else 0.0
        )

        generic_phrases = [
            "sẽ được thông báo", "sẽ báo sau", "đặc biệt", "đặc biệt lắm",
            "rất ý nghĩa", "cực kỳ hay", "tuyệt vời", "vô cùng tốt",
            "không có gì đặc biệt", "bình thường", "như mọi khi",
        ]
        generic_count = sum(1 for ph in generic_phrases if ph in full_text)
        features["vagueness_generic_phrase_count"] = generic_count
        features["vagueness_score"] = min(1.0, (
            features["vagueness_short_sentence_ratio"] * 0.5 +
            min(1.0, generic_count / 3) * 0.5
        ))

        # --- Safety description ---
        safety_keywords = [
            "phương án an toàn", "an toàn", "phòng tránh", "sơ cứu",
            "bảo hộ", "ppe", "thiết bị an toàn", "quy định an toàn",
            "hướng dẫn an toàn", "chữa cháy", "thoát hiểm",
        ]
        safety_patterns = [
            "phương án an toàn", "sơ cấp cứu", "thiết bị bảo hộ",
            "hướng dẫn an toàn", "quy trình an toàn",
        ]

        safety_count = sum(1 for kw in safety_keywords if kw in full_text)
        safety_pattern_count = sum(1 for p in safety_patterns if p in full_text)

        if safety_pattern_count >= 2:
            features["safety_description_score"] = 1.0
        elif safety_count > 0:
            features["safety_description_score"] = 0.5
        else:
            features["safety_description_score"] = 0.0

        return features

    # ============================================================
    # HELPER METHODS
    # ============================================================

    def _parse_date(self, value: Any) -> Optional[date]:
        """Parse various date formats to date object."""
        if value is None:
            return None
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        if isinstance(value, str):
            for fmt in ("%Y-%m-%d", "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
                try:
                    return datetime.strptime(value[:19], fmt).date()
                except ValueError:
                    pass
        return None


class VolunteerFeatureExtractor:
    """Trích xuất features từ volunteer (nguoi_dung) data."""

    def __init__(self, volunteer: dict,
                 registrations: Optional[list[dict]] = None,
                 ratings_given: Optional[list[dict]] = None,
                 ratings_received: Optional[list[dict]] = None):
        self.volunteer = volunteer
        self.registrations = registrations or []
        self.ratings_given = ratings_given or []
        self.ratings_received = ratings_received or []
        self.today = date.today()

    def extract(self) -> dict[str, Any]:
        features = {}
        features.update(self._extract_basic_features())
        features.update(self._extract_behavior_features())
        features.update(self._extract_profile_features())
        return features

    def _extract_basic_features(self) -> dict[str, Any]:
        v = self.volunteer
        features = {}

        # Account age
        created_at = v.get("tao_luc")
        if created_at:
            if isinstance(created_at, str):
                try:
                    created_date = datetime.fromisoformat(created_at.replace("Z", "+00:00")).date()
                except ValueError:
                    created_date = None
            elif isinstance(created_at, datetime):
                created_date = created_at.date()
            elif isinstance(created_at, date):
                created_date = created_at
            else:
                created_date = None
        else:
            created_date = None

        features["account_age_days"] = (
            (self.today - created_date).days if created_date else None
        )
        features["is_new_account"] = (
            features["account_age_days"] is not None
            and features["account_age_days"] < 7
        )

        # Verification
        features["has_verified_email"] = v.get("xac_thuc_email_luc") is not None
        features["has_phone"] = bool(v.get("so_dien_thoai"))
        features["has_avatar"] = bool(v.get("anh_dai_dien"))
        features["has_bio"] = bool(v.get("gioi_thieu"))

        # Last activity
        last_activity = v.get("last_activity_at")
        if last_activity:
            if isinstance(last_activity, str):
                try:
                    last_date = datetime.fromisoformat(last_activity.replace("Z", "+00:00")).date()
                except ValueError:
                    last_date = None
            elif isinstance(last_activity, datetime):
                last_date = last_activity.date()
            elif isinstance(last_activity, date):
                last_date = last_activity
            else:
                last_date = None
        else:
            last_date = None

        features["days_since_last_activity"] = (
            (self.today - last_date).days if last_date else None
        )

        return features

    def _extract_behavior_features(self) -> dict[str, Any]:
        features = {}

        total_reg = len(self.registrations)
        cancelled = sum(
            1 for r in self.registrations
            if r.get("trang_thai") in ("da_huy", "huy")
        )
        completed = sum(
            1 for r in self.registrations
            if r.get("trang_thai") in ("hoan_thanh", "completed")
        )
        confirmed = sum(
            1 for r in self.registrations
            if r.get("trang_thai") in ("da_duyet", "da_xac_nhan", "dang_tham_gia")
        )
        no_show = sum(
            1 for r in self.registrations
            if r.get("trang_thai") == "khong_xac_nhan"
        )

        features["registration_count"] = total_reg
        features["cancelled_registrations"] = cancelled
        features["completed_registrations"] = completed

        features["registration_cancellation_rate"] = (
            cancelled / total_reg if total_reg > 0 else 0.0
        )
        features["completion_rate"] = (
            completed / total_reg if total_reg > 0 else 0.0
        )
        features["no_show_rate"] = (
            no_show / total_reg if total_reg > 0 else 0.0
        )

        # Late cancellation (within 3 days before event)
        late_cancel = sum(
            1 for r in self.registrations
            if r.get("trang_thai") in ("da_huy", "huy") and
            r.get("huy_luc") is not None
        )
        features["late_cancellation_count"] = late_cancel

        # Ratings given
        if self.ratings_given:
            ratings_values = [r.get("so_sao") for r in self.ratings_given if r.get("so_sao")]
            features["avg_feedback_rating_given"] = (
                sum(ratings_values) / len(ratings_values) if ratings_values else None
            )
        else:
            features["avg_feedback_rating_given"] = None

        # Ratings received
        if self.ratings_received:
            rec_values = [r.get("so_sao") for r in self.ratings_received if r.get("so_sao")]
            features["avg_rating_received"] = (
                sum(rec_values) / len(rec_values) if rec_values else None
            )
            features["rating_received_count"] = len(rec_values)
        else:
            features["avg_rating_received"] = None
            features["rating_received_count"] = 0

        # Perfect rating flag
        features["has_perfect_rating"] = (
            features["avg_rating_received"] is not None
            and features["avg_rating_received"] >= 4.9
            and features["rating_received_count"] >= 5
        )

        return features

    def _extract_profile_features(self) -> dict[str, Any]:
        v = self.volunteer
        features = {}

        profile_fields = [
            v.get("ho_ten"),
            v.get("email"),
            v.get("so_dien_thoai"),
            v.get("anh_dai_dien"),
            v.get("ngay_sinh"),
            v.get("gioi_tinh"),
            v.get("dia_chi_duong"),
            v.get("vi_do"),
            v.get("kinh_do"),
        ]
        features["profile_completeness_score"] = (
            sum(1 for f in profile_fields if f) / len(profile_fields)
        )

        # Competency fields
        features["has_certificates"] = v.get("chung_chi_count", 0) > 0
        features["has_experience"] = v.get("kinh_nghiem_count", 0) > 0
        features["has_skills"] = v.get("ky_nang_count", 0) > 0

        return features

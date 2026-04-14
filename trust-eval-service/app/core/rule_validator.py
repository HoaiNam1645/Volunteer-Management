"""
Rule-based Validation Layer - Kiểm tra điều kiện bắt buộc của chiến dịch.

Áp dụng Pydantic validation để kiểm tra dữ liệu đầu vào.
Nếu có lỗi CRITICAL, chiến dịch không được chuyển sang ML evaluation.
"""

from datetime import date, datetime
from typing import Optional, Any


class ValidationRule:
    """Một rule kiểm tra đơn lẻ."""

    def __init__(self, code: str, severity: str, field: str,
                 message: str, suggestion: str, auto_resolvable: bool = False):
        self.code = code
        self.severity = severity  # CRITICAL, HIGH, MEDIUM, LOW
        self.field = field
        self.message = message
        self.suggestion = suggestion
        self.auto_resolvable = auto_resolvable

    def to_dict(self) -> dict:
        return {
            "code": self.code,
            "severity": self.severity,
            "category": self._infer_category(),
            "field": self.field,
            "message": self.message,
            "suggestion": self.suggestion,
            "auto_resolvable": self.auto_resolvable,
        }

    def _infer_category(self) -> str:
        """Infer category from code prefix."""
        mapping = {
            "TITLE": "INFORMATION_COMPLETENESS",
            "DESC": "INFORMATION_COMPLETENESS",
            "LOCATION": "LOCATION",
            "COORDS": "LOCATION",
            "DATE": "SCHEDULE_REASONABLENESS",
            "TIME": "SCHEDULE_REASONABLENESS",
            "REG": "SCHEDULE_REASONABLENESS",
            "COUNT": "INFORMATION_COMPLETENESS",
            "CREATOR": "CREATOR_RELIABILITY",
            "USER": "CREATOR_RELIABILITY",
            "TYPE": "INFORMATION_COMPLETENESS",
        }
        for prefix, cat in mapping.items():
            if self.code.startswith(prefix):
                return cat
        return "GENERAL"


class RuleBasedValidator:
    """
    Kiểm tra tất cả các điều kiện bắt buộc của chiến dịch.

    Các rule:
    - CRITICAL: Dữ liệu không hợp lệ, không chuyển sang ML
    - HIGH: Rủi ro cao, đánh flag
    - MEDIUM: Cần lưu ý
    - LOW: Cảnh báo nhẹ
    """

    VIETNAM_LAT_MIN = 8.4
    VIETNAM_LAT_MAX = 23.4
    VIETNAM_LNG_MIN = 102.1
    VIETNAM_LNG_MAX = 109.5

    def __init__(self, campaign: dict, creator: Optional[dict] = None):
        self.campaign = campaign
        self.creator = creator
        self.today = date.today()
        self.rules: list[ValidationRule] = []

    def validate(self) -> dict:
        """
        Chạy tất cả các rule và trả về kết quả.

        Returns:
            dict với keys:
            - passed: bool (True nếu không có CRITICAL errors)
            - critical_errors: list[dict]
            - warnings: list[dict]
        """
        self.rules = []

        self._validate_title()
        self._validate_description()
        self._validate_location()
        self._validate_coords()
        self._validate_schedule()
        self._validate_registration_deadline()
        self._validate_counts()
        self._validate_creator()
        self._validate_campaign_type()

        critical_errors = [
            r.to_dict() for r in self.rules
            if r.severity == "CRITICAL"
        ]
        warnings = [
            r.to_dict() for r in self.rules
            if r.severity != "CRITICAL"
        ]

        return {
            "passed": len(critical_errors) == 0,
            "critical_errors": critical_errors,
            "warnings": warnings,
        }

    # ============================================================
    # TITLE VALIDATION
    # ============================================================

    def _validate_title(self):
        title = self.campaign.get("tieu_de")
        title_len = len(title) if title else 0

        if not title or title_len == 0:
            self.rules.append(ValidationRule(
                "TITLE_EMPTY",
                "CRITICAL",
                "tieu_de",
                "Tên chiến dịch không được để trống",
                "Yêu cầu người tạo nhập tên chiến dịch",
                auto_resolvable=True,
            ))
            return

        if title_len < 10:
            self.rules.append(ValidationRule(
                "TITLE_TOO_SHORT",
                "MEDIUM",
                "tieu_de",
                f"Tên chiến dịch quá ngắn ({title_len} ký tự, tối thiểu 10)",
                "Tên chiến dịch nên có ít nhất 10 ký tự để mô tả rõ ràng",
                auto_resolvable=True,
            ))

        if title_len > 200:
            self.rules.append(ValidationRule(
                "TITLE_TOO_LONG",
                "LOW",
                "tieu_de",
                f"Tên chiến dịch quá dài ({title_len} ký tự, tối đa 200)",
                "Tên chiến dịch không nên quá 200 ký tự",
                auto_resolvable=True,
            ))

    # ============================================================
    # DESCRIPTION VALIDATION
    # ============================================================

    def _validate_description(self):
        desc = self.campaign.get("mo_ta")
        desc_len = len(desc) if desc else 0

        if not desc or desc_len == 0:
            self.rules.append(ValidationRule(
                "DESCRIPTION_EMPTY",
                "CRITICAL",
                "mo_ta",
                "Mô tả chiến dịch không được để trống",
                "Yêu cầu người tạo nhập mô tả chiến dịch chi tiết",
                auto_resolvable=True,
            ))
            return

        if desc_len < 50:
            self.rules.append(ValidationRule(
                "DESCRIPTION_TOO_SHORT",
                "HIGH",
                "mo_ta",
                f"Mô tả chiến dịch quá ngắn ({desc_len} ký tự, tối thiểu 50)",
                "Mô tả nên có ít nhất 50 ký tự để cung cấp đủ thông tin cho TNV",
                auto_resolvable=True,
            ))

    # ============================================================
    # LOCATION VALIDATION
    # ============================================================

    def _validate_location(self):
        location = self.campaign.get("dia_diem")
        if not location or len(str(location).strip()) == 0:
            self.rules.append(ValidationRule(
                "LOCATION_EMPTY",
                "CRITICAL",
                "dia_diem",
                "Địa điểm không được để trống",
                "Yêu cầu người tạo nhập địa điểm tổ chức chiến dịch",
                auto_resolvable=True,
            ))

    # ============================================================
    # COORDINATES VALIDATION
    # ============================================================

    def _validate_coords(self):
        lat = self.campaign.get("vi_do")
        lng = self.campaign.get("kinh_do")

        if lat is None or lng is None:
            self.rules.append(ValidationRule(
                "COORDS_MISSING",
                "MEDIUM",
                "vi_do/kinh_do",
                "Chiến dịch thiếu tọa độ địa điểm (vĩ độ/kinh độ)",
                "Yêu cầu người tạo bổ sung tọa độ GPS để xác định chính xác địa điểm",
                auto_resolvable=True,
            ))
            return

        # Validate Vietnam boundary
        if not (self.VIETNAM_LAT_MIN <= lat <= self.VIETNAM_LAT_MAX):
            self.rules.append(ValidationRule(
                "COORDS_OUTSIDE_VIETNAM",
                "HIGH",
                "vi_do",
                f"Vĩ độ {lat} nằm ngoài phạm vi Việt Nam (8.4-23.4)",
                "Kiểm tra lại tọa độ địa điểm, đảm bảo nằm trong lãnh thổ Việt Nam",
                auto_resolvable=False,
            ))

        if not (self.VIETNAM_LNG_MIN <= lng <= self.VIETNAM_LNG_MAX):
            self.rules.append(ValidationRule(
                "COORDS_OUTSIDE_VIETNAM",
                "HIGH",
                "kinh_do",
                f"Kinh độ {lng} nằm ngoài phạm vi Việt Nam (102.1-109.5)",
                "Kiểm tra lại tọa độ địa điểm, đảm bảo nằm trong lãnh thổ Việt Nam",
                auto_resolvable=False,
            ))

    # ============================================================
    # SCHEDULE VALIDATION
    # ============================================================

    def _parse_date(self, value: Any) -> Optional[date]:
        if value is None:
            return None
        if isinstance(value, date):
            return value if not isinstance(value, datetime) else value.date()
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, str):
            for fmt in ("%Y-%m-%d", "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S"):
                try:
                    return datetime.strptime(value[:10], fmt).date()
                except ValueError:
                    pass
        return None

    def _validate_schedule(self):
        start = self._parse_date(self.campaign.get("ngay_bat_dau"))
        end = self._parse_date(self.campaign.get("ngay_ket_thuc"))

        if start is None:
            self.rules.append(ValidationRule(
                "DATE_START_MISSING",
                "CRITICAL",
                "ngay_bat_dau",
                "Ngày bắt đầu không được để trống",
                "Yêu cầu người tạo nhập ngày bắt đầu chiến dịch",
                auto_resolvable=True,
            ))
            return

        if end is None:
            self.rules.append(ValidationRule(
                "DATE_END_MISSING",
                "CRITICAL",
                "ngay_ket_thuc",
                "Ngày kết thúc không được để trống",
                "Yêu cầu người tạo nhập ngày kết thúc chiến dịch",
                auto_resolvable=True,
            ))
            return

        if start < self.today:
            self.rules.append(ValidationRule(
                "DATE_START_IN_PAST",
                "CRITICAL",
                "ngay_bat_dau",
                f"Ngày bắt đầu ({start}) đã qua ngày hiện tại ({self.today})",
                "Ngày bắt đầu phải bằng hoặc sau ngày hiện tại",
                auto_resolvable=True,
            ))

        if end < start:
            self.rules.append(ValidationRule(
                "DATE_END_BEFORE_START",
                "CRITICAL",
                "ngay_ket_thuc",
                "Ngày kết thúc không thể trước ngày bắt đầu",
                "Kiểm tra lại ngày bắt đầu và ngày kết thúc chiến dịch",
                auto_resolvable=True,
            ))

        if start and end and (end - start).days > 365:
            self.rules.append(ValidationRule(
                "DATE_DURATION_TOO_LONG",
                "LOW",
                "ngay_ket_thuc",
                f"Thời gian chiến dịch quá dài ({(end - start).days} ngày)",
                "Xem xét chia chiến dịch thành nhiều giai đoạn ngắn hơn",
                auto_resolvable=False,
            ))

    # ============================================================
    # REGISTRATION DEADLINE VALIDATION
    # ============================================================

    def _validate_registration_deadline(self):
        reg_deadline = self._parse_date(self.campaign.get("han_dang_ky"))
        start = self._parse_date(self.campaign.get("ngay_bat_dau"))

        if reg_deadline is None:
            self.rules.append(ValidationRule(
                "REG_DEADLINE_MISSING",
                "HIGH",
                "han_dang_ky",
                "Hạn đăng ký không được để trống",
                "Yêu cầu người tạo đặt hạn đăng ký để TNV có thể lên kế hoạch",
                auto_resolvable=True,
            ))
            return

        if reg_deadline < self.today:
            self.rules.append(ValidationRule(
                "REG_DEADLINE_IN_PAST",
                "HIGH",
                "han_dang_ky",
                f"Hạn đăng ký ({reg_deadline}) đã qua",
                "Hạn đăng ký phải bằng hoặc sau ngày hiện tại",
                auto_resolvable=True,
            ))

        if start and reg_deadline > start:
            self.rules.append(ValidationRule(
                "REG_DEADLINE_AFTER_START",
                "HIGH",
                "han_dang_ky",
                "Hạn đăng ký không thể sau ngày bắt đầu",
                "Hạn đăng ký phải nằm trong khoảng [ngày hiện tại, ngày bắt đầu]",
                auto_resolvable=True,
            ))

        if start and reg_deadline and (start - reg_deadline).days < 1:
            self.rules.append(ValidationRule(
                "REG_DEADLINE_TOO_SHORT",
                "MEDIUM",
                "han_dang_ky",
                "Thời gian đăng ký quá ngắn (dưới 1 ngày)",
                "Nên để thời gian đăng ký ít nhất 3 ngày để thu hút TNV",
                auto_resolvable=True,
            ))

    # ============================================================
    # COUNT VALIDATION
    # ============================================================

    def _validate_counts(self):
        max_vol = self.campaign.get("so_luong_toi_da")
        min_vol = self.campaign.get("so_luong_toi_thieu")

        if max_vol is None or min_vol is None:
            self.rules.append(ValidationRule(
                "COUNT_MISSING",
                "HIGH",
                "so_luong_toi_da/so_luong_toi_thieu",
                "Số lượng tình nguyện viên không được để trống",
                "Yêu cầu người tạo nhập số lượng TNV cần tuyển",
                auto_resolvable=True,
            ))
            return

        if min_vol < 1:
            self.rules.append(ValidationRule(
                "COUNT_MIN_INVALID",
                "HIGH",
                "so_luong_toi_thieu",
                f"Số lượng tối thiểu ({min_vol}) phải >= 1",
                "Số lượng tối thiểu phải từ 1 trở lên",
                auto_resolvable=True,
            ))

        if max_vol < min_vol:
            self.rules.append(ValidationRule(
                "COUNT_MAX_LESS_THAN_MIN",
                "HIGH",
                "so_luong_toi_da",
                f"Số lượng tối đa ({max_vol}) nhỏ hơn số tối thiểu ({min_vol})",
                "Số lượng tối đa phải lớn hơn hoặc bằng số tối thiểu",
                auto_resolvable=True,
            ))

        if max_vol > 10000:
            self.rules.append(ValidationRule(
                "COUNT_MAX_TOO_LARGE",
                "MEDIUM",
                "so_luong_toi_da",
                f"Số lượng tối đa ({max_vol}) quá lớn, có thể không thực tế",
                "Kiểm tra lại số lượng TNV cần tuyển",
                auto_resolvable=False,
            ))

    # ============================================================
    # CREATOR VALIDATION
    # ============================================================

    def _validate_creator(self):
        creator_id = self.campaign.get("nguoi_tao_id")

        if not creator_id:
            self.rules.append(ValidationRule(
                "CREATOR_MISSING",
                "CRITICAL",
                "nguoi_tao_id",
                "Không tìm thấy thông tin người tạo chiến dịch",
                "Liên hệ quản trị viên để xác minh",
                auto_resolvable=False,
            ))
            return

        if not self.creator or not self.creator.get("id"):
            self.rules.append(ValidationRule(
                "CREATOR_NOT_FOUND",
                "CRITICAL",
                "nguoi_tao_id",
                f"Không tìm thấy người dùng với ID {creator_id}",
                "Kiểm tra lại thông tin người tạo chiến dịch",
                auto_resolvable=False,
            ))
            return

        # Creator status
        if self.creator.get("trang_thai") != "hoat_dong":
            self.rules.append(ValidationRule(
                "CREATOR_NOT_ACTIVE",
                "HIGH",
                "nguoi_tao_id",
                "Tài khoản người tạo không còn hoạt động",
                "Yêu cầu người tạo kích hoạt tài khoản trước khi duyệt chiến dịch",
                auto_resolvable=False,
            ))

        # Email verification
        if not self.creator.get("xac_thuc_email_luc"):
            self.rules.append(ValidationRule(
                "CREATOR_EMAIL_UNVERIFIED",
                "HIGH",
                "nguoi_tao_id",
                "Email người tạo chưa được xác thực",
                "Yêu cầu người tạo xác thực email trước khi duyệt chiến dịch",
                auto_resolvable=False,
            ))

    # ============================================================
    # CAMPAIGN TYPE VALIDATION
    # ============================================================

    def _validate_campaign_type(self):
        loai_id = self.campaign.get("loai_chien_dich_id")
        if not loai_id:
            self.rules.append(ValidationRule(
                "TYPE_MISSING",
                "HIGH",
                "loai_chien_dich_id",
                "Loại chiến dịch không được để trống",
                "Yêu cầu người tạo chọn loại chiến dịch phù hợp",
                auto_resolvable=True,
            ))

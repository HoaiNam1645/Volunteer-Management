"""
Risk Keyword Dictionary for Campaign Content Analysis.
Groups keywords by risk category and severity level.

Mức 1 (bắt buộc): Từ điển từ khóa rủi ro + luật phát hiện cụm từ nguy hiểm + đếm tần suất.
Mức 2 (nâng cao): TF-IDF vectorization + Logistic Regression (sẽ triển khai ở Phase 3).
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class RiskKeyword:
    keyword: str
    severity: str  # HIGH, MEDIUM, LOW
    category: str
    display_name: str
    description: str
    suggestion: str


RISK_KEYWORD_DICTIONARY: list[RiskKeyword] = [
    # === HIGH SEVERITY: Yêu cầu tiền trước ===
    RiskKeyword("chuyển khoản", "HIGH", "PAYMENT_REQUEST",
                "Yêu cầu chuyển khoản", "Phát hiện từ khóa 'chuyển khoản'",
                "Xác minh người tạo không yêu cầu TNV chuyển tiền trước khi tham gia"),
    RiskKeyword("đặt cọc", "HIGH", "PAYMENT_REQUEST",
                "Yêu cầu đặt cọc", "Phát hiện từ khóa 'đặt cọc'",
                "Xác minh đây không phải chi phí tham gia bất hợp pháp"),
    RiskKeyword("thu phí", "HIGH", "PAYMENT_REQUEST",
                "Thu phí tham gia", "Phát hiện từ khóa 'thu phí'",
                "Yêu cầu giải trình về khoản phí, kiểm tra giấy tờ hợp lệ"),
    RiskKeyword("phí tham gia", "HIGH", "PAYMENT_REQUEST",
                "Phí tham gia", "Phát hiện cụm từ 'phí tham gia'",
                "Kiểm tra chi phí có hợp lý và minh bạch không"),
    RiskKeyword("nộp tiền", "HIGH", "PAYMENT_REQUEST",
                "Yêu cầu nộp tiền", "Phát hiện từ khóa 'nộp tiền'",
                "Xác minh mục đích nộp tiền, yêu cầu hóa đơn nếu có"),
    RiskKeyword("trả trước", "HIGH", "PAYMENT_REQUEST",
                "Yêu cầu trả trước", "Phát hiện cụm từ 'trả trước'",
                "Chiến dịch tình nguyện không nên yêu cầu thanh toán trước"),
    RiskKeyword("thanh toán", "HIGH", "PAYMENT_REQUEST",
                "Yêu cầu thanh toán", "Phát hiện từ khóa 'thanh toán'",
                "Xác minh đây là chi phí hợp lệ hay không"),

    # === HIGH SEVERITY: Địa điểm mơ hồ ===
    RiskKeyword("sẽ thông báo sau", "HIGH", "VAGUE_LOCATION",
                "Địa điểm sẽ thông báo sau", "Phát hiện cụm từ 'sẽ thông báo sau'",
                "Yêu cầu người tạo cung cấp địa điểm cụ thể trước khi duyệt"),
    RiskKeyword("gửi địa điểm riêng", "HIGH", "VAGUE_LOCATION",
                "Gửi địa điểm riêng", "Phát hiện cụm từ 'gửi địa điểm riêng'",
                "Địa điểm phải công khai, không gửi riêng cho từng người"),
    RiskKeyword("gặp mặt trực tiếp sẽ nói", "HIGH", "VAGUE_LOCATION",
                "Gặp mặt trực tiếp", "Phát hiện cụm từ 'gặp mặt trực tiếp sẽ nói'",
                "Yêu cầu cung cấp địa điểm cụ thể ngay từ đầu"),
    RiskKeyword("địa điểm bí mật", "HIGH", "VAGUE_LOCATION",
                "Địa điểm bí mật", "Phát hiện cụm từ 'địa điểm bí mật'",
                "Yêu cầu người tạo công khai địa điểm tổ chức"),

    # === HIGH SEVERITY: Thông tin nhạy cảm ===
    RiskKeyword("cmnd", "HIGH", "SENSITIVE_INFO",
                "Yêu cầu CMND", "Phát hiện từ khóa 'cmnd' (Căn cước công dân)",
                "Không nên yêu cầu TNV cung cấp CMND trừ khi cần thiết và có lý do chính đáng"),
    RiskKeyword("cccd", "HIGH", "SENSITIVE_INFO",
                "Yêu cầu CCCD", "Phát hiện từ khóa 'cccd' (Căn cước công dân)",
                "Kiểm tra lý do yêu cầu CCCD, đảm bảo tuân thủ quy định bảo mật"),
    RiskKeyword("sao kê", "HIGH", "SENSITIVE_INFO",
                "Yêu cầu sao kê", "Phát hiện từ khóa 'sao kê' (sao kê tài khoản ngân hàng)",
                "Tuyệt đối không yêu cầu TNV cung cấp sao kê tài khoản"),
    RiskKeyword("tài khoản ngân hàng", "HIGH", "SENSITIVE_INFO",
                "Yêu cầu tài khoản ngân hàng", "Phát hiện cụm 'tài khoản ngân hàng'",
                "Không nên yêu cầu TNV cung cấp thông tin tài khoản ngân hàng"),

    # === MEDIUM SEVERITY: Bảo mật đáng ngờ ===
    RiskKeyword("bí mật", "MEDIUM", "SUSPICIOUS_SECURITY",
                "Nội dung bí mật", "Phát hiện từ khóa 'bí mật'",
                "Xác minh lý do chiến dịch cần giữ bí mật"),
    RiskKeyword("không tiết lộ", "MEDIUM", "SUSPICIOUS_SECURITY",
                "Không tiết lộ thông tin", "Phát hiện cụm từ 'không tiết lộ'",
                "Thông tin chiến dịch nên được công khai để TNV yên tâm"),
    RiskKeyword("không công khai", "MEDIUM", "SUSPICIOUS_SECURITY",
                "Không công khai", "Phát hiện cụm từ 'không công khai'",
                "Yêu cầu giải trình về việc không công khai thông tin"),
    RiskKeyword("chỉ người được chọn", "MEDIUM", "SUSPICIOUS_SECURITY",
                "Chỉ người được chọn", "Phát hiện cụm từ 'chỉ người được chọn'",
                "Kiểm tra xem có dấu hiệu phân biệt đối xử không"),

    # === MEDIUM SEVERITY: Nội dung mơ hồ ===
    RiskKeyword("hoạt động đặc biệt", "MEDIUM", "VAGUE_CONTENT",
                "Hoạt động đặc biệt", "Phát hiện cụm từ 'hoạt động đặc biệt'",
                "Yêu cầu mô tả cụ thể hoạt động sẽ thực hiện"),
    RiskKeyword("sự kiện đặc biệt", "MEDIUM", "VAGUE_CONTENT",
                "Sự kiện đặc biệt", "Phát hiện cụm từ 'sự kiện đặc biệt'",
                "Cần mô tả rõ sự kiện là gì, ai tổ chức, ở đâu"),
    RiskKeyword("ngày đặc biệt", "MEDIUM", "VAGUE_CONTENT",
                "Ngày đặc biệt", "Phát hiện cụm từ 'ngày đặc biệt'",
                "Xác minh ngày này là ngày gì, có giấy tờ chứng minh không"),

    # === MEDIUM SEVERITY: Liên hệ không chính thức ===
    RiskKeyword("zalo", "MEDIUM", "INFORMAL_CONTACT",
                "Liên hệ qua Zalo", "Phát hiện từ khóa 'zalo' là kênh liên hệ",
                "Zalo có thể là kênh liên hệ phụ, nhưng cần có email/điện thoại chính thức"),
    RiskKeyword("facebook", "MEDIUM", "INFORMAL_CONTACT",
                "Liên hệ qua Facebook", "Phát hiện từ khóa 'facebook'",
                "Facebook có thể là kênh phụ, cần có thông tin liên hệ chính thức"),
    RiskKeyword("messenger", "MEDIUM", "INFORMAL_CONTACT",
                "Liên hệ qua Messenger", "Phát hiện từ khóa 'messenger'",
                "Cần có kênh liên hệ chính thức như email hoặc điện thoại"),
    RiskKeyword("inbox", "MEDIUM", "INFORMAL_CONTACT",
                "Liên hệ qua inbox", "Phát hiện từ khóa 'inbox'",
                "Yêu cầu thông tin liên hệ công khai, không chỉ inbox riêng"),

    # === MEDIUM SEVERITY: Lừa đảo tiềm ẩn ===
    RiskKeyword("kiếm tiền", "MEDIUM", "POTENTIAL_SCAM",
                "Hứa hẹn kiếm tiền", "Phát hiện từ khóa 'kiếm tiền'",
                "Chiến dịch tình nguyện không nên hứa hẹn thu nhập"),
    RiskKeyword("lợi nhuận", "MEDIUM", "POTENTIAL_SCAM",
                "Đề cập lợi nhuận", "Phát hiện từ khóa 'lợi nhuận'",
                "Kiểm tra xem chiến dịch có mục đích thương mại không"),
    RiskKeyword("đầu tư", "MEDIUM", "POTENTIAL_SCAM",
                "Yêu cầu đầu tư", "Phát hiện từ khóa 'đầu tư'",
                "Chiến dịch tình nguyện không nên yêu cầu đầu tư"),
]


def build_keyword_map() -> dict[str, RiskKeyword]:
    """Build a lowercase keyword -> RiskKeyword lookup map."""
    keyword_map = {}
    for kw in RISK_KEYWORD_DICTIONARY:
        keyword_map[kw.keyword.lower()] = kw
    return keyword_map


def build_pattern_map() -> dict[str, RiskKeyword]:
    """Build pattern -> RiskKeyword map for multi-word phrases."""
    pattern_map = {}
    for kw in RISK_KEYWORD_DICTIONARY:
        if " " in kw.keyword:
            pattern_map[kw.keyword.lower()] = kw
    return pattern_map


def build_category_severity_map() -> dict[tuple[str, str], list[RiskKeyword]]:
    """Build (category, severity) -> [RiskKeyword] map."""
    cat_map: dict[tuple[str, str], list[RiskKeyword]] = {}
    for kw in RISK_KEYWORD_DICTIONARY:
        key = (kw.category, kw.severity)
        if key not in cat_map:
            cat_map[key] = []
        cat_map[key].append(kw)
    return cat_map


RISK_KEYWORD_MAP = build_keyword_map()
RISK_PATTERN_MAP = build_pattern_map()
RISK_CATEGORY_MAP = build_category_severity_map()

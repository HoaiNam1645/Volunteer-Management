"""
Content Analyzer - NLP-based Content Risk Analysis.

Mức 1 (cơ bản, bắt buộc): Từ điển từ khóa rủi ro + luật phát hiện cụm từ nguy hiểm + đếm tần suất.
Mức 2 (nâng cao): TF-IDF vectorization + Logistic Regression (sẽ triển khai ở Phase 3).
"""

import re
from typing import Optional

from app.core.risk_keywords import (
    RISK_KEYWORD_MAP,
    RISK_PATTERN_MAP,
    RiskKeyword,
)


class ContentAnalyzer:
    """
    Phân tích nội dung văn bản chiến dịch để phát hiện rủi ro.

    Bao gồm:
    - Risk keyword detection
    - Vagueness scoring
    - Safety description scoring
    - External URL detection
    """

    def __init__(self, title: str = "", description: str = ""):
        self.title = title
        self.description = description
        self.full_text = f"{title} {description}".lower()

    def analyze(self) -> dict:
        """
        Phân tích toàn diện nội dung.

        Returns:
            dict với keys:
            - text_risk_keyword_count: int
            - text_risk_score: float (0.0-1.0)
            - vagueness_score: float (0.0-1.0, cao = mơ hồ)
            - safety_description_score: float (0.0-1.0, cao = tốt)
            - risk_keywords_found: list of dict
            - has_suspicious_contact: bool
            - has_external_urls: bool
        """
        keywords_found = self._detect_risk_keywords()
        vagueness = self._calculate_vagueness_score()
        safety = self._calculate_safety_score()
        external_urls = self._detect_external_urls()
        suspicious_contact = self._detect_suspicious_contact_only()

        # Compute risk score
        risk_score = self._compute_risk_score(
            keywords_found, vagueness, safety, suspicious_contact
        )

        return {
            "text_risk_keyword_count": len(keywords_found),
            "text_risk_score": round(risk_score, 4),
            "vagueness_score": round(vagueness, 4),
            "safety_description_score": round(safety, 4),
            "risk_keywords_found": keywords_found,
            "has_suspicious_contact": suspicious_contact,
            "has_external_urls": external_urls,
        }

    def _detect_risk_keywords(self) -> list[dict]:
        """
        Detect all risk keywords in the text.

        Returns:
            List of dicts: [{keyword, severity, category, message, suggestion}]
        """
        found: list[dict] = []
        seen_keywords: set[str] = set()

        # 1. Multi-word patterns first
        for pattern, risk_kw in RISK_PATTERN_MAP.items():
            if pattern in self.full_text and pattern not in seen_keywords:
                found.append({
                    "keyword": risk_kw.keyword,
                    "severity": risk_kw.severity,
                    "category": risk_kw.category,
                    "display_name": risk_kw.display_name,
                    "description": risk_kw.description,
                    "suggestion": risk_kw.suggestion,
                    "match": pattern,
                })
                seen_keywords.add(pattern)

        # 2. Single-word keywords
        words = re.findall(r'\b\w+\b', self.full_text)
        for word in words:
            if word in RISK_KEYWORD_MAP and word not in seen_keywords:
                risk_kw = RISK_KEYWORD_MAP[word]
                found.append({
                    "keyword": risk_kw.keyword,
                    "severity": risk_kw.severity,
                    "category": risk_kw.category,
                    "display_name": risk_kw.display_name,
                    "description": risk_kw.description,
                    "suggestion": risk_kw.suggestion,
                    "match": word,
                })
                seen_keywords.add(word)

        return found

    def _detect_suspicious_contact_only(self) -> bool:
        """
        Detect if the only contact method is informal (zalo, facebook, etc.)
        without any official contact (email, phone).
        """
        informal_keywords = ["zalo", "facebook", "messenger", "inbox", "fb"]
        official_keywords = ["email", "điện thoại", "số điện thoại", "hotline",
                            "phone", "liên hệ"]

        has_informal = any(kw in self.full_text for kw in informal_keywords)
        has_official = any(kw in self.full_text for kw in official_keywords)

        return has_informal and not has_official

    def _detect_external_urls(self) -> bool:
        """Detect if text contains external URLs."""
        url_pattern = re.compile(
            r'https?://[^\s<>"{}|\\^`\[\]]+', re.IGNORECASE
        )
        return bool(url_pattern.search(self.description))

    def _calculate_vagueness_score(self) -> float:
        """
        Tính điểm mơ hồ của mô tả.
        Score càng cao = càng mơ hồ, không rõ ràng.
        """
        desc = self.description
        if not desc or len(desc.strip()) < 10:
            return 1.0

        score = 0.0

        # 1. Short sentence ratio
        sentences = re.split(r'[.!?\n]+', desc)
        sentences = [s.strip() for s in sentences if s.strip()]
        if sentences:
            short = sum(1 for s in sentences if len(s) < 15)
            short_ratio = short / len(sentences)
            score += short_ratio * 0.3

        # 2. Generic/meaningless phrases
        generic_phrases = [
            "sẽ được thông báo", "sẽ báo sau", "rất ý nghĩa", "cực kỳ hay",
            "tuyệt vời", "vô cùng tốt", "đặc biệt lắm", "bình thường",
            "như mọi khi", "hoạt động đặc biệt", "sự kiện đặc biệt",
            "ngày đặc biệt", "không có gì đặc biệt", "mọi thứ sẽ ổn",
            "chúng tôi sẽ", "tổ chức sẽ", "sẽ có", "có thể có",
            "có thể sẽ", "tùy", "tùy theo", "sẽ linh hoạt",
        ]
        generic_count = sum(1 for ph in generic_phrases if ph in self.full_text)
        generic_penalty = min(1.0, generic_count / 3) * 0.3
        score += generic_penalty

        # 3. Very short description
        word_count = len(desc.split())
        if word_count < 30:
            score += 0.2 * (1 - word_count / 30)

        # 4. Lack of specific details (no numbers, no locations)
        has_numbers = bool(re.search(r'\d+', desc))
        has_specific_location = any(
            kw in self.full_text
            for kw in ["quận", "huyện", "phường", "xã", "tỉnh", "thành phố",
                      "đường", "phố", "km", "m2"]
        )
        if not has_numbers:
            score += 0.1
        if not has_specific_location:
            score += 0.1

        return min(1.0, score)

    def _calculate_safety_score(self) -> float:
        """
        Tính điểm mô tả an toàn.
        Score càng cao = mô tả an toàn tốt.
        """
        text = self.full_text

        # Strong safety patterns (full descriptions)
        strong_patterns = [
            "phương án an toàn", "sơ cấp cứu", "thiết bị bảo hộ",
            "hướng dẫn an toàn", "quy trình an toàn", "phòng cháy chữa cháy",
            "bảo hộ lao động", "đào tạo an toàn", "kế hoạch sơ tán",
        ]
        # Weak patterns (mentions safety but no details)
        weak_patterns = [
            "an toàn", "phòng tránh", "bảo vệ", "cẩn thận",
        ]

        strong_count = sum(1 for p in strong_patterns if p in text)
        weak_count = sum(1 for p in weak_patterns if p in text)

        if strong_count >= 2:
            return 1.0
        elif strong_count == 1:
            return 0.8
        elif weak_count >= 2:
            return 0.5
        elif weak_count == 1:
            return 0.3
        else:
            return 0.0

    def _compute_risk_score(
        self,
        keywords_found: list[dict],
        vagueness_score: float,
        safety_score: float,
        suspicious_contact: bool,
    ) -> float:
        """
        Tổng hợp điểm rủi ro từ các yếu tố.
        Score càng cao = rủi ro cao.
        """
        score = 0.0

        # 1. Risk keywords by severity
        severity_weights = {
            "HIGH": 0.35,
            "MEDIUM": 0.20,
            "LOW": 0.10,
        }
        for kw in keywords_found:
            score += severity_weights.get(kw["severity"], 0.10)

        # 2. Vagueness penalty (high vagueness = higher risk)
        score += vagueness_score * 0.20

        # 3. Safety description bonus (high safety = lower risk)
        # safety_score: cao = tốt (1.0), thấp = xấu (0.0)
        # Nên trừ để khi safety cao → score giảm → rủi ro thấp
        score -= safety_score * 0.15

        # 4. Suspicious contact only
        if suspicious_contact:
            score += 0.10

        return min(1.0, score)


def format_risk_flags_from_analysis(
    analysis: dict,
    category_prefix: str = "CONTENT",
) -> list[dict]:
    """
    Chuyển đổi kết quả ContentAnalyzer thành RiskFlag format.
    """
    flags = []

    # High severity keyword flags
    for kw in analysis.get("risk_keywords_found", []):
        flags.append({
            "code": f"RISK_KEYWORD_{kw['keyword'].upper().replace(' ', '_')}",
            "severity": kw["severity"],
            "category": kw["category"],
            "message": f"Phát hiện từ khóa rủi ro: '{kw['keyword']}' trong nội dung",
            "suggestion": kw["suggestion"],
            "auto_resolvable": kw["severity"] != "HIGH",
        })

    # Vagueness flag
    if analysis.get("vagueness_score", 0) > 0.6:
        flags.append({
            "code": "VAGUE_DESCRIPTION",
            "severity": "MEDIUM",
            "category": "VAGUE_CONTENT",
            "message": "Mô tả chiến dịch có mức độ mơ hồ cao",
            "suggestion": "Yêu cầu người tạo mô tả chi tiết hơn về nội dung, địa điểm và hoạt động cụ thể",
            "auto_resolvable": True,
        })

    # Safety description flag
    if analysis.get("safety_description_score", 1.0) == 0.0:
        flags.append({
            "code": "NO_SAFETY_DESCRIPTION",
            "severity": "MEDIUM",
            "category": "SAFETY",
            "message": "Chiến dịch không có mô tả phương án an toàn",
            "suggestion": "Yêu cầu người tạo bổ sung mô tả về phương án an toàn, sơ cấp cứu hoặc thiết bị bảo hộ",
            "auto_resolvable": True,
        })
    elif analysis.get("safety_description_score", 1.0) == 0.5:
        flags.append({
            "code": "MINIMAL_SAFETY_DESCRIPTION",
            "severity": "LOW",
            "category": "SAFETY",
            "message": "Chiến dịch có đề cập an toàn nhưng không mô tả chi tiết",
            "suggestion": "Khuyến khích người tạo mô tả chi tiết phương án an toàn để tăng độ tin cậy",
            "auto_resolvable": True,
        })

    # Suspicious contact only flag
    if analysis.get("has_suspicious_contact", False):
        flags.append({
            "code": "INFORMAL_CONTACT_ONLY",
            "severity": "MEDIUM",
            "category": "INFORMAL_CONTACT",
            "message": "Chiến dịch chỉ cung cấp kênh liên hệ không chính thức (Zalo, Facebook) mà không có email/điện thoại",
            "suggestion": "Yêu cầu người tạo bổ sung email hoặc số điện thoại chính thức",
            "auto_resolvable": True,
        })

    # External URL flag (can be neutral or risky depending on context)
    if analysis.get("has_external_urls", False):
        flags.append({
            "code": "HAS_EXTERNAL_URLS",
            "severity": "LOW",
            "category": "EXTERNAL_LINKS",
            "message": "Mô tả chứa các liên kết bên ngoài",
            "suggestion": "Kiểm tra các liên kết để đảm bảo an toàn và phù hợp với nội dung chiến dịch",
            "auto_resolvable": False,
        })

    return flags

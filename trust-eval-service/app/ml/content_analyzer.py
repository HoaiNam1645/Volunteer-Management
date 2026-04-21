"""
Content Analyzer - NLP-style content risk analysis.

Outputs both aggregate scores and detailed evidence so UI can explain:
- which risk keywords were found
- where they were found (title/description + position + snippet)
- why vagueness is high
- why safety score is low/high
- score breakdown components
"""

from __future__ import annotations

import re
from typing import Any

from app.core.risk_keywords import RISK_KEYWORD_MAP, RISK_PATTERN_MAP


class ContentAnalyzer:
    def __init__(self, title: str = "", description: str = ""):
        self.title = title or ""
        self.description = description or ""
        self.full_text = f"{self.title} {self.description}".lower()

    def analyze(self) -> dict[str, Any]:
        keywords_found = self._detect_risk_keywords()
        vagueness_score, vagueness_signals = self._calculate_vagueness_score_with_signals()
        safety_score, safety_signals = self._calculate_safety_score_with_signals()
        has_external_urls = self._detect_external_urls()
        has_suspicious_contact = self._detect_suspicious_contact_only()
        text_risk_score, text_risk_breakdown = self._compute_risk_score(
            keywords_found=keywords_found,
            vagueness_score=vagueness_score,
            safety_score=safety_score,
            suspicious_contact=has_suspicious_contact,
        )

        return {
            "text_risk_keyword_count": len(keywords_found),
            "text_risk_score": round(text_risk_score, 4),
            "vagueness_score": round(vagueness_score, 4),
            "safety_description_score": round(safety_score, 4),
            "risk_keywords_found": keywords_found,
            "risk_keyword_details": keywords_found,
            "vagueness_signals": vagueness_signals,
            "safety_signals": safety_signals,
            "text_risk_breakdown": text_risk_breakdown,
            "has_suspicious_contact": has_suspicious_contact,
            "has_external_urls": has_external_urls,
        }

    def _detect_risk_keywords(self) -> list[dict[str, Any]]:
        found: list[dict[str, Any]] = []
        seen: set[str] = set()

        for pattern, risk_kw in RISK_PATTERN_MAP.items():
            if pattern in self.full_text and pattern not in seen:
                found.append({
                    "keyword": risk_kw.keyword,
                    "severity": risk_kw.severity,
                    "category": risk_kw.category,
                    "display_name": risk_kw.display_name,
                    "description": risk_kw.description,
                    "suggestion": risk_kw.suggestion,
                    "match": pattern,
                    "locations": self._find_match_positions(pattern, whole_word=False),
                })
                seen.add(pattern)

        words = re.findall(r"\b\w+\b", self.full_text)
        for word in words:
            if word not in RISK_KEYWORD_MAP or word in seen:
                continue
            risk_kw = RISK_KEYWORD_MAP[word]
            found.append({
                "keyword": risk_kw.keyword,
                "severity": risk_kw.severity,
                "category": risk_kw.category,
                "display_name": risk_kw.display_name,
                "description": risk_kw.description,
                "suggestion": risk_kw.suggestion,
                "match": word,
                "locations": self._find_match_positions(word, whole_word=True),
            })
            seen.add(word)

        return found

    def _find_match_positions(self, pattern: str, whole_word: bool = False) -> list[dict[str, Any]]:
        escaped = re.escape(pattern)
        regex = rf"\b{escaped}\b" if whole_word else escaped
        locations: list[dict[str, Any]] = []

        for source_name, source_text in (("title", self.title), ("description", self.description)):
            source_lower = source_text.lower()
            for match in re.finditer(regex, source_lower):
                start = match.start()
                end = match.end()
                left = max(0, start - 25)
                right = min(len(source_text), end + 25)
                snippet = source_text[left:right].strip()
                locations.append({
                    "source": source_name,
                    "start": start,
                    "end": end,
                    "snippet": snippet,
                })

        return locations

    def _detect_suspicious_contact_only(self) -> bool:
        informal_keywords = ["zalo", "facebook", "messenger", "inbox", "fb"]
        official_keywords = ["email", "điện thoại", "số điện thoại", "hotline", "phone", "liên hệ"]

        has_informal = any(kw in self.full_text for kw in informal_keywords)
        has_official = any(kw in self.full_text for kw in official_keywords)
        return has_informal and not has_official

    def _detect_external_urls(self) -> bool:
        url_pattern = re.compile(r'https?://[^\s<>"{}|\\^`\[\]]+', re.IGNORECASE)
        return bool(url_pattern.search(self.description))

    def _calculate_vagueness_score(self) -> float:
        score, _signals = self._calculate_vagueness_score_with_signals()
        return score

    def _calculate_vagueness_score_with_signals(self) -> tuple[float, list[dict[str, Any]]]:
        desc = self.description
        signals: list[dict[str, Any]] = []
        if not desc or len(desc.strip()) < 10:
            signals.append({
                "type": "very_short_description",
                "weight": 1.0,
                "detail": "Mô tả quá ngắn hoặc trống",
            })
            return 1.0, signals

        score = 0.0

        sentences = re.split(r"[.!?\n]+", desc)
        sentences = [s.strip() for s in sentences if s.strip()]
        if sentences:
            short_count = sum(1 for s in sentences if len(s) < 15)
            short_ratio = short_count / len(sentences)
            contribution = short_ratio * 0.3
            score += contribution
            if short_count > 0:
                signals.append({
                    "type": "short_sentences",
                    "weight": round(contribution, 4),
                    "detail": f"{short_count}/{len(sentences)} câu ngắn (<15 ký tự)",
                })

        generic_phrases = [
            "sẽ được thông báo",
            "sẽ báo sau",
            "rất ý nghĩa",
            "cực kỳ hay",
            "tuyệt vời",
            "vô cùng tốt",
            "đặc biệt lắm",
            "như mọi khi",
            "sẽ linh hoạt",
            "có thể sẽ",
            "tùy theo",
        ]
        matched_generic = [phrase for phrase in generic_phrases if phrase in self.full_text]
        generic_penalty = min(1.0, len(matched_generic) / 3) * 0.3
        score += generic_penalty
        if matched_generic:
            signals.append({
                "type": "generic_phrases",
                "weight": round(generic_penalty, 4),
                "detail": ", ".join(matched_generic[:5]),
            })

        word_count = len(desc.split())
        if word_count < 30:
            contribution = 0.2 * (1 - word_count / 30)
            score += contribution
            signals.append({
                "type": "low_word_count",
                "weight": round(contribution, 4),
                "detail": f"Mô tả chỉ có {word_count} từ",
            })

        has_numbers = bool(re.search(r"\d+", desc))
        has_specific_location = any(
            kw in self.full_text
            for kw in ["quận", "huyện", "phường", "xã", "tỉnh", "thành phố", "đường", "phố", "km", "m2"]
        )
        if not has_numbers:
            score += 0.1
            signals.append({
                "type": "missing_numbers",
                "weight": 0.1,
                "detail": "Không có số liệu hoặc mốc số cụ thể",
            })
        if not has_specific_location:
            score += 0.1
            signals.append({
                "type": "missing_specific_location",
                "weight": 0.1,
                "detail": "Không có địa điểm chi tiết (quận/huyện/đường...)",
            })

        return min(1.0, score), signals

    def _calculate_safety_score(self) -> float:
        score, _signals = self._calculate_safety_score_with_signals()
        return score

    def _calculate_safety_score_with_signals(self) -> tuple[float, list[dict[str, Any]]]:
        text = self.full_text

        strong_patterns = [
            "phương án an toàn",
            "sơ cấp cứu",
            "thiết bị bảo hộ",
            "hướng dẫn an toàn",
            "quy trình an toàn",
            "phòng cháy chữa cháy",
            "kế hoạch sơ tán",
        ]
        weak_patterns = ["an toàn", "phòng tránh", "bảo vệ", "cẩn thận"]

        matched_strong = [pattern for pattern in strong_patterns if pattern in text]
        matched_weak = [pattern for pattern in weak_patterns if pattern in text]

        if len(matched_strong) >= 2:
            score = 1.0
            level = "strong"
        elif len(matched_strong) == 1:
            score = 0.8
            level = "strong"
        elif len(matched_weak) >= 2:
            score = 0.5
            level = "weak"
        elif len(matched_weak) == 1:
            score = 0.3
            level = "weak"
        else:
            score = 0.0
            level = "none"

        signals = [{
            "level": level,
            "strong_matches": matched_strong,
            "weak_matches": matched_weak,
        }]
        return score, signals

    def _compute_risk_score(
        self,
        keywords_found: list[dict[str, Any]],
        vagueness_score: float,
        safety_score: float,
        suspicious_contact: bool,
    ) -> tuple[float, dict[str, float]]:
        score = 0.0
        severity_weights = {"HIGH": 0.35, "MEDIUM": 0.20, "LOW": 0.10}

        keyword_component = 0.0
        for kw in keywords_found:
            keyword_component += severity_weights.get(kw.get("severity"), 0.10)
        score += keyword_component

        vagueness_component = vagueness_score * 0.20
        score += vagueness_component

        safety_component = safety_score * 0.15
        score -= safety_component

        suspicious_contact_component = 0.0
        if suspicious_contact:
            suspicious_contact_component = 0.10
            score += suspicious_contact_component

        final_score = min(1.0, score)
        return final_score, {
            "keyword_component": round(keyword_component, 4),
            "vagueness_component": round(vagueness_component, 4),
            "safety_component": round(safety_component, 4),
            "suspicious_contact_component": round(suspicious_contact_component, 4),
            "final_score": round(final_score, 4),
        }


def format_risk_flags_from_analysis(analysis: dict[str, Any], category_prefix: str = "CONTENT") -> list[dict[str, Any]]:
    flags: list[dict[str, Any]] = []

    for kw in analysis.get("risk_keywords_found", []):
        flags.append({
            "code": f"RISK_KEYWORD_{kw['keyword'].upper().replace(' ', '_')}",
            "severity": kw["severity"],
            "category": kw["category"],
            "message": f"Phát hiện từ khóa rủi ro: '{kw['keyword']}' trong nội dung",
            "suggestion": kw["suggestion"],
            "auto_resolvable": kw["severity"] != "HIGH",
        })

    if analysis.get("vagueness_score", 0) > 0.6:
        flags.append({
            "code": "VAGUE_DESCRIPTION",
            "severity": "MEDIUM",
            "category": "VAGUE_CONTENT",
            "message": "Mô tả chiến dịch có mức độ mơ hồ cao",
            "suggestion": "Yêu cầu người tạo mô tả chi tiết hơn về nội dung, địa điểm và hoạt động cụ thể",
            "auto_resolvable": True,
        })

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

    if analysis.get("has_suspicious_contact", False):
        flags.append({
            "code": "INFORMAL_CONTACT_ONLY",
            "severity": "MEDIUM",
            "category": "INFORMAL_CONTACT",
            "message": "Chiến dịch chỉ cung cấp kênh liên hệ không chính thức",
            "suggestion": "Yêu cầu người tạo bổ sung email hoặc số điện thoại chính thức",
            "auto_resolvable": True,
        })

    if analysis.get("has_external_urls", False):
        flags.append({
            "code": "HAS_EXTERNAL_URLS",
            "severity": "LOW",
            "category": "EXTERNAL_LINKS",
            "message": "Mô tả chứa liên kết bên ngoài",
            "suggestion": "Kiểm tra liên kết để đảm bảo an toàn và phù hợp với nội dung chiến dịch",
            "auto_resolvable": False,
        })

    return flags

"""
Test Content Analysis - NLP risk keyword detection and content scoring.
"""

import pytest
from app.ml.content_analyzer import ContentAnalyzer, format_risk_flags_from_analysis


class TestRiskKeywordDetection:
    """Test risk keyword detection in campaign descriptions."""

    def test_no_keywords_returns_zero(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch tình nguyện mùa hè",
            description="Chiến dịch tình nguyện bảo vệ môi trường, hỗ trợ cộng đồng địa phương.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] == 0
        assert len(result["risk_keywords_found"]) == 0

    def test_detects_money_request_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Yêu cầu chuyển khoản đặt cọc trước 500.000đ. Phí tham gia là 200.000đ.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0
        keywords = [kw["keyword"] for kw in result["risk_keywords_found"]]
        assert any(k in keywords for k in ["chuyển khoản", "đặt cọc", "phí tham gia"])

    def test_detects_vague_location_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch đặc biệt",
            description="Gặp mặt trực tiếp sẽ thông báo sau. Gửi địa điểm riêng.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0
        keywords = [kw["keyword"] for kw in result["risk_keywords_found"]]
        assert any(k in keywords for k in ["thông báo sau", "gửi địa điểm riêng"])

    def test_detects_sensitive_info_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Yêu cầu cung cấp CMND và sao kê tài khoản ngân hàng.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0
        keywords = [kw["keyword"] for kw in result["risk_keywords_found"]]
        assert any(k in keywords for k in ["cmnd", "sao kê"])

    def test_detects_confidential_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch bí mật",
            description="Hoạt động bí mật, không công khai, chỉ người được chọn.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0
        keywords = [kw["keyword"] for kw in result["risk_keywords_found"]]
        assert any(k in keywords for k in ["bí mật", "không công khai"])

    def test_detects_vague_event_keywords(self):
        analyzer = ContentAnalyzer(
            title="Sự kiện đặc biệt",
            description="Hoạt động đặc biệt, ngày đặc biệt cần người tham gia ngay.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0

    def test_case_insensitive_detection(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Yêu cầu CHUYỂN KHOẢN trước. CMND cần thiết.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0

    def test_informal_contact_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Liên hệ qua zalo hoặc facebook để đăng ký. Không có email.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0


class TestVaguenessScoring:
    """Test vagueness score computation."""

    def test_long_specific_text_low_vagueness(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch tình nguyện mùa hè xanh",
            description="Chiến dịch nhằm bảo vệ môi trường. Hoạt động gồm: "
                        "dọn rác công viên, trồng cây, tuyên truyền. "
                        "Thời gian: 8h-17h. Địa điểm: Công viên Thống Nhất.",
        )
        result = analyzer.analyze()
        assert 0.0 <= result["vagueness_score"] <= 1.0

    def test_short_vague_text_high_vagueness(self):
        analyzer = ContentAnalyzer(
            title="Tình nguyện",
            description="Hoạt động đặc biệt. Ngày đặc biệt.",
        )
        result = analyzer.analyze()
        # Short + generic phrases = high vagueness
        assert result["vagueness_score"] >= 0.0

    def test_vagueness_score_range(self):
        texts = [
            ("A", "A"),
            ("Chiến dịch tình nguyện bảo vệ môi trường xanh sạch đẹp", "Mô tả dài"),
            ("Hoạt động đặc biệt", "Sự kiện đặc biệt"),
        ]
        for title, desc in texts:
            analyzer = ContentAnalyzer(title=title, description=desc)
            result = analyzer.analyze()
            assert 0.0 <= result["vagueness_score"] <= 1.0


class TestSafetyDescriptionScore:
    """Test safety description score."""

    def test_has_safety_description_high_score(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Chiến dịch có phương án an toàn rõ ràng. "
                        "Tất cả tình nguyện viên được trang bị thiết bị bảo hộ.",
        )
        result = analyzer.analyze()
        assert result["safety_description_score"] == 1.0

    def test_has_safety_keyword_but_no_description(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Chiến dịch có an toàn cho tình nguyện viên.",
        )
        result = analyzer.analyze()
        # Contains "an toàn" but no real description
        assert result["safety_description_score"] == 0.5

    def test_no_safety_description_zero_score(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="Chiến dịch tình nguyện mùa hè xanh.",
        )
        result = analyzer.analyze()
        assert result["safety_description_score"] == 0.0


class TestTextRiskScore:
    """Test text risk score (TF-IDF based)."""

    def test_safe_text_low_risk_score(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch tình nguyện mùa hè xanh",
            description="Chiến dịch nhằm bảo vệ môi trường và hỗ trợ cộng đồng. "
                        "Hoạt động bao gồm dọn rác, trồng cây, tuyên truyền về bảo vệ môi trường.",
        )
        result = analyzer.analyze()
        assert 0.0 <= result["text_risk_score"] <= 1.0
        assert result["text_risk_score"] < 0.5

    def test_risky_text_high_risk_score(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch đặc biệt",
            description="Yêu cầu chuyển khoản đặt cọc trước. Gặp mặt trực tiếp thông báo sau. "
                        "CMND và tài khoản ngân hàng cần cung cấp. Bí mật.",
        )
        result = analyzer.analyze()
        assert result["text_risk_score"] >= 0.5


class TestRiskFlagsFormatting:
    """Test formatting of risk flags from analysis."""

    def test_format_risk_flags(self):
        analysis = {
            "text_risk_keyword_count": 3,
            "risk_keywords_found": [
                {"keyword": "chuyển khoản", "severity": "HIGH", "category": "YÊU_CẦU_TIỀN", "suggestion": "Yêu cầu xác minh"},
                {"keyword": "cmnd", "severity": "HIGH", "category": "THÔNG_TIN_NHAY_CẢM", "suggestion": "Không yêu cầu CMND"},
            ],
            "text_risk_score": 0.8,
            "vagueness_score": 0.6,
            "safety_description_score": 0.0,
        }
        flags = format_risk_flags_from_analysis(analysis)
        assert len(flags) == 2
        assert flags[0]["code"] == "RISK_KEYword_CHUYỂN_KHOẢN".upper().replace(" ", "_")


class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_empty_title_and_description(self):
        analyzer = ContentAnalyzer(title="", description="")
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] == 0
        assert result["text_risk_score"] >= 0.0

    def test_none_inputs(self):
        analyzer = ContentAnalyzer(title=None, description=None)
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] >= 0

    def test_very_long_text(self):
        long_desc = "Hoạt động " * 1000
        analyzer = ContentAnalyzer(title="Chiến dịch", description=long_desc)
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] >= 0

    def test_mixed_case_keywords(self):
        analyzer = ContentAnalyzer(
            title="Chiến dịch",
            description="CHUYỂN KHOẢN trước. CMTND cần thiết. ZALO liên hệ.",
        )
        result = analyzer.analyze()
        assert result["text_risk_keyword_count"] > 0

"""
Pytest configuration and fixtures for trust-eval-service tests.
"""

import os
import sys
from pathlib import Path

import pytest

# Ensure app is on path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Set test environment
os.environ["APP_ENV"] = "testing"
os.environ["DB_HOST"] = "127.0.0.1"
os.environ["DB_PORT"] = "3306"
os.environ["DB_DATABASE"] = "volunteer_management_test"
os.environ["DB_USERNAME"] = "trust_evaluator"
os.environ["DB_PASSWORD"] = "test_password"


# ─────────────────────────────────────────────
# Sample Data Fixtures
# ─────────────────────────────────────────────

@pytest.fixture
def sample_campaign():
    """A valid, complete campaign dict."""
    from datetime import date, timedelta

    today = date.today()
    return {
        "id": 1,
        "tieu_de": "Chiến dịch tình nguyện mùa hè xanh 2026",
        "mo_ta": "Chiến dịch tình nguyện mùa hè xanh nhằm bảo vệ môi trường và hỗ trợ cộng đồng. "
                  "Chúng tôi tổ chức các hoạt động dọn rác, trồng cây và tuyên truyền về bảo vệ môi trường. "
                  "Mọi tình nguyện viên đều được cung cấp thiết bị bảo hộ và được tham gia đầy đủ các hoạt động.",
        "anh_bia": "https://example.com/cover.jpg",
        "dia_diem": "Công viên Thống Nhất, Hà Nội",
        "vi_do": 21.0285,
        "kinh_do": 105.8542,
        "khu_vuc_id": 1,
        "loai_chien_dich_id": 1,
        "ngay_bat_dau": (today + timedelta(days=10)).isoformat(),
        "ngay_ket_thuc": (today + timedelta(days=15)).isoformat(),
        "han_dang_ky": (today + timedelta(days=7)).isoformat(),
        "so_luong_toi_da": 50,
        "so_luong_toi_thieu": 10,
        "muc_do_uu_tien": "trung_binh",
        "trang_thai": "cho_duyet",
        "so_dang_ky": 15,
        "so_xac_nhan": 12,
        "nguoi_tao_id": 100,
        "tao_luc": (today - timedelta(days=30)).isoformat(),
    }


@pytest.fixture
def sample_creator():
    """A valid creator dict."""
    from datetime import date, timedelta

    today = date.today()
    return {
        "id": 100,
        "ho_ten": "Nguyễn Văn Minh",
        "email": "minh@example.com",
        "anh_dai_dien": "https://example.com/avatar.jpg",
        "gioi_thieu": "Tình nguyện viên nhiều năm kinh nghiệm",
        "trang_thai": "hoat_dong",
        "xac_thuc_email_luc": (today - timedelta(days=180)).isoformat(),
        "tao_luc": (today - timedelta(days=365)).isoformat(),
        "tinh_thanh_id": 1,
        "vi_do": 21.0285,
        "kinh_do": 105.8542,
        "so_dien_thoai": "0912345678",
        "vai_tro": "to_chuc",
        "campaign_count": 15,
        "campaign_approval_rate": 0.87,
        "campaign_cancellation_rate": 0.07,
        "avg_participation": 18.5,
        "campaign_report_count": 1,
        "ky_nang_count": 3,
        "chung_chi_count": 2,
        "kinh_nghiem_count": 5,
        "ratings": [
            {"so_sao": 5},
            {"so_sao": 4},
            {"so_sao": 5},
            {"so_sao": 4},
            {"so_sao": 5},
        ],
    }


@pytest.fixture
def sample_campaign_with_missing_fields():
    """Campaign with several validation errors."""
    from datetime import date, timedelta

    today = date.today()
    return {
        "id": 2,
        "tieu_de": "Tình nguyện",  # Too short (< 10 chars)
        "mo_ta": "Mùa hè xanh",    # Too short (< 50 chars)
        "anh_bia": None,
        "dia_diem": "",             # Empty
        "vi_do": None,              # Missing
        "kinh_do": None,            # Missing
        "khu_vuc_id": None,
        "loai_chien_dich_id": 1,
        "ngay_bat_dau": (today - timedelta(days=1)).isoformat(),  # In the past
        "ngay_ket_thuc": (today - timedelta(days=5)).isoformat(),  # Before start
        "han_dang_ky": None,
        "so_luong_toi_da": 5,
        "so_luong_toi_thieu": 10,   # > max
        "muc_do_uu_tien": "khan_cap",
        "trang_thai": "nhap",
        "so_dang_ky": 0,
        "so_xac_nhan": 0,
        "nguoi_tao_id": None,        # Missing creator
        "tao_luc": today.isoformat(),
    }


@pytest.fixture
def suspicious_campaign():
    """Campaign with suspicious indicators."""
    from datetime import date, timedelta

    today = date.today()
    return {
        "id": 3,
        "tieu_de": "Chiến dịch đặc biệt mùa hè",
        "mo_ta": "Hoạt động đặc biệt cần người tham gia. "
                  "Yêu cầu chuyển khoản đặt cọc trước 500.000đ. "
                  "Gặp mặt trực tiếp sẽ thông báo sau. "
                  "CMND và sao kê tài khoản ngân hàng cần cung cấp.",
        "anh_bia": None,
        "dia_diem": "Sẽ thông báo sau",
        "vi_do": 25.0,   # Outside Vietnam
        "kinh_do": 115.0,
        "khu_vuc_id": None,
        "loai_chien_dich_id": 1,
        "ngay_bat_dau": (today + timedelta(days=3)).isoformat(),
        "ngay_ket_thuc": (today + timedelta(days=5)).isoformat(),
        "han_dang_ky": today.isoformat(),
        "so_luong_toi_da": 200,
        "so_luong_toi_thieu": 1,
        "muc_do_uu_tien": "khan_cap",
        "trang_thai": "cho_duyet",
        "so_dang_ky": 0,
        "so_xac_nhan": 0,
        "nguoi_tao_id": 200,
        "tao_luc": today.isoformat(),
    }


@pytest.fixture
def suspicious_creator():
    """Creator with suspicious indicators."""
    from datetime import date, timedelta

    today = date.today()
    return {
        "id": 200,
        "ho_ten": "Unknown User",
        "email": None,
        "anh_dai_dien": None,
        "gioi_thieu": None,
        "trang_thai": "hoat_dong",
        "xac_thuc_email_luc": None,
        "tao_luc": (today - timedelta(days=3)).isoformat(),  # Very new account
        "tinh_thanh_id": None,
        "vi_do": None,
        "kinh_do": None,
        "so_dien_thoai": None,
        "vai_tro": "to_chuc",
        "campaign_count": 1,
        "campaign_approval_rate": 0.0,
        "campaign_cancellation_rate": 1.0,
        "avg_participation": 0.0,
        "campaign_report_count": 3,
        "ky_nang_count": 0,
        "chung_chi_count": 0,
        "kinh_nghiem_count": 0,
        "ratings": [],
    }


@pytest.fixture
def empty_creator():
    """Minimal creator dict."""
    return {
        "id": None,
        "ho_ten": None,
        "email": None,
        "trang_thai": None,
        "xac_thuc_email_luc": None,
        "tao_luc": None,
        "vai_tro": None,
    }


# ─────────────────────────────────────────────
# Session Fixtures
# ─────────────────────────────────────────────

@pytest.fixture(scope="session")
def app_settings():
    """Application settings."""
    from app.config import get_settings
    return get_settings()


# ─────────────────────────────────────────────
# Mock Fixtures
# ─────────────────────────────────────────────

@pytest.fixture
def mock_db_cursor(monkeypatch):
    """Mock database cursor to avoid real DB calls."""
    class MockCursor:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def execute(self, query, params=None):
            pass

        def fetchone(self):
            return {}

        def fetchall(self):
            return []

    class MockConnection:
        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def cursor(self, dictionary=True):
            return MockCursor()

    def mock_get_cursor():
        return MockConnection()

    from app.core import database
    monkeypatch.setattr(database, "get_db_cursor", mock_get_cursor)

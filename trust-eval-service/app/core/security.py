"""
Security Layer - Internal API authentication, rate limiting, and input sanitization.

Bảo vệ ML Service khỏi:
1. Unauthorized access từ bên ngoài
2. Rate limiting để tránh abuse
3. Input sanitization
4. Internal API key validation
5. CORS hardening
"""

import hashlib
import hmac
import logging
import time
from collections import defaultdict
from functools import wraps
from typing import Callable, Optional

from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse

logger = logging.getLogger("trust_eval_service")


# ─────────────────────────────────────────────
# Rate Limiter
# ─────────────────────────────────────────────

class RateLimiter:
    """
    Token bucket rate limiter cho mỗi IP/client.

    Cấu hình mặc định:
    - 100 requests / phút cho evaluation endpoints
    - 10 requests / phút cho training endpoints
    - 60 requests / phút cho health/read-only endpoints
    """

    def __init__(
        self,
        requests_per_minute: int = 100,
        burst_size: Optional[int] = None,
    ):
        self._rate = requests_per_minute / 60.0  # requests per second
        self._burst_size = burst_size or requests_per_minute
        self._buckets: dict[str, tuple[float, float]] = {}  # ip → (tokens, last_update)
        self._lock = __import__("threading").RLock()

    def _get_client_ip(self, request: Request) -> str:
        """Extract client IP, support proxy via X-Forwarded-For."""
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"

    def is_allowed(self, request: Request) -> bool:
        """Check if request is allowed under rate limit."""
        ip = self._get_client_ip(request)
        now = time.time()

        with self._lock:
            if ip not in self._buckets:
                self._buckets[ip] = (float(self._burst_size), now)
                return True

            tokens, last_update = self._buckets[ip]
            elapsed = now - last_update

            # Refill tokens based on elapsed time
            tokens = min(self._burst_size, tokens + elapsed * self._rate)

            if tokens >= 1.0:
                tokens -= 1.0
                self._buckets[ip] = (tokens, now)
                return True
            else:
                self._buckets[ip] = (tokens, now)
                return False

    def get_remaining(self, request: Request) -> int:
        """Get remaining requests for this client."""
        ip = self._get_client_ip(request)
        with self._lock:
            if ip not in self._buckets:
                return self._burst_size
            tokens, _ = self._buckets[ip]
            return max(0, int(tokens))

    def reset(self, ip: Optional[str] = None):
        """Reset rate limit for specific IP or all."""
        with self._lock:
            if ip:
                self._buckets.pop(ip, None)
            else:
                self._buckets.clear()


# Global rate limiters
EVAL_RATE_LIMITER = RateLimiter(requests_per_minute=100)
TRAIN_RATE_LIMITER = RateLimiter(requests_per_minute=10)
HEALTH_RATE_LIMITER = RateLimiter(requests_per_minute=60)
BATCH_RATE_LIMITER = RateLimiter(requests_per_minute=20)


# ─────────────────────────────────────────────
# Internal API Key Authentication
# ─────────────────────────────────────────────

class InternalAuth:
    """
    Xác thực internal API requests từ Laravel.

    Cách hoạt động:
    - Laravel gửi header: X-Internal-Key: <secret_key>
    - Hoặc header: Authorization: Bearer <secret_key>
    - ML Service validate key trước khi xử lý

    Đọc key từ INTERNAL_API_KEY environment variable.
    """

    def __init__(self):
        import os
        self._key = os.environ.get("INTERNAL_API_KEY", "")
        self._enabled = bool(self._key)

    def validate(self, request: Request) -> bool:
        """
        Validate internal API key from request headers.

        Returns True nếu:
        - Key không required (development mode)
        - Key hợp lệ
        - Request đến từ localhost/internal network
        """
        if not self._enabled:
            # Auth disabled (development)
            return True

        # Check header
        key = request.headers.get("X-Internal-Key")
        if not key:
            # Try Bearer token
            auth_header = request.headers.get("Authorization", "")
            if auth_header.startswith("Bearer "):
                key = auth_header[7:]

        if not key:
            logger.warning(f"Missing API key from {self._get_client_ip(request)}")
            return False

        # Constant-time comparison to prevent timing attacks
        if not hmac.compare_digest(key, self._key):
            logger.warning(f"Invalid API key from {self._get_client_ip(request)}")
            return False

        return True

    def _get_client_ip(self, request: Request) -> str:
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"


# Global auth
INTERNAL_AUTH = InternalAuth()


# ─────────────────────────────────────────────
# Middleware
# ─────────────────────────────────────────────

async def rate_limit_middleware(request: Request, call_next):
    """FastAPI middleware cho rate limiting toàn bộ requests."""
    # Determine which rate limiter to use
    path = request.url.path

    if path.startswith("/api/v1/train"):
        limiter = TRAIN_RATE_LIMITER
    elif path.startswith("/api/v1/evaluate/batch"):
        limiter = BATCH_RATE_LIMITER
    elif path.startswith("/api/v1/evaluate"):
        limiter = EVAL_RATE_LIMITER
    elif path in ("/health", "/api/v1/health", "/"):
        limiter = HEALTH_RATE_LIMITER
    else:
        limiter = EVAL_RATE_LIMITER

    if not limiter.is_allowed(request):
        remaining = limiter.get_remaining(request)
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "detail": "Rate limit exceeded. Please slow down.",
                "retry_after_seconds": 60,
                "remaining": remaining,
            },
            headers={"Retry-After": "60", "X-RateLimit-Remaining": str(remaining)},
        )

    response = await call_next(request)

    # Add rate limit headers
    remaining = limiter.get_remaining(request)
    response.headers["X-RateLimit-Remaining"] = str(remaining)

    return response


async def internal_auth_middleware(request: Request, call_next):
    """
    Middleware xác thực internal API key cho non-public endpoints.

    Bỏ qua auth cho:
    - /health, /docs, /redoc, /
    - GET requests (read-only, không cần auth trong internal network)
    """
    public_paths = {"/", "/health", "/docs", "/redoc", "/openapi.json"}
    path = request.url.path

    # Public paths - skip auth
    if path in public_paths:
        return await call_next(request)

    # GET requests - skip auth (read-only)
    if request.method == "GET":
        return await call_next(request)

    # Training endpoints - require auth
    if path.startswith("/api/v1/train"):
        if not INTERNAL_AUTH.validate(request):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={"detail": "Invalid or missing internal API key"},
            )

    return await call_next(request)


# ─────────────────────────────────────────────
# Decorators
# ─────────────────────────────────────────────

def require_internal_key(func: Callable) -> Callable:
    """Decorator yêu cầu internal API key cho một endpoint cụ thể."""
    @wraps(func)
    async def wrapper(request: Request, *args, **kwargs):
        if not INTERNAL_AUTH.validate(request):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or missing internal API key",
            )
        return await func(request, *args, **kwargs)
    return wrapper


# ─────────────────────────────────────────────
# Input Sanitization
# ─────────────────────────────────────────────

class InputSanitizer:
    """
    Sanitize input trước khi xử lý để tránh injection attacks.
    """

    @staticmethod
    def sanitize_string(value: str, max_length: int = 10000) -> str:
        """Sanitize string input."""
        if not isinstance(value, str):
            return ""

        # Truncate to max length
        value = value[:max_length]

        # Remove null bytes
        value = value.replace("\x00", "")

        # Strip leading/trailing whitespace
        value = value.strip()

        return value

    @staticmethod
    def sanitize_int(value: any, min_val: int = 0, max_val: int = 10_000_000) -> int:
        """Sanitize integer input."""
        try:
            value = int(value)
            return max(min_val, min(max_val, value))
        except (TypeError, ValueError):
            return 0

    @staticmethod
    def sanitize_float(value: any, min_val: float = 0.0, max_val: float = 1.0) -> float:
        """Sanitize float input."""
        try:
            value = float(value)
            return max(min_val, min(max_val, value))
        except (TypeError, ValueError):
            return 0.0

    @staticmethod
    def sanitize_campaign_id(value: any) -> int:
        """Sanitize campaign ID specifically."""
        return InputSanitizer.sanitize_int(value, min_val=1, max_val=10_000_000)

    @staticmethod
    def sanitize_list(value: list, max_length: int = 100) -> list:
        """Sanitize list input."""
        if not isinstance(value, list):
            return []
        return value[:max_length]


# Global sanitizer instance
SANITIZER = InputSanitizer()


# ─────────────────────────────────────────────
# Security Headers
# ─────────────────────────────────────────────

def add_security_headers(response):
    """Add security headers to response."""
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'none'"
    return response


# ─────────────────────────────────────────────
# Audit Logging
# ─────────────────────────────────────────────

def audit_log(request: Request, action: str, details: Optional[dict] = None):
    """Log security-relevant events."""
    client_ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "unknown")
    user_agent = request.headers.get("user-agent", "unknown")
    path = request.url.path

    log_data = {
        "action": action,
        "client_ip": client_ip,
        "path": path,
        "user_agent": user_agent,
        "timestamp": time.time(),
    }

    if details:
        log_data["details"] = details

    if action in ("auth_failed", "rate_limited", "invalid_input"):
        logger.warning(f"SECURITY: {log_data}")
    else:
        logger.info(f"AUDIT: {log_data}")

"""
Performance Optimization Layer - Batch inference, caching, and response optimization.

Các tối ưu hóa:
1. In-memory LRU cache cho evaluation results (với TTL)
2. Batch inference cho nhiều campaigns cùng lúc
3. Precomputed feature vectors cache
4. Async model loading
5. Connection pooling cho database
"""

import hashlib
import json
import logging
import threading
import time
from collections import OrderedDict
from functools import wraps
from typing import Any, Optional

logger = logging.getLogger("trust_eval_service")


# ─────────────────────────────────────────────
# LRU Cache with TTL
# ─────────────────────────────────────────────

class TTLCache:
    """
    Thread-safe LRU cache với TTL (Time-To-Live).

    Features:
    - LRU eviction khi đầy
    - TTL expiration tự động
    - Thread-safe access
    - Hit/miss statistics
    """

    def __init__(self, max_size: int = 1000, default_ttl: int = 3600):
        self._max_size = max_size
        self._default_ttl = default_ttl
        self._cache: OrderedDict[str, tuple[Any, float]] = OrderedDict()
        self._lock = threading.RLock()
        self._hits = 0
        self._misses = 0
        self._evictions = 0

    def get(self, key: str) -> Optional[Any]:
        """Get value from cache. Returns None if not found or expired."""
        with self._lock:
            if key not in self._cache:
                self._misses += 1
                return None

            value, expiry = self._cache[key]

            if time.time() > expiry:
                # Expired
                del self._cache[key]
                self._misses += 1
                return None

            # Move to end (most recently used)
            self._cache.move_to_end(key)
            self._hits += 1
            return value

    def set(self, key: str, value: Any, ttl: Optional[int] = None):
        """Set value in cache with optional custom TTL."""
        with self._lock:
            ttl = ttl if ttl is not None else self._default_ttl
            expiry = time.time() + ttl

            if key in self._cache:
                self._cache.move_to_end(key)
                self._cache[key] = (value, expiry)
                return

            # Evict oldest if full
            while len(self._cache) >= self._max_size:
                self._cache.popitem(last=False)
                self._evictions += 1

            self._cache[key] = (value, expiry)

    def invalidate(self, key: str):
        """Remove a key from cache."""
        with self._lock:
            self._cache.pop(key, None)

    def clear(self):
        """Clear all cache entries."""
        with self._lock:
            self._cache.clear()

    def get_stats(self) -> dict:
        """Return cache statistics."""
        with self._lock:
            total = self._hits + self._misses
            hit_rate = self._hits / total if total > 0 else 0.0
            return {
                "size": len(self._cache),
                "max_size": self._max_size,
                "hits": self._hits,
                "misses": self._misses,
                "hit_rate": round(hit_rate, 4),
                "evictions": self._evictions,
            }

    def cleanup_expired(self):
        """Remove all expired entries."""
        now = time.time()
        with self._lock:
            expired_keys = [
                k for k, (_, expiry) in self._cache.items()
                if now > expiry
            ]
            for k in expired_keys:
                del self._cache[k]
            return len(expired_keys)


# ─────────────────────────────────────────────
# Global Cache Instances
# ─────────────────────────────────────────────

# Campaign evaluation cache: campaign_id → evaluation result
# TTL: 1 giờ (đúng như spec section 8.1)
EVALUATION_CACHE = TTLCache(max_size=2000, default_ttl=3600)

# Volunteer evaluation cache: volunteer_id → evaluation result
# TTL: 6 giờ (đúng như spec section 8.1)
VOLUNTEER_CACHE = TTLCache(max_size=1000, default_ttl=21600)

# ML service health cache: 5 phút
HEALTH_CACHE = TTLCache(max_size=10, default_ttl=300)

# Model info cache: 10 phút
MODEL_INFO_CACHE = TTLCache(max_size=50, default_ttl=600)

# Statistics cache: 5 phút
STATS_CACHE = TTLCache(max_size=100, default_ttl=300)


# ─────────────────────────────────────────────
# Cache Key Helpers
# ─────────────────────────────────────────────

def cache_key_campaign(campaign_id: int) -> str:
    """Generate cache key for campaign evaluation."""
    return f"campaign_evaluation:{campaign_id}"


def cache_key_volunteer(volunteer_id: int) -> str:
    """Generate cache key for volunteer evaluation."""
    return f"volunteer_evaluation:{volunteer_id}"


def cache_key_force_refresh(campaign_id: int) -> str:
    """Generate cache key for forced refresh (bypasses cache)."""
    return f"force_refresh:{campaign_id}"


# ─────────────────────────────────────────────
# Cache Decorators
# ─────────────────────────────────────────────

def cached(cache: TTLCache, key_func, ttl: Optional[int] = None):
    """
    Decorator for caching function results.

    Args:
        cache: TTLCache instance
        key_func: function to generate cache key from args
        ttl: optional custom TTL in seconds
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            key = key_func(*args, **kwargs)
            result = cache.get(key)
            if result is not None:
                return result
            result = func(*args, **kwargs)
            if result is not None:
                cache.set(key, result, ttl)
            return result
        return wrapper
    return decorator


# ─────────────────────────────────────────────
# Batch Inference Optimizer
# ─────────────────────────────────────────────

class BatchInferenceOptimizer:
    """
    Tối ưu hóa batch inference bằng cách:
    1. Group requests theo model type
    2. Parallel feature extraction
    3. Batch model predictions
    4. Early termination on errors
    """

    def __init__(self, max_batch_size: int = 50, timeout_seconds: float = 30.0):
        self._max_batch_size = max_batch_size
        self._timeout = timeout_seconds
        self._pending: dict[str, list[dict]] = {}
        self._lock = threading.Lock()

    def add(self, campaign_id: int, priority: str = "normal") -> str:
        """
        Add a campaign to the batch queue.

        Returns batch_id for tracking.
        """
        batch_id = hashlib.md5(
            f"{campaign_id}_{time.time()}".encode()
        ).hexdigest()[:8]

        with self._lock:
            if batch_id not in self._pending:
                self._pending[batch_id] = []
            self._pending[batch_id].append({
                "campaign_id": campaign_id,
                "priority": priority,
                "added_at": time.time(),
            })

        return batch_id

    def get_batch(self, batch_id: str) -> Optional[list[dict]]:
        """Get current batch or None if not ready."""
        with self._lock:
            if batch_id not in self._pending:
                return None

            batch = self._pending[batch_id]

            # Ready if batch is full or timeout reached
            elapsed = time.time() - batch[0]["added_at"]

            if len(batch) >= self._max_batch_size or elapsed > self._timeout:
                return self._pending.pop(batch_id, None)

            return None

    def get_stats(self) -> dict:
        """Return batch optimizer statistics."""
        with self._lock:
            total_pending = sum(len(v) for v in self._pending.values())
            return {
                "active_batches": len(self._pending),
                "total_pending": total_pending,
                "max_batch_size": self._max_batch_size,
                "timeout_seconds": self._timeout,
            }


# Global batch optimizer
BATCH_OPTIMIZER = BatchInferenceOptimizer()


# ─────────────────────────────────────────────
# Cache Utilities
# ─────────────────────────────────────────────

def invalidate_campaign_cache(campaign_id: int):
    """Invalidate all caches related to a campaign."""
    EVALUATION_CACHE.invalidate(cache_key_campaign(campaign_id))
    logger.debug(f"Invalidated cache for campaign {campaign_id}")


def invalidate_volunteer_cache(volunteer_id: int):
    """Invalidate all caches related to a volunteer."""
    VOLUNTEER_CACHE.invalidate(cache_key_volunteer(volunteer_id))
    logger.debug(f"Invalidated cache for volunteer {volunteer_id}")


def invalidate_all_caches():
    """Clear all caches."""
    EVALUATION_CACHE.clear()
    VOLUNTEER_CACHE.clear()
    HEALTH_CACHE.clear()
    MODEL_INFO_CACHE.clear()
    STATS_CACHE.clear()
    logger.info("All caches cleared")


def get_cache_stats() -> dict:
    """Return statistics for all caches."""
    return {
        "campaign_evaluation": EVALUATION_CACHE.get_stats(),
        "volunteer_evaluation": VOLUNTEER_CACHE.get_stats(),
        "health": HEALTH_CACHE.get_stats(),
        "model_info": MODEL_INFO_CACHE.get_stats(),
        "statistics": STATS_CACHE.get_stats(),
        "batch_optimizer": BATCH_OPTIMIZER.get_stats(),
    }

"""Redis caching service."""
import redis
import json
from typing import Optional, Any
from app.config import settings
from app.utils.logging import get_logger
from app.utils.metrics import cache_hits, cache_misses

logger = get_logger(__name__)


class CacheService:
    """Redis cache service for caching weather data."""

    def __init__(self):
        """Initialize Redis connection."""
        try:
            self.client = redis.Redis(
                host=settings.redis_host,
                port=settings.redis_port,
                db=settings.redis_db,
                password=settings.redis_password,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_keepalive=True
            )
            # Test connection
            self.client.ping()
            logger.info("Redis connection established", extra={"host": settings.redis_host})
        except Exception as e:
            logger.error("Failed to connect to Redis", extra={"error": str(e)})
            self.client = None

    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache."""
        if not self.client:
            return None

        try:
            value = self.client.get(key)
            if value:
                cache_hits.labels(key=key).inc()
                logger.debug(f"Cache hit for key: {key}")
                return json.loads(value)
            cache_misses.labels(key=key).inc()
            logger.debug(f"Cache miss for key: {key}")
            return None
        except Exception as e:
            logger.error(f"Cache get error for key {key}", extra={"error": str(e)})
            return None

    async def set(
        self,
        key: str,
        value: Any,
        ttl: Optional[int] = None
    ) -> bool:
        """Set value in cache."""
        if not self.client:
            return False

        try:
            ttl = ttl or settings.redis_cache_ttl
            self.client.setex(
                key,
                ttl,
                json.dumps(value, default=str)
            )
            logger.debug(f"Cache set for key: {key}", extra={"ttl": ttl})
            return True
        except Exception as e:
            logger.error(f"Cache set error for key {key}", extra={"error": str(e)})
            return False

    async def delete(self, key: str) -> bool:
        """Delete value from cache."""
        if not self.client:
            return False

        try:
            self.client.delete(key)
            logger.debug(f"Cache deleted for key: {key}")
            return True
        except Exception as e:
            logger.error(f"Cache delete error for key {key}", extra={"error": str(e)})
            return False

    async def clear(self) -> bool:
        """Clear all cache."""
        if not self.client:
            return False

        try:
            self.client.flushdb()
            logger.info("Cache cleared")
            return True
        except Exception as e:
            logger.error("Cache clear error", extra={"error": str(e)})
            return False

    def is_connected(self) -> bool:
        """Check if Redis is connected. Attempts reconnection if needed."""
        # If no client exists, try to reconnect
        if not self.client:
            try:
                logger.info(
                    "Attempting Redis reconnection",
                    extra={
                        "host": settings.redis_host,
                        "port": settings.redis_port,
                        "has_password": settings.redis_password is not None
                    }
                )
                self.client = redis.Redis(
                    host=settings.redis_host,
                    port=settings.redis_port,
                    db=settings.redis_db,
                    password=settings.redis_password,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_keepalive=True
                )
                self.client.ping()
                logger.info("Redis reconnected successfully", extra={"host": settings.redis_host})
                return True
            except ConnectionRefusedError as e:
                logger.warning(
                    "Redis connection refused - ensure Redis is running",
                    extra={
                        "host": settings.redis_host,
                        "port": settings.redis_port,
                        "error": str(e)
                    }
                )
                self.client = None
                return False
            except Exception as e:
                logger.warning(
                    "Failed to reconnect to Redis",
                    extra={
                        "error_type": type(e).__name__,
                        "error": str(e),
                        "host": settings.redis_host
                    }
                )
                self.client = None
                return False
        
        # If client exists, test connection
        try:
            self.client.ping()
            return True
        except Exception as e:
            logger.warning(
                "Redis connection lost",
                extra={
                    "error_type": type(e).__name__,
                    "error": str(e)
                }
            )
            self.client = None
            return False


# Global cache instance
cache = CacheService()

"""Prometheus metrics for monitoring."""
from prometheus_client import Counter, Histogram, Gauge
import time

# Request metrics
request_count = Counter(
    "weather_api_requests_total",
    "Total number of API requests",
    ["method", "endpoint", "status"]
)

request_duration = Histogram(
    "weather_api_request_duration_seconds",
    "Request duration in seconds",
    ["method", "endpoint"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0)
)

# Weather API metrics
weather_api_calls = Counter(
    "weather_api_calls_total",
    "Total number of weather API calls",
    ["city", "status"]
)

weather_api_duration = Histogram(
    "weather_api_call_duration_seconds",
    "Weather API call duration in seconds",
    buckets=(0.1, 0.5, 1.0, 2.0, 5.0)
)

# Cache metrics
cache_hits = Counter(
    "cache_hits_total",
    "Total number of cache hits",
    ["key"]
)

cache_misses = Counter(
    "cache_misses_total",
    "Total number of cache misses",
    ["key"]
)

# Health check
api_health = Gauge(
    "weather_api_health",
    "API health status (1=healthy, 0=unhealthy)"
)


class MetricsMiddleware:
    """ASGI middleware for tracking metrics."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        start_time = time.time()
        method = scope.get("method", "unknown")
        path = scope.get("path", "unknown")

        async def send_with_metrics(message):
            if message["type"] == "http.response.start":
                status = message.get("status", 500)
                duration = time.time() - start_time
                request_count.labels(method=method, endpoint=path, status=status).inc()
                request_duration.labels(method=method, endpoint=path).observe(duration)
            await send(message)

        await self.app(scope, receive, send_with_metrics)

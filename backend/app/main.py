"""FastAPI application factory and endpoints."""
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from datetime import datetime
import logging

from app.config import settings
from app.models import WeatherData, HealthCheck, ErrorResponse
from app.services.weather import weather_service
from app.services.cache import cache
from app.utils.logging import setup_logging, get_logger
from app.utils.metrics import MetricsMiddleware, api_health

# Setup logging
setup_logging()
logger = get_logger(__name__)


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""

    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        debug=settings.debug,
        docs_url="/docs",
        openapi_url="/openapi.json"
    )

    # Add metrics middleware
    if settings.prometheus_enabled:
        app.add_middleware(MetricsMiddleware)

    # Startup event
    @app.on_event("startup")
    async def startup():
        """Application startup event."""
        logger.info(f"Starting {settings.app_name} v{settings.app_version}")
        logger.info(f"Debug mode: {settings.debug}")
        logger.info(f"Log level: {settings.log_level}")
        if cache.is_connected():
            logger.info("Redis cache connected")
            api_health.set(1)
        else:
            logger.warning("Redis cache not available")
            api_health.set(0)

    # Shutdown event
    @app.on_event("shutdown")
    async def shutdown():
        """Application shutdown event."""
        logger.info(f"Shutting down {settings.app_name}")

    # Health check endpoint
    @app.get(
        "/health",
        tags=["Health"],
        summary="Health check endpoint",
        description="Returns the health status of the API"
    )
    async def health_check():
        """
        Health check endpoint returning application status.

        Returns:
            Health status, version, and timestamp with dependency info
        """
        logger.debug("Health check requested")
        redis_health = cache.is_connected()
        api_health.set(1 if redis_health else 0)
        
        # Determine overall status
        status = "healthy" if redis_health else "degraded"
        
        response = {
            "status": status,
            "version": settings.app_version,
            "timestamp": datetime.utcnow().isoformat(),
            "dependencies": {
                "redis": {
                    "status": "connected" if redis_health else "disconnected",
                    "host": settings.redis_host,
                    "port": settings.redis_port
                }
            }
        }
        
        if not redis_health:
            response["note"] = "Redis is disconnected. Start Redis to make status 'healthy'. API still functional."
        
        return response

    # Weather endpoint - get weather for a city
    @app.get(
        "/weather",
        response_model=WeatherData,
        tags=["Weather"],
        summary="Get weather data",
        description="Fetch current weather data for a specified city"
    )
    async def get_weather(city: str = Query(..., min_length=1, description="City name")):
        """
        Get weather data for a city.

        Args:
            city: City name to fetch weather for

        Returns:
            WeatherData: Current weather information including temperature, humidity, etc.

        Raises:
            HTTPException: If city not found or API error occurs
        """
        logger.info(f"Weather request for city: {city}")

        if not city or len(city.strip()) == 0:
            logger.warning("Empty city name provided")
            raise HTTPException(
                status_code=400,
                detail="City name cannot be empty"
            )

        weather_data = await weather_service.get_weather(city)

        if not weather_data:
            logger.warning(f"Weather data not found for city: {city}")
            raise HTTPException(
                status_code=404,
                detail=f"City '{city}' not found. Please check the city name and try again. "
                       f"Use format like 'London', 'New York', 'Tokyo', etc."
            )

        logger.info(f"Successfully retrieved weather for {city}")
        return weather_data

    # Diagnostics endpoint
    @app.get(
        "/diagnostics",
        tags=["Diagnostics"],
        summary="API diagnostics",
        description="Check API configuration and dependencies"
    )
    async def diagnostics():
        """
        Diagnostic endpoint to check API configuration and health.
        
        Returns:
            Diagnostic information for troubleshooting
        """
        logger.debug("Diagnostics check requested")
        
        # Check API key
        api_key = settings.openweather_api_key
        api_key_status = "configured" if api_key and api_key != "your_api_key_here" else "not_configured"
        
        # Check Redis
        redis_status = cache.is_connected()
        
        # Check weather service
        weather_health = await weather_service.health_check()
        
        return {
            "status": "ok" if all([redis_status, weather_health if api_key_status != "not_configured" else True]) else "warning",
            "app": {
                "name": settings.app_name,
                "version": settings.app_version,
                "debug": settings.debug,
                "log_level": settings.log_level
            },
            "dependencies": {
                "redis": {
                    "connected": redis_status,
                    "host": settings.redis_host,
                    "port": settings.redis_port
                },
                "openweather_api": {
                    "key_status": api_key_status,
                    "base_url": settings.openweather_base_url,
                    "accessible": weather_health
                }
            },
            "cache": {
                "ttl_seconds": settings.redis_cache_ttl,
                "enabled": redis_status
            }
        }

    # Metrics endpoint
    @app.get(
        "/metrics",
        tags=["Monitoring"],
        summary="Prometheus metrics",
        description="Get Prometheus metrics in text format"
    )
    async def metrics():
        """
        Prometheus metrics endpoint.

        Returns:
            Plain text Prometheus metrics
        """
        if not settings.prometheus_enabled:
            raise HTTPException(status_code=404, detail="Metrics disabled")

        return JSONResponse(
            content=generate_latest().decode("utf-8"),
            media_type=CONTENT_TYPE_LATEST
        )

    # Cache management endpoints
    @app.delete(
        "/cache",
        tags=["Cache"],
        summary="Clear cache",
        description="Clear all cached weather data"
    )
    async def clear_cache():
        """Clear all cached data."""
        logger.info("Cache clear requested")
        success = await cache.clear()
        if success:
            logger.info("Cache cleared successfully")
            return {"message": "Cache cleared successfully"}
        else:
            logger.error("Failed to clear cache")
            raise HTTPException(status_code=500, detail="Failed to clear cache")

    # Root endpoint
    @app.get(
        "/",
        tags=["Info"],
        summary="API information",
        description="Returns basic API information"
    )
    async def root():
        """Return API information."""
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "docs": "/docs",
            "health": "/health",
            "weather": "/weather?city=London",
            "diagnostics": "/diagnostics",
            "metrics": "/metrics"
        }

    # Error handler
    @app.exception_handler(HTTPException)
    async def http_exception_handler(request, exc):
        """Handle HTTP exceptions."""
        logger.error(f"HTTP exception: {exc.status_code} - {exc.detail}")
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": exc.detail,
                "code": f"HTTP_{exc.status_code}"
            }
        )

    return app


# Create application instance
app = create_app()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        workers=settings.workers,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )

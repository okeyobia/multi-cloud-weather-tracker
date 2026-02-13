"""Configuration management using Pydantic Settings."""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    app_name: str = "Weather Tracker API"
    app_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"

    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 4

    # OpenWeatherMap API
    openweather_api_key: str
    openweather_base_url: str = "https://api.openweathermap.org/data/2.5"
    openweather_timeout: int = 10

    # Redis
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    redis_cache_ttl: int = 3600  # 1 hour

    # Prometheus
    prometheus_enabled: bool = True
    prometheus_port: int = 8001

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()

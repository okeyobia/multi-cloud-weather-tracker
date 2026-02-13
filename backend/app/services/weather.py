"""Weather API service for fetching weather data."""
import httpx
import time
from typing import Optional, Dict, Any
from datetime import datetime
from app.config import settings
from app.models import WeatherData
from app.services.cache import cache
from app.utils.logging import get_logger
from app.utils.metrics import weather_api_calls, weather_api_duration

logger = get_logger(__name__)


class WeatherService:
    """Service for fetching weather data from OpenWeatherMap API."""

    def __init__(self):
        """Initialize weather service."""
        self.base_url = settings.openweather_base_url
        self.api_key = settings.openweather_api_key
        self.timeout = settings.openweather_timeout

    async def get_weather(self, city: str) -> Optional[WeatherData]:
        """
        Fetch weather data for a city.

        Args:
            city: City name to fetch weather for

        Returns:
            WeatherData object or None if failed
        """
        # Check cache first
        cache_key = f"weather:{city.lower()}"
        cached_data = await cache.get(cache_key)
        if cached_data:
            logger.info(f"Returning cached weather data for {city}")
            return WeatherData(**cached_data)

        try:
            start_time = time.time()
            weather_data = await self._fetch_from_api(city)
            duration = time.time() - start_time

            if weather_data:
                # Cache the result
                await cache.set(cache_key, weather_data.dict())
                weather_api_calls.labels(city=city, status="success").inc()
                weather_api_duration.observe(duration)
                logger.info(f"Successfully fetched weather for {city}", extra={
                    "duration": duration,
                    "city": city
                })
                return weather_data
            else:
                weather_api_calls.labels(city=city, status="not_found").inc()
                logger.warning(f"City not found: {city}")
                return None

        except Exception as e:
            duration = time.time() - start_time
            weather_api_calls.labels(city=city, status="error").inc()
            weather_api_duration.observe(duration)
            logger.error(f"Error fetching weather for {city}", extra={
                "error": str(e),
                "city": city,
                "duration": duration
            })
            return None

    async def _fetch_from_api(self, city: str) -> Optional[WeatherData]:
        """Fetch weather data from OpenWeatherMap API."""
        params = {
            "q": city,
            "appid": self.api_key,
            "units": "metric"
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params=params
                )
                
                # Handle 401/403 - API key issues
                if response.status_code == 401:
                    logger.error("Invalid API key: Unauthorized access to OpenWeatherMap API")
                    return None
                if response.status_code == 403:
                    logger.error("API key forbidden: Check API permissions and quota")
                    return None
                
                # Handle 404 - City not found
                if response.status_code == 404:
                    logger.warning(f"City not found in OpenWeatherMap: {city}")
                    return None
                
                response.raise_for_status()
                data = response.json()

                return WeatherData(
                    city=data.get("name", city),
                    temperature=data["main"]["temp"],
                    description=data["weather"][0]["main"],
                    cloudProvider="AWS",
                    isFailover=False,
                    lastUpdated=datetime.utcnow().isoformat(),
                    feels_like=data["main"]["feels_like"],
                    humidity=data["main"]["humidity"],
                    pressure=data["main"]["pressure"],
                    wind_speed=data["wind"]["speed"],
                    cloudiness=data["clouds"]["all"]
                )

        except httpx.HTTPStatusError as e:
            logger.error(
                f"OpenWeatherMap API error: {e.response.status_code}",
                extra={
                    "status_code": e.response.status_code,
                    "response": e.response.text[:200]
                }
            )
            return None
        except httpx.RequestError as e:
            logger.error(f"Network error connecting to OpenWeatherMap: {str(e)}")
            return None
        except (KeyError, ValueError) as e:
            logger.error(
                f"Invalid response format from OpenWeatherMap: {str(e)}",
                extra={"error_type": type(e).__name__}
            )
            return None

    async def health_check(self) -> bool:
        """Check if OpenWeatherMap API is accessible."""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params={"q": "London", "appid": self.api_key}
                )
                return response.status_code == 200
        except Exception as e:
            logger.error(f"Health check failed: {str(e)}")
            return False


# Global weather service instance
weather_service = WeatherService()

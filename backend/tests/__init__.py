"""Unit tests for Weather Tracker API."""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from app.main import app
from app.models import WeatherData
from datetime import datetime


client = TestClient(app)


class TestHealthEndpoint:
    """Tests for health check endpoint."""

    def test_health_check_success(self):
        """Test successful health check."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "version" in data
        assert data["version"] == "1.0.0"

    def test_health_check_has_timestamp(self):
        """Test health check includes timestamp."""
        response = client.get("/health")
        data = response.json()
        assert "timestamp" in data


class TestWeatherEndpoint:
    """Tests for weather endpoint."""

    @patch("app.services.weather.weather_service.get_weather")
    def test_get_weather_success(self, mock_get_weather):
        """Test successful weather retrieval."""
        mock_data = WeatherData(
            city="London",
            temperature=10.5,
            feels_like=9.2,
            humidity=72,
            pressure=1013,
            weather="Cloudy",
            wind_speed=3.5,
            cloudiness=85,
            timestamp=datetime.utcnow()
        )
        mock_get_weather.return_value = mock_data

        response = client.get("/weather?city=London")
        assert response.status_code == 200
        data = response.json()
        assert data["city"] == "London"
        assert data["temperature"] == 10.5
        assert data["humidity"] == 72

    @patch("app.services.weather.weather_service.get_weather")
    def test_get_weather_not_found(self, mock_get_weather):
        """Test weather not found response."""
        mock_get_weather.return_value = None

        response = client.get("/weather?city=NonexistentCity")
        assert response.status_code == 404

    def test_get_weather_missing_city_parameter(self):
        """Test weather endpoint without city parameter."""
        response = client.get("/weather")
        assert response.status_code == 422  # Unprocessable Entity

    def test_get_weather_empty_city(self):
        """Test weather endpoint with empty city."""
        response = client.get("/weather?city=")
        assert response.status_code == 422


class TestMetricsEndpoint:
    """Tests for Prometheus metrics endpoint."""

    def test_metrics_endpoint_success(self):
        """Test metrics endpoint returns data."""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "weather_api_requests_total" in response.text or response.text

    def test_metrics_content_type(self):
        """Test metrics endpoint content type."""
        response = client.get("/metrics")
        assert "text/plain" in response.headers.get("content-type", "")


class TestCacheEndpoint:
    """Tests for cache management."""

    @patch("app.services.cache.cache.clear")
    async def test_clear_cache_success(self, mock_clear):
        """Test successful cache clear."""
        mock_clear.return_value = True

        response = client.delete("/cache")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data


class TestRootEndpoint:
    """Tests for root endpoint."""

    def test_root_endpoint(self):
        """Test root endpoint returns API info."""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "name" in data
        assert "version" in data
        assert "docs" in data
        assert "health" in data
        assert "weather" in data


class TestErrorHandling:
    """Tests for error handling."""

    def test_404_not_found(self):
        """Test 404 error response."""
        response = client.get("/nonexistent")
        assert response.status_code == 404

    def test_invalid_query_parameter(self):
        """Test invalid query parameter handling."""
        response = client.get("/weather?invalid=param")
        assert response.status_code == 422


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

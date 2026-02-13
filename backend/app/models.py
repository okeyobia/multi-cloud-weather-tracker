"""Pydantic models for request and response validation."""
from pydantic import BaseModel, Field
from typing import Optional


class WeatherData(BaseModel):
    """Weather data model."""

    city: str = Field(..., description="City name")
    temperature: float = Field(..., description="Temperature in Celsius")
    description: str = Field(..., description="Weather description")
    cloudProvider: str = Field(default="AWS", description="Cloud provider (AWS or Azure)")
    isFailover: bool = Field(default=False, description="Whether using failover/secondary region")
    lastUpdated: str = Field(..., description="Last update timestamp in ISO format")
    feels_like: float = Field(..., description="Feels like temperature in Celsius")
    humidity: int = Field(..., description="Humidity percentage")
    pressure: int = Field(..., description="Pressure in hPa")
    wind_speed: float = Field(..., description="Wind speed in m/s")
    cloudiness: int = Field(..., description="Cloudiness percentage")

    class Config:
        json_schema_extra = {
            "example": {
                "city": "London",
                "temperature": 10.5,
                "description": "Cloudy",
                "cloudProvider": "AWS",
                "isFailover": False,
                "lastUpdated": "2024-01-15T10:30:00",
                "feels_like": 9.2,
                "humidity": 72,
                "pressure": 1013,
                "wind_speed": 3.5,
                "cloudiness": 85
            }
        }


class HealthCheck(BaseModel):
    """Health check response model."""

    status: str = Field(..., description="Health status")
    version: str = Field(..., description="Application version")
    timestamp: str = Field(..., description="Timestamp in ISO format")

    class Config:
        json_schema_extra = {
            "example": {
                "status": "healthy",
                "version": "1.0.0",
                "timestamp": "2024-01-15T10:30:00"
            }
        }


class ErrorResponse(BaseModel):
    """Error response model."""

    error: str = Field(..., description="Error message")
    code: str = Field(..., description="Error code")
    timestamp: str = Field(..., description="Timestamp in ISO format")

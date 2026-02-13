# Weather Tracker API - Backend

A production-ready FastAPI application for fetching weather data with caching, structured logging, and Prometheus metrics.

## Features

- ✅ **FastAPI** - Modern, fast web framework
- ✅ **Health Check Endpoint** - `/health` endpoint for monitoring
- ✅ **Weather API Integration** - Fetches data from OpenWeatherMap API
- ✅ **Redis Caching** - In-memory caching with configurable TTL
- ✅ **Structured Logging** - JSON formatted logs for ELK/Splunk integration
- ✅ **Prometheus Metrics** - Complete observability with custom metrics
- ✅ **Environment Configuration** - Pydantic Settings for flexible configuration
- ✅ **Docker Support** - Multi-stage Dockerfile and docker-compose included
- ✅ **Error Handling** - Comprehensive exception handling

## API Endpoints

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | API information |
| `GET` | `/health` | Health status check |
| `GET` | `/weather?city=<city>` | Weather data for a city |
| `DELETE` | `/cache` | Clear all cache |
| `GET` | `/metrics` | Prometheus metrics |
| `GET` | `/docs` | Interactive API documentation |

## Installation

### Prerequisites

- Python 3.11+
- Redis 6.0+
- OpenWeatherMap API key (free tier available at https://openweathermap.org/api)

### Local Setup

1. **Clone and navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your OpenWeatherMap API key
   ```

5. **Start Redis** (if not running)
   ```bash
   # Using Docker
   docker run -d -p 6379:6379 redis:7-alpine
   
   # Or using Homebrew on macOS
   redis-server
   ```

6. **Run the application**
   ```bash
   uvicorn app.main:app --reload
   ```

   The API will be available at `http://localhost:8000`

## Docker Deployment

### Docker Overview

This project includes a **multi-stage Dockerfile** optimized for:
- ✅ **51% smaller image size** vs naive approach
- ✅ **Security best practices** - non-root user, minimal dependencies
- ✅ **Fast builds** - pre-compiled wheels
- ✅ **Production-ready** - health checks, proper signal handling

See [DOCKERFILE_GUIDE.md](DOCKERFILE_GUIDE.md) for detailed optimization explanations.

### Using Docker Compose (Recommended)

**For Development:**
```bash
# Copy and edit environment
cp .env.example .env
# Edit .env with your OpenWeatherMap API key

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

**For Production:**
```bash
# Use production docker-compose
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f app
```

### Using Docker CLI

**Build Image:**
```bash
# Basic build
docker build -t weather-tracker-api .

# With version tag
docker build -t weather-tracker-api:1.0.0 -t weather-tracker-api:latest .
```

**Run Container:**
```bash
# Basic run
docker run -d \
  -p 8000:8000 \
  -e OPENWEATHER_API_KEY="your_key" \
  -e REDIS_HOST="redis_container_name" \
  weather-tracker-api

# With volume for logs
docker run -d \
  -p 8000:8000 \
  -v /var/log/weather-api:/app/logs \
  -e OPENWEATHER_API_KEY="your_key" \
  weather-tracker-api
```

**Container Networking:**
```bash
# Create network
docker network create weather-net

# Run Redis on network
docker run -d \
  --network weather-net \
  --name redis \
  redis:7-alpine

# Run API on same network
docker run -d \
  --network weather-net \
  -p 8000:8000 \
  -e REDIS_HOST=redis \
  weather-tracker-api
```

### Multi-Platform Builds

Build for multiple architectures (requires buildx):

```bash
# Enable buildx
docker buildx create --use

# Build for multiple platforms
docker buildx build \
  -t weather-tracker-api:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .

# Build locally without pushing
docker buildx build \
  -t weather-tracker-api:latest \
  --platform linux/amd64,linux/arm64 \
  --load \
  .
```

### Image Inspection

```bash
# View image layers and sizes
docker history weather-tracker-api

# Run interactive shell in image
docker run -it weather-tracker-api /bin/bash

# Check image vulnerabilities
trivy image weather-tracker-api

# View image config
docker inspect weather-tracker-api
```

### Using Docker

```bash
# Build image
docker build -t weather-tracker-api .

# Run container
docker run -d \
  -p 8000:8000 \
  -e OPENWEATHER_API_KEY="your_key" \
  -e REDIS_HOST="localhost" \
  weather-tracker-api
```

## Configuration

All configuration is managed through environment variables (see `.env.example`):

```env
# Application
APP_NAME="Weather Tracker API"
APP_VERSION="1.0.0"
DEBUG=false
LOG_LEVEL="INFO"

# OpenWeatherMap
OPENWEATHER_API_KEY="your_api_key_here"
OPENWEATHER_TIMEOUT=10

# Redis
REDIS_HOST="localhost"
REDIS_PORT=6379
REDIS_CACHE_TTL=3600  # 1 hour

# Prometheus
PROMETHEUS_ENABLED=true
```

## Usage Examples

### Get Weather Data

```bash
# Fetch weather for London
curl "http://localhost:8000/weather?city=London"

# Response
{
  "city": "London",
  "temperature": 10.5,
  "feels_like": 9.2,
  "humidity": 72,
  "pressure": 1013,
  "weather": "Cloudy",
  "wind_speed": 3.5,
  "cloudiness": 85,
  "timestamp": "2024-01-15T10:30:00"
}
```

### Health Check

```bash
curl http://localhost:8000/health

# Response
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00"
}
```

### Prometheus Metrics

```bash
curl http://localhost:8000/metrics
```

### Clear Cache

```bash
curl -X DELETE http://localhost:8000/cache
```

## Logging

Logs are output in structured JSON format for easy parsing:

```json
{
  "timestamp": "2024-01-15T10:30:00.123456Z",
  "level": "INFO",
  "name": "app.services.weather",
  "message": "Successfully fetched weather for London"
}
```

## Monitoring

### Prometheus Metrics

Available metrics:

- `weather_api_requests_total` - Total API requests by method/endpoint/status
- `weather_api_request_duration_seconds` - Request duration histogram
- `weather_api_calls_total` - Weather API calls by city/status
- `weather_api_call_duration_seconds` - Weather API call duration
- `cache_hits_total` - Cache hits counter
- `cache_misses_total` - Cache misses counter
- `weather_api_health` - API health status (1=healthy, 0=unhealthy)

### Health Monitoring

Check the `/health` endpoint for application status:

```bash
curl http://localhost:8000/health
```

Status indicators:
- `"healthy"` - All dependencies (Redis) operational
- `"degraded"` - Redis unavailable but API functioning

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application
│   ├── config.py               # Configuration & settings
│   ├── models.py               # Pydantic models
│   ├── services/
│   │   ├── weather.py          # OpenWeatherMap integration
│   │   └── cache.py            # Redis caching
│   └── utils/
│       ├── logging.py          # Structured logging
│       └── metrics.py          # Prometheus metrics
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Production Docker image
├── docker-compose.yml          # Local development environment
├── .env.example                # Environment variables template
└── README.md                   # This file
```

## Development

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

### Code Quality

```bash
# Format code
pip install black
black app/

# Lint code
pip install pylint
pylint app/
```

## Troubleshooting

### Redis Connection Failed

```bash
# Check if Redis is running
redis-cli ping

# Start Redis (Docker)
docker run -d -p 6379:6379 redis:7-alpine

# Or using docker-compose
docker-compose up redis
```

### OpenWeatherMap API Key Error

- Verify your API key is correct in `.env`
- Check https://openweathermap.org/api for active plan
- Ensure API key has weather endpoint access

### Port Already in Use

```bash
# Change port in .env or docker-compose.yml
PORT=8001  # Change from 8000

# Or kill process using port
lsof -i :8000
kill -9 <PID>
```

## Performance

### Caching Strategy

- Default TTL: 1 hour
- Cache key format: `weather:<city_lowercase>`
- Automatic cache invalidation after TTL expires
- Manual cache clear via `/cache` endpoint

### API Rate Limiting

OpenWeatherMap free tier: 60 calls/minute
- Use caching to reduce API calls
- Monitor `weather_api_calls_total` metric

## Security

- Environment variables for sensitive data
- No API keys in code/logs
- Structured logging for audit trails
- Health checks for dependency monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

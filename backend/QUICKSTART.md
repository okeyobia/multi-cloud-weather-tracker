# Quick Start Guide

Get the Weather Tracker API running in 5 minutes!

## Prerequisites

- Python 3.11+ ([Download](https://www.python.org/downloads/))
- OpenWeatherMap API Key ([Get Free Key](https://openweathermap.org/api))
- Redis (optional, included in docker-compose)

## Option 1: Using the Quick Start Script (Recommended)

### macOS/Linux

```bash
cd backend
chmod +x run.sh
./run.sh
```

The script will:
- ✅ Create a Python virtual environment
- ✅ Install dependencies
- ✅ Start Redis in Docker (if needed)
- ✅ Launch the API server

### Windows

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
redis-server  # In another terminal
python -m uvicorn app.main:app --reload
```

## Option 2: Using Make Commands

```bash
cd backend
make install    # Install dependencies
make docker-up  # Start Redis in Docker
make dev        # Run development server
```

## Option 3: Using Docker Compose

```bash
cd backend
export OPENWEATHER_API_KEY="your_api_key_here"
docker-compose up
```

## Setup Steps

### 1. Get OpenWeatherMap API Key

1. Visit https://openweathermap.org/api
2. Sign up for free account
3. Get your API key from account dashboard

### 2. Configure Environment

```bash
cd backend
cp .env.example .env
# Edit .env and add your API key
```

### 3. Start Redis

**Option A: Docker (Recommended)**
```bash
docker run -d -p 6379:6379 --name weather-redis redis:7-alpine
```

**Option B: Homebrew (macOS)**
```bash
brew install redis
redis-server
```

**Option C: APT (Ubuntu/Debian)**
```bash
sudo apt-get install redis-server
redis-server
```

### 4. Create Virtual Environment & Install Dependencies

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 5. Run the Application

```bash
uvicorn app.main:app --reload
```

## Testing the API

### In Your Browser

- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Weather Data**: http://localhost:8000/weather?city=London

### Using curl

```bash
# Get weather for a city
curl "http://localhost:8000/weather?city=New%20York"

# Health check
curl http://localhost:8000/health

# View metrics
curl http://localhost:8000/metrics

# Clear cache
curl -X DELETE http://localhost:8000/cache
```

### Using Python

```python
import requests

# Weather API
response = requests.get("http://localhost:8000/weather?city=London")
print(response.json())

# Health check
health = requests.get("http://localhost:8000/health")
print(health.json())
```

## Common Issues

### "Port 8000 already in use"

```bash
# Find and kill process
lsof -i :8000
kill -9 <PID>

# Or use different port
uvicorn app.main:app --port 8001
```

### "Redis connection refused"

```bash
# Start Redis with Docker
docker run -d -p 6379:6379 redis:7-alpine

# Verify Redis is running
redis-cli ping  # Should output: PONG
```

### "API key not working"

1. Verify key in `.env` file
2. Check API key at https://openweathermap.org/api
3. Ensure you have an active free tier plan
4. Wait a few minutes for API key to activate

### "ModuleNotFoundError: No module named 'fastapi'"

```bash
# Ensure virtual environment is activated
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Reinstall dependencies
pip install -r requirements.txt
```

## Next Steps

1. 📚 Read the [Main README](README.md) for detailed documentation
2. 🧪 Run tests: `pytest`
3. 📊 Check metrics: http://localhost:8000/metrics
4. 🔍 Explore API docs: http://localhost:8000/docs
5. 🐳 Deploy with Docker: `docker-compose up -d`

## Support

- 📖 [FastAPI Documentation](https://fastapi.tiangolo.com/)
- 🔑 [OpenWeatherMap API Docs](https://openweathermap.org/api)
- 💾 [Redis Documentation](https://redis.io/docs/)
- 📊 [Prometheus Docs](https://prometheus.io/docs/)

## Performance Tips

1. **Enable caching**: Leave Redis running for better performance
2. **Monitor metrics**: Check `/metrics` to track API usage
3. **Use structured logs**: Parse JSON logs with ELK/Splunk
4. **Health checks**: Integrate `/health` with load balancers

---

**Happy Weather Tracking! 🌤️**

#!/bin/bash
# FastAPI Weather Tracker - Quick Start Script

set -e

echo "🚀 Weather Tracker API - Quick Start"
echo "===================================="

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
    echo "📝 Please edit .env and add your OpenWeatherMap API key"
    read -p "Press enter to continue..."
fi

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

echo "✅ Python found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt > /dev/null 2>&1

# Check for Redis
echo "🔍 Checking for Redis..."
if ! command -v redis-server &> /dev/null && ! command -v redis-cli &> /dev/null; then
    echo "⚠️  Redis not found locally. Starting Redis with Docker..."
    if command -v docker &> /dev/null; then
        docker run -d -p 6379:6379 --name weather-redis redis:7-alpine 2>/dev/null || true
        sleep 2
    else
        echo "❌ Docker not found. Please install Redis and start it manually:"
        echo "   brew install redis  # macOS"
        echo "   Or use Docker: docker run -d -p 6379:6379 redis:7-alpine"
        exit 1
    fi
else
    echo "✅ Redis found"
fi

# Start the application
echo ""
echo "🌍 Starting Weather Tracker API..."
echo "📚 Documentation: http://localhost:8000/docs"
echo "💚 Health check: http://localhost:8000/health"
echo "🌤️  Weather API: http://localhost:8000/weather?city=London"
echo ""

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

.PHONY: help install dev test lint format clean docker-build docker-up docker-down

help:
	@echo "Weather Tracker API - Available Commands"
	@echo "========================================"
	@echo "  make install      - Install dependencies"
	@echo "  make dev          - Run development server"
	@echo "  make test         - Run tests"
	@echo "  make lint         - Run code linter"
	@echo "  make format       - Format code with Black"
	@echo "  make clean        - Clean up temporary files"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-up    - Start services with Docker Compose"
	@echo "  make docker-down  - Stop and remove Docker containers"

install:
	pip install -r requirements.txt
	pip install pytest pytest-asyncio black pylint

dev:
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

test:
	pytest tests/ -v --cov=app --cov-report=html

lint:
	pylint app/ --disable=R,C

format:
	black app/ tests/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".coverage" -delete
	find . -type d -name "htmlcov" -delete
	find . -type d -name "dist" -delete
	find . -type d -name "build" -delete
	find . -type d -name "*.egg-info" -delete

docker-build:
	docker build -t weather-tracker-api .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f api

docker-ps:
	docker-compose ps

redis-cli:
	docker exec -it weather-tracker-redis redis-cli

.DEFAULT_GOAL := help

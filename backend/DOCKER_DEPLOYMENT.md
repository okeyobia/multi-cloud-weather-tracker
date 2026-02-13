# Docker Deployment Guide

Complete guide for deploying the Weather Tracker API using Docker and Docker Compose.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Development Setup](#development-setup)
3. [Production Setup](#production-setup)
4. [Multi-Platform Deployment](#multi-platform-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+ (or use `docker compose`)
- OpenWeatherMap API key

### 30-Second Setup

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your OpenWeatherMap API key

# 2. Start services
docker-compose up -d

# 3. Test API
curl http://localhost:8000/health
```

## Development Setup

### Local Development with Docker Compose

Perfect for development with hot-reload and easy debugging.

```bash
# Copy environment
cp .env.example .env

# Edit configuration
nano .env  # Or your favorite editor

# Start services (attaches logs)
docker-compose up

# Or run in background
docker-compose up -d
docker-compose logs -f api
```

### Docker Compose Development File

```yaml
# docker-compose.yml
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY}
      - REDIS_HOST=redis
    depends_on:
      redis:
        condition: service_healthy
    volumes:
      - .:/app  # Mount source code for live reload

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

### Development Workflow

```bash
# 1. Make code changes (auto-reload enabled)
# 2. Check logs in real-time
docker-compose logs -f api

# 3. Rebuild image after dependency changes
docker-compose build
docker-compose up -d

# 4. Run tests in container
docker-compose exec api pytest

# 5. Access shell
docker-compose exec api bash

# 6. Clean up
docker-compose down -v  # -v removes volumes
```

## Production Setup

### Production Deployment

For production, we use:
- Non-development dependencies
- No volume mounts
- Health checks
- Restart policies
- Logging drivers
- Security settings

```bash
# 1. Create production environment
cp .env.example .env.prod
nano .env.prod

# 2. Build optimized image
docker build -t weather-tracker-api:1.0.0 .

# 3. Start with production compose
docker-compose -f docker-compose.yml \
  -f docker-compose.prod.yml up -d

# 4. Monitor
docker-compose -f docker-compose.yml \
  -f docker-compose.prod.yml logs -f
```

### Production Docker Compose

```yaml
# docker-compose.prod.yml
services:
  api:
    restart: unless-stopped
    
    # Port only accessible locally
    ports:
      - "127.0.0.1:8000:8000"
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      retries: 3
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

### Production Checklist

- [ ] API key is secret (use `.env` or secrets management)
- [ ] Redis password configured (if exposed to network)
- [ ] Health checks working (`docker ps`)
- [ ] Logs are aggregated and rotated
- [ ] Nginx reverse proxy configured (optional)
- [ ] SSL certificates obtained (for HTTPS)
- [ ] Database backups configured
- [ ] Monitoring/alerting set up
- [ ] Resource limits configured

### Environment Configuration

```bash
# Production .env
OPENWEATHER_API_KEY=your_production_key_here
DEBUG=false
LOG_LEVEL=INFO
REDIS_HOST=redis-prod.example.com
REDIS_PASSWORD=<strong_password>
WORKERS=4
```

## Multi-Platform Deployment

### Build for Multiple Architectures

```bash
# Enable Docker buildx
docker buildx create --use

# Build for multiple platforms
docker buildx build \
  -t weather-tracker-api:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .
```

### Supported Platforms

| Platform | Use Case |
|----------|----------|
| `linux/amd64` | Intel/AMD servers (AWS, GCP, Azure) |
| `linux/arm64` | ARM servers (Apple Silicon, Graviton) |
| `linux/arm/v7` | Raspberry Pi, IoT devices |

### Push to Registry

```bash
# Docker Hub
docker buildx build \
  -t your-username/weather-tracker:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .

# AWS ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

docker tag weather-tracker:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest

docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/weather-tracker:latest
```

## Kubernetes Deployment

### Deploy to Kubernetes

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weather-tracker-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: weather-tracker-api
  template:
    metadata:
      labels:
        app: weather-tracker-api
    spec:
      containers:
      - name: api
        image: weather-tracker-api:1.0.0
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
        env:
        - name: OPENWEATHER_API_KEY
          valueFrom:
            secretKeyRef:
              name: weather-secrets
              key: api-key
        - name: REDIS_HOST
          value: redis-service
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: weather-tracker-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8000
  selector:
    app: weather-tracker-api
```

### Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace weather-tracker

# Create secret for API key
kubectl create secret generic weather-secrets \
  --from-literal=api-key=your_api_key \
  -n weather-tracker

# Deploy application
kubectl apply -f k8s/ -n weather-tracker

# Monitor deployment
kubectl get pods -n weather-tracker
kubectl logs -f deployment/weather-tracker-api -n weather-tracker

# Port forward to test
kubectl port-forward svc/weather-tracker-service 8000:80 -n weather-tracker
```

## Nginx Reverse Proxy

### Production Setup with Nginx

```bash
# Use docker-compose.prod.yml which includes nginx service
docker-compose -f docker-compose.yml \
  -f docker-compose.prod.yml up -d

# Check status
docker-compose ps
```

### SSL/TLS Configuration

```bash
# Generate self-signed certificate (for testing)
mkdir -p ssl
openssl req -x509 -newkey rsa:4096 -nodes \
  -out ssl/cert.pem -keyout ssl/key.pem -days 365

# For production, use Let's Encrypt
# See nginx.conf for ACME challenge configuration
```

### Access APIs

```bash
# Through nginx
curl https://weather-api.example.com/health

# Rate limiting enabled
for i in {1..1000}; do
  curl -s https://weather-api.example.com/weather?city=London
done
# After ~100 requests, you'll get 429 (Too Many Requests)
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs api

# Rebuild
docker-compose build --no-cache
docker-compose up

# Debug shell
docker run -it weather-tracker-api /bin/bash
```

### Slow startup

```bash
# Check if Redis is slow
docker-compose logs redis

# Increase timeout in health check
# Modify docker-compose.yml:
healthcheck:
  start_period: 30s  # Increase from 5s
```

### Out of memory

```bash
# Check memory usage
docker stats

# Limit container memory
docker run -m 1g weather-tracker-api

# In docker-compose:
services:
  api:
    deploy:
      resources:
        limits:
          memory: 1g
```

### Port already in use

```bash
# Find process using port
lsof -i :8000

# Change port in docker-compose
ports:
  - "8001:8000"  # Change from 8000 to 8001
```

### Volume permission issues

```bash
# Fix ownership
sudo chown -R $USER:$USER logs/

# Or run as specific user in Dockerfile
USER appuser
```

## Performance Tuning

### Optimize Image Size

```bash
# Check layer sizes
docker history weather-tracker-api

# Use Alpine (even smaller)
# Modify Dockerfile: FROM python:3.11-alpine
```

### Optimize Build Speed

```bash
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker build .

# Or set in daemon.json
# {"features": {"buildkit": true}}
```

### Multi-stage Build Benefits

```bash
# Original size: 450MB
# After multi-stage: 220MB  (51% reduction)

# Final image layers
docker run weather-tracker-api du -sh /
```

## Security Best Practices

### Container Security

```bash
# Scan for vulnerabilities
trivy image weather-tracker-api

# Run as non-root (built-in)
docker run -u appuser weather-tracker-api id
# uid=1000(appuser) gid=1000(appuser) groups=1000(appuser)

# Use read-only filesystem (if possible)
docker run --read-only weather-tracker-api
```

### Network Security

```bash
# Use specific network
docker network create weather-net
docker run --network weather-net weather-tracker-api

# Don't expose unnecessary ports
# Only expose 8000 for API
# Use internal networks for Redis, databases
```

### Secret Management

```bash
# Use environment files
docker run --env-file .env.prod weather-tracker-api

# For Kubernetes, use secrets
kubectl create secret generic weather-secrets

# For Docker Swarm, use docker secrets
echo "api_key" | docker secret create weather_api_key -
```

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best Practices](https://docs.docker.com/develop/image-bestpractices/)
- [Security](https://docs.docker.com/engine/security/)
- [Kubernetes](https://kubernetes.io/docs/)

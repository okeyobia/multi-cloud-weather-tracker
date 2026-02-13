# Dockerfile Guide - Production Optimization

This document explains the multi-stage Dockerfile used for the Weather Tracker FastAPI application and the security and performance optimizations employed.

## Overview

The Dockerfile uses a **two-stage build process**:

1. **Builder Stage** - Compiles dependencies into wheels (pre-built packages)
2. **Production Stage** - Uses only the compiled wheels, minimal dependencies

## Stage 1: Builder

```dockerfile
FROM python:3.11-slim as builder
```

### Purpose
- Compile Python packages into wheels (.whl files)
- Wheels are pre-built, compiled Python packages that install much faster
- Contains build tools (gcc) that are not needed in production

### Why Wheels?
- **Speed**: Pre-compiled wheels install in ~0.1s vs 10-30s from source
- **Size**: No build artifacts in final image
- **Reliability**: Guaranteed consistent builds

### Build Dependencies
```dockerfile
gcc=4:12.2.0-3
```
- Pinned to specific version for reproducibility
- Required to compile Python packages with C extensions
- Removed after wheel compilation

## Stage 2: Production Image

```dockerfile
FROM python:3.11-slim
```

### Optimal Base Image Choice

| Image | Size | When to use |
|-------|------|------------|
| `python:3.11-slim` | ~130MB | **Recommended** - Small, production-ready |
| `python:3.11-alpine` | ~50MB | Smallest, but missing build tools |
| `python:3.11` | ~920MB | Full-featured, overkill for most apps |

**We chose `slim`** because it:
- ✅ Includes essential runtime libraries
- ✅ Smaller than full Python image  
- ✅ More reliable than Alpine
- ✅ Good balance of size vs functionality

## Security Best Practices

### 1. Non-Root User

```dockerfile
RUN groupadd -r appuser && useradd -r -g appuser appuser
USER appuser
```

**Why?** 
- Prevents container breakout exploits that gain root access
- Limits damage if application is compromised
- Industry standard security practice

**How it works:**
- `groupadd -r appuser` - Create restricted group
- `useradd -r -g appuser appuser` - Create restricted user
- `USER appuser` - Run container as this user

### 2. File Ownership

```dockerfile
COPY --chown=appuser:appuser . .
```

**Why?**
- Ensures application files are owned by the app user
- Prevents escalation from within the container

### 3. Minimal Dependencies

```dockerfile
# Runtime dependencies only
curl           # Health checks
ca-certificates # HTTPS verification
```

**Why?**
- Fewer packages = smaller attack surface
- No gcc, build tools, or development headers
- Smaller image size = faster deployment

### 4. Metadata Labels

```dockerfile
LABEL maintainer="Weather Tracker Team"
LABEL description="Production-ready FastAPI weather tracking application"
LABEL version="1.0.0"
```

**Why?**
- Container registry tracking
- License/compliance documentation
- Image identification in production

## Performance Optimizations

### 1. Layer Caching

Dockerfile layers are cached independently. Order matters:

```dockerfile
# ✅ Good - Changes rarely
COPY requirements.txt .
RUN pip wheel ...

# ✅ Good - Changes frequently  
COPY . .
```

This ensures:
- Dependencies only rebuild when requirements.txt changes
- Application code changes don't rebuild dependencies

### 2. Environment Variables

```dockerfile
ENV PYTHONDONTWRITEBYTECODE=1     # Don't create .pyc files
ENV PYTHONUNBUFFERED=1            # Immediate logging output
ENV PYTHONHASHSEED=random         # Security randomization
ENV PIP_NO_CACHE_DIR=1            # Don't cache pip packages
ENV PIP_DISABLE_PIP_VERSION_CHECK=1 # Skip version check
```

**Benefits:**
- Faster logging (unbuffered)
- Reduced disk I/O (no .pyc files)
- Better security (hash randomization)

### 3. Multi-Arch Build

Build for multiple architectures:

```bash
docker buildx build \
  -t myapp:latest \
  --platform linux/amd64,linux/arm64 \
  .
```

Supports:
- `linux/amd64` - Intel/AMD processors (most servers)
- `linux/arm64` - ARM processors (Apple Silicon, Raspberry Pi)

## Size Comparison

| Image Generation | Size | Savings |
|------------------|------|---------|
| Single stage (all tools) | ~450MB | Baseline |
| Multi-stage (wheels) | ~220MB | 51% reduction |
| Alpine (slim variant) | ~50MB | 89% reduction |

**Our choice: Multi-stage slim = Best balance**
- Production-grade reliability
- 51% smaller than naïve approach  
- Faster than Alpine for our use case

## Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1
```

**Configuration:**
- **interval=30s** - Check every 30 seconds
- **timeout=10s** - Wait max 10 seconds for response
- **start-period=5s** - Wait 5s before first check
- **retries=3** - Fail after 3 consecutive failures

**Usage:**
```bash
# Check container health
docker ps
# HEALTHCHECK shows "(healthy)" or "(unhealthy)"

# In docker-compose
depends_on:
  redis:
    condition: service_healthy
```

## Building the Image

### Basic Build

```bash
docker build -t weather-tracker-api .
```

### With Tags

```bash
docker build \
  -t weather-tracker-api:latest \
  -t weather-tracker-api:1.0.0 \
  .
```

### Multi-Platform Build

```bash
# Requires buildx
docker buildx build \
  -t weather-tracker-api:latest \
  --platform linux/amd64,linux/arm64 \
  --push \
  .
```

## Running the Container

### Basic Run

```bash
docker run -p 8000:8000 weather-tracker-api
```

### With Environment Variables

```bash
docker run \
  -p 8000:8000 \
  -e OPENWEATHER_API_KEY="your_key" \
  -e REDIS_HOST="redis" \
  weather-tracker-api
```

### Docker Compose (Recommended)

```yaml
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
    
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
```

## Debugging Dockerfile

### View Layers

```bash
docker history weather-tracker-api
```

Shows each layer, how it was created, and its size.

### Interactive Debugging

Stop at a layer to debug:

```bash
# Run intermediate builder image
docker build --target builder -t weather-tracker-builder .
docker run -it weather-tracker-builder /bin/bash
```

### Check Image Contents

```bash
# List files in image
docker run weather-tracker-api ls -la /app

# Check installed packages
docker run weather-tracker-api pip list

# Check user/permissions
docker run weather-tracker-api id
```

## Security Scanning

Scan for vulnerabilities:

```bash
# Using Trivy
trivy image weather-tracker-api

# Using Grype
grype weather-tracker-api

# Using Snyk (requires login)
snyk container test weather-tracker-api
```

## Production Checklist

- [x] Non-root user configured
- [x] Multi-stage build reduces size
- [x] Minimal runtime dependencies
- [x] Health checks configured
- [x] Version pinning for reproducibility
- [x] Proper signal handling (Uvicorn)
- [x] Logging output unbuffered
- [x] No build tools in final image
- [x] Working directory properly set
- [x] Expose port documented

## Best Practices Applied

✅ **Security**
- Non-root user execution
- Minimal dependencies
- No unnecessary packages

✅ **Performance**
- Multi-stage build
- Layer caching optimization
- Pre-compiled wheels

✅ **Maintainability**
- Clear comments
- Pinned versions
- Metadata labels

✅ **Reliability**
- Health checks
- Proper error handling
- Python best practices

## References

- [Docker Best Practices](https://docs.docker.com/develop/image-bestpractices/)
- [OWASP Container Security](https://owasp.org/www-project-container-security/)
- [Python in Docker](https://docs.docker.com/language/python/)
- [Uvicorn Documentation](https://www.uvicorn.org/)

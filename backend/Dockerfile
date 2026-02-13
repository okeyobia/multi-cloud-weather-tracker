# ============================================================================
# Multi-stage build for production-ready FastAPI application
# Optimized for small size, security, and performance
# ============================================================================

# Stage 1: Builder - Create Python wheels
FROM python:3.11-slim AS builder

WORKDIR /build

# Install only necessary build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Upgrade pip to latest version
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy requirements file
COPY requirements.txt .

# Create wheels for all dependencies (pre-compiled packages)
# This significantly speeds up the final image build
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /build/wheels -r requirements.txt


# Stage 2: Final production image
FROM python:3.11-slim

# Set metadata labels for container registry
LABEL maintainer="Weather Tracker Team"
LABEL description="Production-ready FastAPI weather tracking application"
LABEL version="1.0.0"

# Python environment variables for production
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Create non-root user for security (run app as unprivileged user)
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# Copy wheels and requirements from builder stage
COPY --from=builder /build/wheels /wheels
COPY --from=builder /build/requirements.txt .

# Install Python dependencies from pre-built wheels
# This is much faster than installing from source
RUN pip install --no-cache-dir /wheels/* && \
    rm -rf /wheels /build

# Copy application code
COPY --chown=appuser:appuser . .

# Create directories for logs if needed
RUN mkdir -p /app/logs && chown -R appuser:appuser /app/logs

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8000

# Health check configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run FastAPI application with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

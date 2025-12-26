# Python Base Image
# Multi-stage build for production applications
# Uses slim variant for smaller footprint

ARG PYTHON_VERSION=3.12
ARG DEBIAN_VERSION=bookworm

# =============================================================================
# Builder stage for installing dependencies
# =============================================================================
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libpq-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install build tools
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy and install requirements
COPY requirements*.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# If using poetry
# COPY pyproject.toml poetry.lock ./
# RUN pip install poetry && \
#     poetry config virtualenvs.create false && \
#     poetry install --no-dev --no-interaction --no-ansi

# Copy source code for any build steps
COPY . .

# =============================================================================
# Production stage - minimal image for running the application
# =============================================================================
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS production

# Labels for metadata
LABEL org.opencontainers.image.title="Python Application" \
      org.opencontainers.image.description="Production-ready Python base image" \
      org.opencontainers.image.vendor="Platform Team" \
      org.opencontainers.image.licenses="MIT"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* /var/tmp/*

# Create non-root user
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /bin/false -m appuser && \
    mkdir -p /app/logs /app/tmp && \
    chown -R appuser:appgroup /app

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appgroup . .

# Environment configuration
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose application port
EXPOSE ${PORT}

# Use tini as init process
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default command - override in derived images
# For Flask:
# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "app:app"]
# For FastAPI:
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]

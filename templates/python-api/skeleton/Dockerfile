# syntax=docker/dockerfile:1.7

# ============================================
# Base stage - Python with uv
# ============================================
FROM python:3.12-slim AS base

# Prevent Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Keep Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED=1
# UV settings
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# ============================================
# Dependencies stage
# ============================================
FROM base AS dependencies

# Install dependencies first (for better caching)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-install-project --no-dev

# ============================================
# Build stage
# ============================================
FROM dependencies AS build

# Copy project files
COPY . .

# Install the project
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# ============================================
# Production stage
# ============================================
FROM python:3.12-slim AS production

# Security best practices
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/.venv/bin:$PATH"

# Create non-root user
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy virtual environment from build stage
COPY --from=build --chown=appuser:appgroup /app/.venv /app/.venv
COPY --from=build --chown=appuser:appgroup /app/src /app/src
COPY --from=build --chown=appuser:appgroup /app/alembic /app/alembic
COPY --from=build --chown=appuser:appgroup /app/alembic.ini /app/alembic.ini

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health')" || exit 1

# Run the application
CMD ["uvicorn", "${{ values.name | replace('-', '_') }}.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ============================================
# Development stage
# ============================================
FROM base AS development

# Install all dependencies including dev
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen

COPY . .

# Install project in editable mode
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

EXPOSE 8000

CMD ["uvicorn", "${{ values.name | replace('-', '_') }}.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

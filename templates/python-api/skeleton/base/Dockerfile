FROM python:${{ values.python_version }}-slim AS builder
WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml ./
COPY src ./src
RUN pip install --no-cache-dir .

FROM python:${{ values.python_version }}-slim AS production
WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"
{%- if values.database_type == 'sqlite' %}

# The SQLite file lives in /data, which the unprivileged user owns. Mount a volume
# there to keep the data when the container is replaced.
ENV DATABASE_URL=sqlite+aiosqlite:////data/app.db
RUN mkdir /data && chown 10001:10001 /data
{%- endif %}

COPY --from=builder /opt/venv /opt/venv
{%- if values.migrations %}
COPY alembic.ini ./
COPY migrations ./migrations
{%- endif %}

# Unprivileged user without a login or a home directory
USER 10001:10001

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"]

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"{% if values.enable_logging %}, "--no-access-log"{% endif %}]

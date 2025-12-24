# ${{ values.name }}

${{ values.description }}

## Quick Start

### Prerequisites

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) (recommended) or pip
- Docker (optional)

### Local Development

```bash
# Install uv (if not installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone and setup
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# Install dependencies
uv sync

# Copy environment variables
cp .env.example .env

# Run the API
uv run uvicorn ${{ values.name | replace('-', '_') }}.main:app --reload
```

### Using Docker

```bash
# Development
docker-compose up

# Production build
docker build -t ${{ values.name }}:latest .
docker run -p 8000:8000 ${{ values.name }}:latest
```

## API Documentation

Once running, visit:

- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc
- **OpenAPI JSON**: http://localhost:8000/api/v1/openapi.json

## Development

### Running Tests

```bash
# All tests
uv run pytest

# With coverage
uv run pytest --cov=src --cov-report=html

# Unit tests only
uv run pytest tests/unit/

# Integration tests only
uv run pytest tests/integration/
```

### Code Quality

```bash
# Format code
uv run ruff format .

# Lint code
uv run ruff check .

# Type checking
uv run mypy src/

# Security scan
uv run bandit -r src/
```

{%- if values.database_type in ['postgresql', 'mysql'] %}

### Database Migrations

```bash
# Create migration
uv run alembic revision --autogenerate -m "description"

# Apply migrations
uv run alembic upgrade head

# Rollback
uv run alembic downgrade -1
```

{%- endif %}

## Project Structure

```
src/
├── ${{ values.name | replace('-', '_') }}/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Settings management
│   ├── api/
│   │   └── routes/          # API endpoints
│   ├── core/
│   │   ├── database.py      # Database connection
│   │   └── logging.py       # Structured logging
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   └── repositories/        # Data access layer
tests/
├── unit/                    # Unit tests
├── integration/             # Integration tests
└── conftest.py              # Pytest fixtures
```

## Environment Variables

| Variable      | Description       | Default       |
| ------------- | ----------------- | ------------- |
| `DEBUG`       | Enable debug mode | `false`       |
| `ENVIRONMENT` | Environment name  | `development` |
| `HOST`        | Server host       | `0.0.0.0`     |
| `PORT`        | Server port       | `8000`        |

{%- if values.database_type == 'postgresql' %}
| `DATABASE_HOST` | PostgreSQL host | `localhost` |
| `DATABASE_PORT` | PostgreSQL port | `5432` |
| `DATABASE_USER` | Database user | `postgres` |
| `DATABASE_PASSWORD` | Database password | - |
| `DATABASE_NAME` | Database name | `${{ values.name | replace('-', '_') }}` |
{%- endif %}
{%- if values.auth_type == 'jwt' %}
| `JWT_SECRET_KEY` | JWT signing key | - |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiry | `30` |
{%- endif %}

## Links

- [GitHub Repository](https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }})
- [CI/CD Pipeline](https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/actions)
- [Developer Portal](https://backstage.example.com/catalog/default/component/${{ values.name }})

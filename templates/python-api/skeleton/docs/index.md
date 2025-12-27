# ${{ values.name }}

${{ values.description }}

## Overview

This is a production-ready Python API built with **FastAPI** framework, featuring modern async patterns, comprehensive testing, and enterprise-grade CI/CD pipelines. The service is containerized with Docker and follows Python best practices for code quality, security, and maintainability.

```d2
direction: right

title: {
  label: Python API Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

client: Client {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lb: Load Balancer {
  shape: hexagon
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

api: FastAPI Application {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  middleware: Middleware Layer {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"

    cors: CORS
    auth: Authentication
    rate: Rate Limiting
    metrics: Metrics
  }

  routers: API Routers {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    health: Health
    items: Items
    auth_routes: Auth
  }

  services: Business Logic {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"

    item_svc: Item Service
    auth_svc: Auth Service
  }

  models: Data Layer {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    schemas: Pydantic Schemas
    orm: SQLAlchemy Models
  }

  middleware -> routers
  routers -> services
  services -> models
}

db: Database {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

cache: Redis Cache {
  shape: cylinder
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

client -> lb
lb -> api
api.models -> db
api.services -> cache
```

### Key Features

- **FastAPI Framework**: High-performance async Python web framework
- **Pydantic v2**: Data validation and settings management
- **SQLAlchemy 2.0**: Modern async ORM for database operations
- **Alembic**: Database migration management
- **Structured Logging**: JSON-formatted logs with structlog
- **Prometheus Metrics**: Built-in observability instrumentation
- **Docker Multi-stage Builds**: Optimized container images
- **Comprehensive Testing**: Unit, integration, and end-to-end tests

---

## Configuration Summary

| Setting            | Value                                           |
| ------------------ | ----------------------------------------------- |
| Project Name       | `${{ values.name }}`                            |
| Python Version     | `>= 3.12`                                       |
| Framework          | FastAPI                                         |
| Package Manager    | uv (Astral)                                     |
| Database           | `${{ values.database_type }}`                   |
| Authentication     | `${{ values.auth_type }}`                       |
| Owner              | `${{ values.destination.owner }}`               |
| Repository         | `${{ values.destination.repo }}`                |

---

## Project Structure

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── ci.yaml              # GitHub Actions CI/CD pipeline
├── src/
│   └── ${{ values.name | replace('-', '_') }}/
│       ├── __init__.py
│       ├── main.py              # FastAPI application entry point
│       ├── config.py            # Pydantic settings configuration
│       ├── api/
│       │   ├── __init__.py
│       │   └── routes/
│       │       ├── __init__.py
│       │       ├── health.py    # Health check endpoints
│       │       ├── items.py     # Item CRUD endpoints
│       │       └── auth.py      # Authentication endpoints
│       ├── core/
│       │   ├── __init__.py
│       │   ├── database.py      # Database connection management
│       │   └── logging.py       # Structured logging setup
│       ├── models/
│       │   ├── __init__.py
│       │   └── item.py          # SQLAlchemy ORM models
│       └── schemas/
│           ├── __init__.py
│           ├── item.py          # Pydantic request/response schemas
│           └── auth.py          # Authentication schemas
├── tests/
│   ├── conftest.py              # Pytest fixtures and configuration
│   ├── unit/
│   │   ├── __init__.py
│   │   └── test_schemas.py      # Unit tests for schemas
│   └── integration/
│       ├── __init__.py
│       └── test_api.py          # Integration tests for API
├── alembic/
│   ├── env.py                   # Alembic environment config
│   └── script.py.mako           # Migration script template
├── docs/
│   └── index.md                 # This documentation
├── alembic.ini                  # Alembic configuration
├── pyproject.toml               # Project metadata and dependencies
├── Dockerfile                   # Multi-stage Docker build
├── docker-compose.yaml          # Local development stack
├── mkdocs.yml                   # Documentation site config
├── catalog-info.yaml            # Backstage component metadata
├── .env.example                 # Environment variable template
├── .gitignore                   # Git ignore patterns
└── .dockerignore                # Docker build ignore patterns
```

### Directory Descriptions

| Directory        | Purpose                                                    |
| ---------------- | ---------------------------------------------------------- |
| `src/api/routes` | FastAPI router definitions for each resource               |
| `src/core`       | Core utilities: database, logging, middleware              |
| `src/models`     | SQLAlchemy ORM models for database entities                |
| `src/schemas`    | Pydantic models for request/response validation            |
| `tests/unit`     | Isolated unit tests for individual components              |
| `tests/integration` | API integration tests using TestClient                  |
| `alembic`        | Database migration scripts and configuration               |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Lint & Format**: Ruff for code formatting and linting, mypy for type checking
- **Security Scanning**: Bandit, Safety, and Trivy for vulnerability detection
- **Testing**: Multi-version Python testing with coverage reports
- **Docker Build**: Multi-stage builds with SBOM and provenance attestation
- **Deployment**: Staging and production environments with approvals

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Ruff Format\nRuff Check\nMyPy"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Bandit\nSafety\nTrivy"
}

test: Test {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Unit Tests\nIntegration\nCoverage"
}

build: Build {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Docker Build\nPush to GHCR"
}

staging: Staging {
  shape: diamond
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Deploy\nSmoke Tests"
}

prod: Production {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

pr -> lint
pr -> security
pr -> test
lint -> build
security -> build
test -> build
build -> staging
staging -> prod
```

### Pipeline Jobs

| Job            | Trigger                | Description                                   |
| -------------- | ---------------------- | --------------------------------------------- |
| `lint`         | PR, Push               | Code formatting and linting with Ruff         |
| `security`     | PR, Push               | Security scanning with Bandit, Safety, Trivy  |
| `test`         | PR, Push               | Run tests on Python 3.12 and 3.13             |
| `build`        | After lint/test pass   | Build and push Docker image to GHCR           |
| `deploy-staging` | Push to main         | Deploy to staging environment                 |
| `deploy-production` | Release published | Deploy to production with approval            |

---

## Prerequisites

### 1. Python Environment

Ensure you have the required Python version and package manager:

```bash
# Install Python 3.12 or later
# macOS with Homebrew
brew install python@3.12

# Ubuntu/Debian
sudo apt update && sudo apt install python3.12 python3.12-venv

# Windows with winget
winget install Python.Python.3.12
```

### 2. uv Package Manager

This project uses [uv](https://github.com/astral-sh/uv) for fast, reliable dependency management:

```bash
# Install uv (recommended)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Or with pip
pip install uv

# Or with Homebrew
brew install uv
```

### 3. Docker

Required for containerized development and deployment:

```bash
# macOS
brew install --cask docker

# Ubuntu
sudo apt install docker.io docker-compose-v2

# Verify installation
docker --version
docker compose version
```

### 4. Database Setup (if applicable)

{%- if values.database_type == 'postgresql' %}
```bash
# PostgreSQL via Docker
docker run -d \
  --name postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=${{ values.name | replace('-', '_') }} \
  -p 5432:5432 \
  postgres:16-alpine
```
{%- elif values.database_type == 'mysql' %}
```bash
# MySQL via Docker
docker run -d \
  --name mysql \
  -e MYSQL_ROOT_PASSWORD=mysql \
  -e MYSQL_DATABASE=${{ values.name | replace('-', '_') }} \
  -p 3306:3306 \
  mysql:8
```
{%- elif values.database_type == 'mongodb' %}
```bash
# MongoDB via Docker
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  mongo:7
```
{%- elif values.database_type == 'redis' %}
```bash
# Redis via Docker
docker run -d \
  --name redis \
  -p 6379:6379 \
  redis:7-alpine
```
{%- endif %}

---

## Usage

### Local Development

#### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.name }}

# Create environment file
cp .env.example .env
# Edit .env with your configuration
```

#### 2. Install Dependencies

```bash
# Install all dependencies including dev tools
uv sync

# Or install production dependencies only
uv sync --no-dev
```

#### 3. Run Database Migrations

{%- if values.database_type in ['postgresql', 'mysql'] %}
```bash
# Run migrations
uv run alembic upgrade head

# Create a new migration
uv run alembic revision --autogenerate -m "description"
```
{%- endif %}

#### 4. Start Development Server

```bash
# Run with hot reload
uv run uvicorn ${{ values.name | replace('-', '_') }}.main:app --reload --host 0.0.0.0 --port 8000

# Or use the CLI entry point
uv run ${{ values.name | replace('-', '_') }}
```

### Docker Development

```bash
# Start all services with docker-compose
docker compose up -d

# View logs
docker compose logs -f api

# Stop services
docker compose down
```

### Docker Production Build

```bash
# Build production image
docker build -t ${{ values.name }}:latest --target production .

# Run container
docker run -d \
  --name ${{ values.name }} \
  -p 8000:8000 \
  -e DATABASE_URL="your-database-url" \
  ${{ values.name }}:latest

# Check health
curl http://localhost:8000/health
```

---

## API Documentation

Once the application is running, access the interactive API documentation:

| Documentation | URL                                | Description                    |
| ------------- | ---------------------------------- | ------------------------------ |
| Swagger UI    | http://localhost:8000/api/v1/docs  | Interactive API explorer       |
| ReDoc         | http://localhost:8000/api/v1/redoc | Alternative API documentation  |
| OpenAPI JSON  | http://localhost:8000/api/v1/openapi.json | Raw OpenAPI specification |

### API Endpoints

| Method | Endpoint              | Description                    |
| ------ | --------------------- | ------------------------------ |
| GET    | `/health`             | Liveness probe                 |
| GET    | `/health/ready`       | Readiness probe with DB check  |
| GET    | `/api/v1/items`       | List all items                 |
| POST   | `/api/v1/items`       | Create a new item              |
| GET    | `/api/v1/items/{id}`  | Get item by ID                 |
| PUT    | `/api/v1/items/{id}`  | Update an item                 |
| DELETE | `/api/v1/items/{id}`  | Delete an item                 |
{%- if values.auth_type != 'none' %}
| POST   | `/api/v1/auth/login`  | Authenticate user              |
| POST   | `/api/v1/auth/refresh`| Refresh access token           |
{%- endif %}
{%- if values.enable_metrics %}
| GET    | `/metrics`            | Prometheus metrics endpoint    |
{%- endif %}

---

## Testing Strategy

This project follows a comprehensive testing strategy with multiple test types:

### Test Categories

| Type          | Location              | Purpose                                      |
| ------------- | --------------------- | -------------------------------------------- |
| Unit          | `tests/unit/`         | Test individual functions and classes        |
| Integration   | `tests/integration/`  | Test API endpoints with TestClient           |
| End-to-End    | `tests/e2e/`          | Test full user workflows (if applicable)     |

### Running Tests

```bash
# Run all tests
uv run pytest

# Run with coverage
uv run pytest --cov=src --cov-report=html

# Run only unit tests
uv run pytest tests/unit/ -v

# Run only integration tests
uv run pytest tests/integration/ -v

# Run tests in parallel
uv run pytest -n auto

# Run tests with specific markers
uv run pytest -m "unit"
uv run pytest -m "integration"
uv run pytest -m "not slow"
```

### Coverage Requirements

The project enforces a minimum of **80% code coverage**. Coverage reports are generated in multiple formats:

- **HTML Report**: `htmlcov/index.html`
- **XML Report**: `coverage.xml` (for CI integration)
- **Terminal**: Summary displayed after test run

### Writing Tests

```python
# tests/unit/test_example.py
import pytest
from ${{ values.name | replace('-', '_') }}.schemas.item import ItemCreate

class TestItemSchema:
    def test_item_create_valid(self):
        item = ItemCreate(name="Test Item", price=9.99)
        assert item.name == "Test Item"
        assert item.price == 9.99

    def test_item_create_invalid_price(self):
        with pytest.raises(ValueError):
            ItemCreate(name="Test", price=-1.0)
```

```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}
```

---

## Security Features

### Code Security

| Tool       | Purpose                                      | Configuration        |
| ---------- | -------------------------------------------- | -------------------- |
| **Bandit** | Static security analysis for Python          | `pyproject.toml`     |
| **Safety** | Dependency vulnerability scanning            | CI pipeline          |
| **Trivy**  | Container and filesystem vulnerability scan  | CI pipeline          |
| **Ruff**   | Security-focused linting rules (S rules)     | `pyproject.toml`     |

### Runtime Security

{%- if values.auth_type == 'jwt' %}
- **JWT Authentication**: Secure token-based authentication with configurable expiration
- **Password Hashing**: bcrypt-based password hashing with passlib
{%- elif values.auth_type == 'oauth2' %}
- **OAuth2/OIDC**: Integration with external identity providers
- **Token Validation**: Automatic token validation and refresh
{%- elif values.auth_type == 'api-key' %}
- **API Key Authentication**: Header-based API key validation
{%- endif %}
{%- if values.enable_rate_limiting %}
- **Rate Limiting**: Protection against abuse with SlowAPI (default: 100 req/min)
{%- endif %}
{%- if values.enable_cors %}
- **CORS Protection**: Configurable cross-origin resource sharing
{%- endif %}

### Docker Security

- **Non-root User**: Application runs as unprivileged `appuser`
- **Multi-stage Builds**: Minimal production image without build tools
- **Health Checks**: Built-in container health monitoring
- **SBOM Generation**: Software Bill of Materials for supply chain security

### Security Scanning in CI

```yaml
# Security scan results are uploaded to GitHub Security tab
- Bandit SARIF: Static analysis findings
- Trivy SARIF: Vulnerability scan results
```

---

## Environment Variables

| Variable                | Required | Default          | Description                        |
| ----------------------- | -------- | ---------------- | ---------------------------------- |
| `DEBUG`                 | No       | `false`          | Enable debug mode                  |
| `ENVIRONMENT`           | No       | `development`    | Environment name                   |
| `HOST`                  | No       | `0.0.0.0`        | Server bind address                |
| `PORT`                  | No       | `8000`           | Server port                        |
| `API_V1_PREFIX`         | No       | `/api/v1`        | API version prefix                 |
| `OPENAPI_ENABLED`       | No       | `true`           | Enable OpenAPI documentation       |
{%- if values.database_type in ['postgresql', 'mysql'] %}
| `DATABASE_HOST`         | Yes      | `localhost`      | Database host                      |
| `DATABASE_PORT`         | Yes      | `5432`/`3306`    | Database port                      |
| `DATABASE_USER`         | Yes      | -                | Database username                  |
| `DATABASE_PASSWORD`     | Yes      | -                | Database password                  |
| `DATABASE_NAME`         | Yes      | -                | Database name                      |
{%- elif values.database_type == 'mongodb' %}
| `MONGODB_URL`           | Yes      | -                | MongoDB connection URL             |
| `MONGODB_DATABASE`      | Yes      | -                | MongoDB database name              |
{%- endif %}
{%- if values.enable_caching or values.database_type == 'redis' %}
| `REDIS_HOST`            | No       | `localhost`      | Redis host                         |
| `REDIS_PORT`            | No       | `6379`           | Redis port                         |
| `REDIS_PASSWORD`        | No       | -                | Redis password                     |
{%- endif %}
{%- if values.auth_type == 'jwt' %}
| `JWT_SECRET_KEY`        | Yes      | -                | JWT signing secret (change in prod)|
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | No | `30`        | Access token TTL in minutes        |
{%- endif %}
{%- if values.enable_logging %}
| `LOG_LEVEL`             | No       | `INFO`           | Logging level                      |
| `LOG_FORMAT`            | No       | `json`           | Log format (json/console)          |
{%- endif %}

---

## Troubleshooting

### Application Issues

**Error: ModuleNotFoundError**

```
ModuleNotFoundError: No module named '${{ values.name | replace('-', '_') }}'
```

**Resolution:**
```bash
# Ensure dependencies are installed
uv sync

# Or reinstall the project
uv pip install -e .
```

---

**Error: Database connection failed**

```
sqlalchemy.exc.OperationalError: could not connect to server
```

**Resolution:**
1. Verify database is running: `docker ps | grep postgres`
2. Check connection settings in `.env`
3. Ensure database exists: `docker exec -it postgres psql -U postgres -l`
4. Test connection manually:
   ```bash
   uv run python -c "from ${{ values.name | replace('-', '_') }}.core.database import check_db_connection; import asyncio; print(asyncio.run(check_db_connection()))"
   ```

---

**Error: Port already in use**

```
OSError: [Errno 48] Address already in use
```

**Resolution:**
```bash
# Find process using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use a different port
uv run uvicorn ${{ values.name | replace('-', '_') }}.main:app --port 8001
```

---

### CI/CD Issues

**Pipeline failing on lint**

```bash
# Fix formatting locally
uv run ruff format .

# Fix linting issues
uv run ruff check --fix .
```

---

**Docker build failing**

```bash
# Build with verbose output
docker build --progress=plain -t ${{ values.name }}:debug .

# Check for missing files in .dockerignore
cat .dockerignore
```

---

**Tests failing in CI but passing locally**

1. Ensure you're using the same Python version as CI (3.12)
2. Check for environment-specific configuration
3. Run tests in isolation: `uv run pytest --forked`

---

### Dependency Issues

**Lock file out of sync**

```bash
# Regenerate lock file
uv lock

# Update all dependencies
uv lock --upgrade
```

---

## Related Templates

| Template                                                    | Description                          |
| ----------------------------------------------------------- | ------------------------------------ |
| [python-library](/docs/default/template/python-library)     | Python library package template      |
| [python-cli](/docs/default/template/python-cli)             | Python CLI application template      |
| [fastapi-ml](/docs/default/template/fastapi-ml)             | FastAPI with ML model serving        |
| [aws-ecs-service](/docs/default/template/aws-ecs-service)   | AWS ECS deployment for Python APIs   |
| [aws-lambda-python](/docs/default/template/aws-lambda-python) | AWS Lambda function with Python    |
| [k8s-deployment](/docs/default/template/k8s-deployment)     | Kubernetes deployment manifests      |

---

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic v2 Documentation](https://docs.pydantic.dev/latest/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [uv Package Manager](https://github.com/astral-sh/uv)
- [Ruff Linter](https://docs.astral.sh/ruff/)
- [pytest Documentation](https://docs.pytest.org/)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Backstage Software Catalog](https://backstage.io/docs/features/software-catalog/)

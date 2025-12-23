# Python API Service Template

This template creates a production-ready Python API with FastAPI, authentication, monitoring, and comprehensive testing.

## Overview

Build high-performance Python APIs with modern async support, automatic documentation, and enterprise-ready features out of the box.

## Features

### Framework Options
- **FastAPI** (Recommended) - Modern, fast, async-first
- **Flask + Flask-RESTful** - Lightweight and flexible
- **Django REST Framework** - Full-featured with admin
- **Starlette** - Minimal ASGI framework

### API Types
- REST CRUD API
- REST Microservice
- GraphQL API
- WebSocket Service
- Async Task Processor

### Database Support
| Database | ORM/ODM |
|----------|---------|
| PostgreSQL | SQLAlchemy |
| MySQL | SQLAlchemy, Tortoise ORM |
| MongoDB | MongoEngine |
| Redis | Redis OM |
| SQLite | SQLAlchemy, Peewee |

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `python_version` | Python version | 3.11 |
| `framework` | Web framework | fastapi |
| `database_type` | Database | postgresql |
| `auth_type` | Authentication | jwt |
| `enable_async` | Async support | true |

## Getting Started

### Prerequisites
- Python 3.9+
- pip or Poetry
- Docker (optional)

### Local Development

1. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # or
   .\venv\Scripts\activate  # Windows
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   # or with Poetry
   poetry install
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Run database migrations**
   ```bash
   alembic upgrade head
   ```

5. **Start the server**
   ```bash
   uvicorn app.main:app --reload
   ```

### API Documentation

FastAPI automatically generates interactive documentation:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## Project Structure

```
├── app/
│   ├── __init__.py
│   ├── main.py              # Application entry point
│   ├── config.py            # Configuration settings
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/          # API route handlers
│   │   └── dependencies.py  # Dependency injection
│   ├── core/
│   │   ├── security.py      # Authentication/authorization
│   │   └── logging.py       # Structured logging
│   ├── models/              # Database models
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   └── repositories/        # Data access layer
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── alembic/                 # Database migrations
├── Dockerfile
├── docker-compose.yaml
└── requirements.txt
```

## Authentication

### JWT Authentication
```python
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    user = decode_token(token)
    if not user:
        raise HTTPException(status_code=401)
    return user
```

### Supported Auth Methods
- JWT Tokens
- OAuth2 / OpenID Connect
- API Key Authentication
- Basic Authentication
- LDAP Authentication

## Database Migrations

Using Alembic for database migrations:

```bash
# Create a new migration
alembic revision --autogenerate -m "Add users table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Testing

### Run Tests
```bash
# Run all tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Run specific tests
pytest tests/unit/
pytest tests/integration/
```

### Test Configuration
```python
# conftest.py
import pytest
from httpx import AsyncClient

@pytest.fixture
async def client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
```

## Code Quality

### Linting and Formatting
```bash
# Format code
black app/ tests/
isort app/ tests/

# Lint
flake8 app/ tests/

# Type checking
mypy app/
```

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/psf/black
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    hooks:
      - id: isort
  - repo: https://github.com/pycqa/flake8
    hooks:
      - id: flake8
```

## Docker Deployment

### Build and Run
```bash
# Build image
docker build -t my-api:latest .

# Run container
docker run -p 8000:8000 my-api:latest

# With docker-compose
docker-compose up -d
```

### Multi-stage Dockerfile
```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

## Monitoring

### Health Checks
```python
@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/health/ready")
async def readiness():
    # Check database connection
    # Check external dependencies
    return {"status": "ready"}
```

### Prometheus Metrics
```python
from prometheus_fastapi_instrumentator import Instrumentator

Instrumentator().instrument(app).expose(app)
```

## Related Templates

- [Kubernetes Microservice](../kubernetes-microservice) - Deploy to Kubernetes
- [Docker Application](../docker-application) - Containerization template
- [React Frontend](../react-frontend) - Frontend for your API

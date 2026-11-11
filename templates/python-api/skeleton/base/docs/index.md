{%- set password_auth = values.auth_type in ['jwt', 'basic-auth'] -%}
{%- set server_db = values.database_type in ['postgresql', 'mysql'] -%}
{%- set has_secrets = server_db or values.auth_type != 'none' -%}
{%- set db_names = {'postgresql': 'PostgreSQL', 'mysql': 'MySQL', 'sqlite': 'SQLite'} -%}
{%- set auth_names = {'jwt': 'JWT bearer tokens', 'api-key': 'API key header', 'basic-auth': 'HTTP Basic'} -%}
# ${{ values.name }}

${{ values.description }}

## Overview

| Setting        | Value |
| -------------- | ----- |
| Service        | `${{ values.name }}` |
| Owner          | `${{ values.owner }}` |
| Framework      | FastAPI, Python ${{ values.python_version }} (see `.python-version`) |
| Port           | `8000` |
| Storage        | {% if values.sql %}${{ db_names[values.database_type] }} through SQLAlchemy 2 (async){% if values.migrations %}, Alembic migrations{% endif %}{% else %}In memory{% endif %} |
{%- if values.enable_caching %}
| Cache          | Redis when `REDIS_URL` is set, otherwise in memory |
{%- endif %}
| Authentication | {% if values.auth_type != 'none' %}${{ auth_names[values.auth_type] }}{% else %}None{% endif %} |
| Repository     | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

client: Client {
  shape: oval
}

service: ${{ values.name }} {
  health: "/health\n/health/ready"
  items: "/api/v1/items"
{%- if values.auth_type == 'jwt' %}
  auth: "/api/v1/auth/token"
{%- endif %}
  repository: "ItemRepository"
  items -> repository
}
{%- if values.sql %}

database: ${{ db_names[values.database_type] }} {
  shape: cylinder
}
{%- endif %}
{%- if values.enable_caching %}

cache: Redis {
  shape: cylinder
}
{%- endif %}

client -> service.items: HTTP 8000
client -> service.health
{%- if values.auth_type == 'jwt' %}
client -> service.auth: user name, password
{%- endif %}
{%- if values.sql %}
service.repository -> database
service.health -> database: ready
{%- endif %}
{%- if values.enable_caching %}
service.repository -> cache: item reads
{%- endif %}
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
│   ├── ci.yaml               # Tests, image build and smoke test, dependency scan
{%- if values.enable_linting %}
│   ├── lint.yaml             # Ruff lint and format check
{%- endif %}
{%- if values.enable_type_checking %}
│   ├── typecheck.yaml        # mypy in strict mode
{%- endif %}
{%- if values.containerization == 'docker-compose' %}
│   └── compose.yaml          # Starts the Compose stack and calls the API
{%- elif values.containerization == 'kubernetes' %}
│   └── kubernetes.yaml       # Validates the manifests in k8s/
{%- endif %}
├── docs/index.md             # This page
{%- if values.containerization == 'kubernetes' %}
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
{%- endif %}
{%- if values.migrations %}
├── migrations/
│   ├── env.py                # Alembic environment (async engine)
│   └── versions/             # One file per migration
├── alembic.ini
{%- endif %}
{%- if values.containerization == 'docker-compose' %}
├── scripts/smoke.sh          # Creates, reads and deletes an item on a running service
{%- endif %}
├── src/app/
│   ├── main.py               # create_app() and the ASGI application
│   ├── config.py             # Settings read from the environment
│   ├── dependencies.py       # Dependencies shared by the routes
│   ├── schemas.py            # Request and response models
│   ├── repository.py         # ItemRepository interface
{%- if values.sql %}
│   ├── db.py                 # SQLAlchemy model, connection pool, SQL repository
{%- else %}
│   ├── memory.py             # In-memory repository
{%- endif %}
{%- if values.sql and not values.migrations %}
│   ├── init_db.py            # python -m app.init_db creates the tables
{%- endif %}
{%- if values.enable_caching %}
│   ├── cache.py              # Cache interface, Redis and in-memory caches, cached repository
{%- endif %}
{%- if values.auth_type != 'none' %}
│   ├── security.py           # ${{ auth_names[values.auth_type] }}
{%- endif %}
{%- if values.enable_rate_limiting %}
│   ├── rate_limit.py         # Rate limiting middleware
{%- endif %}
{%- if values.enable_security_headers %}
│   ├── security_headers.py   # Security headers middleware
{%- endif %}
{%- if values.enable_logging %}
│   ├── log.py                # JSON logging and request logging middleware
{%- endif %}
{%- if values.enable_metrics %}
│   ├── metrics.py            # Prometheus metrics
{%- endif %}
│   └── api/
{%- if values.auth_type == 'jwt' %}
│       ├── auth.py           # /api/v1/auth/token
{%- endif %}
│       ├── health.py         # /health, /health/ready
│       └── items.py          # /api/v1/items
├── tests/                    # pytest tests of every module
├── .env.example
├── .python-version
├── Dockerfile
{%- if values.containerization == 'docker-compose' %}
├── docker-compose.yaml
{%- endif %}
├── catalog-info.yaml
├── mkdocs.yml
└── pyproject.toml            # Dependencies and tool configuration
```

## Running locally

```bash
python${{ values.python_version }} -m venv .venv
. .venv/bin/activate
pip install -e '.[dev]'
{%- if values.migrations %}
alembic upgrade head
{%- elif values.sql %}
python -m app.init_db
{%- endif %}
uvicorn app.main:app --reload
```
{%- if values.containerization == 'docker-compose' %}

`docker compose up --build --wait` builds the image and starts the service
{%- if server_db %}, ${{ db_names[values.database_type] }}{% endif %}
{%- if values.enable_caching %} and Redis{% endif %}
{%- if values.migrations %}; the service container applies the migrations before it starts{% elif values.sql %}; the service container creates missing tables before it starts{% endif %}.
`bash scripts/smoke.sh` then creates, reads and deletes an item through the API.
{%- endif %}

## Endpoints

| Method | Path                 | Description                                   |
| ------ | -------------------- | --------------------------------------------- |
| GET    | `/health`            | Liveness: the process is running              |
| GET    | `/health/ready`      | Readiness: {% if values.sql or values.enable_caching %}checks {% if values.sql %}the database{% endif %}{% if values.sql and values.enable_caching %} and {% endif %}{% if values.enable_caching %}the cache{% endif %}, 503 on failure{% else %}no dependencies to check{% endif %} |
{%- if values.auth_type == 'jwt' %}
| POST   | `/api/v1/auth/token` | Exchange user name and password for a token   |
{%- endif %}
| GET    | `/api/v1/items`      | List items (`skip`, `limit`)                  |
| POST   | `/api/v1/items`      | Create an item                                |
| GET    | `/api/v1/items/{id}` | Read an item                                  |
| PUT    | `/api/v1/items/{id}` | Replace an item                               |
| DELETE | `/api/v1/items/{id}` | Delete an item                                |
{%- if values.enable_metrics %}
| GET    | `/metrics`           | Prometheus metrics                            |
{%- endif %}
{%- if values.enable_docs %}
| GET    | `/docs`, `/redoc`    | Swagger UI and ReDoc                          |
| GET    | `/openapi.json`      | OpenAPI document                              |
{%- endif %}
{%- if values.auth_type == 'jwt' %}

## Authentication

The items routes require a bearer token. `POST /api/v1/auth/token` issues one for the
user configured with `AUTH_USERNAME` and `AUTH_PASSWORD`; it is signed with `JWT_SECRET`
(HS256) and expires after `JWT_EXPIRE_MINUTES`.

```bash
token="$(curl -s -d 'username=admin' -d 'password=change-me' \
  http://localhost:8000/api/v1/auth/token | python3 -c 'import json, sys; print(json.load(sys.stdin)["access_token"])')"
curl -H "Authorization: Bearer $token" http://localhost:8000/api/v1/items
```
{%- elif values.auth_type == 'api-key' %}

## Authentication

The items routes require one of the keys listed in `API_KEYS` in the `X-API-Key` header.

```bash
curl -H 'X-API-Key: dev-api-key' http://localhost:8000/api/v1/items
```
{%- elif values.auth_type == 'basic-auth' %}

## Authentication

The items routes require HTTP Basic credentials of the user configured with
`AUTH_USERNAME` and `AUTH_PASSWORD`.

```bash
curl -u admin:change-me http://localhost:8000/api/v1/items
```
{%- endif %}
{%- if values.sql %}

## Database

Items are stored in ${{ db_names[values.database_type] }} through SQLAlchemy 2 (async). The service connects on the first
query, so it starts without a reachable database; `/health/ready` reports whether the
database answers.
{%- if values.migrations %}

The schema is managed with Alembic migrations in `migrations/versions/`:

```bash
alembic upgrade head                              # apply all migrations
alembic revision --autogenerate -m "add a column" # create one after changing app/db.py
alembic downgrade -1                              # undo the last one
```
{%- else %}

`python -m app.init_db` creates the tables that do not exist yet. It does not change
existing tables.
{%- endif %}

The tests run on an in-memory SQLite database and need no database server.
{%- else %}

## Storage

Items are kept in the memory of the process (`app/memory.py`): they are lost when the
process stops and are not shared between processes. Implement the `ItemRepository`
interface in `app/repository.py` to store them elsewhere.
{%- endif %}
{%- if values.enable_caching %}

## Cache

Single items are read cache-aside (`CachedItemRepository` in `app/cache.py`): a read asks
the cache first and stores the item on a miss for `CACHE_TTL_SECONDS`; replacing or
deleting an item removes its entry. Lists are not cached. With `REDIS_URL` the cache is
Redis and `/health/ready` checks that it answers; without it each process caches in its
own memory.
{%- endif %}

## Configuration

Settings are environment variables, read by `src/app/config.py`. Copy `.env.example` to
`.env` to change them locally.

| Variable             | Default                      | Purpose                                             |
| -------------------- | ---------------------------- | --------------------------------------------------- |
| `APP_ENV`            | `development`                | `development`, `staging` or `production`            |
{%- if values.enable_logging %}
| `LOG_LEVEL`          | `INFO`                       | Lowest level that is logged                         |
{%- endif %}
{%- if values.database_type == 'postgresql' %}
| `DATABASE_URL`       | `postgresql+asyncpg://app:app@localhost:5432/app` | SQLAlchemy URL of the database |
{%- elif values.database_type == 'mysql' %}
| `DATABASE_URL`       | `mysql+aiomysql://app:app@localhost:3306/app` | SQLAlchemy URL of the database     |
{%- elif values.database_type == 'sqlite' %}
| `DATABASE_URL`       | `sqlite+aiosqlite:///./app.db` (`/data/app.db` in the image) | SQLAlchemy URL of the database |
{%- endif %}
{%- if values.enable_caching %}
| `REDIS_URL`          | not set                      | Redis used as cache; unset means an in-memory cache |
| `CACHE_TTL_SECONDS`  | `60`                         | How long a cached item is served                    |
{%- endif %}
{%- if password_auth %}
| `AUTH_USERNAME`      | `admin`                      | User allowed to call the items API                  |
| `AUTH_PASSWORD`      | `change-me`                  | Password of that user                               |
{%- endif %}
{%- if values.auth_type == 'jwt' %}
| `JWT_SECRET`         | a development value          | Key that signs the tokens (HS256)                   |
| `JWT_EXPIRE_MINUTES` | `30`                         | Lifetime of a token                                 |
{%- endif %}
{%- if values.auth_type == 'api-key' %}
| `API_KEYS`           | `["dev-api-key"]`            | JSON list of accepted keys                          |
{%- endif %}
{%- if values.enable_rate_limiting %}
| `RATE_LIMIT`         | `100/minute`                 | Requests allowed per client address                 |
{%- endif %}
{%- if values.enable_cors %}
| `CORS_ORIGINS`       | `["http://localhost:3000"]`  | JSON list of allowed browser origins                |
{%- endif %}
{%- if has_secrets %}

With `APP_ENV=production` the service refuses to start while a setting marked in
`DEVELOPMENT_ONLY_DEFAULTS` (`src/app/config.py`) still has its development default.
{%- endif %}
{%- if values.enable_rate_limiting or values.enable_cors or values.enable_security_headers or values.enable_logging or values.enable_metrics %}

## Middleware
{% if values.enable_rate_limiting %}
- **Rate limiting**: every client address may send `RATE_LIMIT` requests; further requests
  get 429 with a `Retry-After` header. `/health` and `/health/ready` are exempt. Counters
  are kept per process.
{%- endif %}
{%- if values.enable_cors %}
- **CORS**: browsers on an origin listed in `CORS_ORIGINS` may call the API.
{%- endif %}
{%- if values.enable_security_headers %}
- **Security headers**: every response carries `X-Content-Type-Options`, `X-Frame-Options`,
  `Referrer-Policy`, `Cross-Origin-Opener-Policy`, `Cross-Origin-Resource-Policy`,
  `Permissions-Policy` and `Strict-Transport-Security`.
{%- endif %}
{%- if values.enable_logging %}
- **Logging**: every request is logged as one JSON object (method, path, status code,
  duration) with structlog. `structlog.get_logger()` logs in the same format.
{%- endif %}
{%- if values.enable_metrics %}
- **Metrics**: `/metrics` serves request counts and durations in the Prometheus format.
{%- endif %}
{%- endif %}

## Container image

The `Dockerfile` builds a `python:${{ values.python_version }}-slim` image that runs as an unprivileged user and
listens on port 8000. The container starts without configuration
{%- if values.sql %}; run `{% if values.migrations %}alembic upgrade head{% else %}python -m app.init_db{% endif %}` in it once the database is reachable{% endif %}.
{%- if values.database_type == 'sqlite' %}
In the image the SQLite file is `/data/app.db`; mount a volume on `/data` to keep it.
{%- endif %}
{%- if values.containerization == 'kubernetes' %}

## Kubernetes

`k8s/deployment.yaml` and `k8s/service.yaml` run the image
`ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest` with `APP_ENV=production`,
a liveness probe on `/health` and a readiness probe on `/health/ready`
{%- if values.sql %}. An init container runs `{% if values.migrations %}alembic upgrade head{% else %}python -m app.init_db{% endif %}` before the server starts{% endif %}.
{%- if has_secrets or values.enable_caching %}

The pods read their settings from the Secret `${{ values.name }}-env`{% if not has_secrets %}, which is optional{% endif %}. Create it with
the variables of the table above{% if has_secrets %}; every secret must differ from its development default{% endif %}:

```bash
kubectl create secret generic ${{ values.name }}-env \
{%- if values.database_type == 'postgresql' %}
  --from-literal=DATABASE_URL='postgresql+asyncpg://USER:PASSWORD@HOST:5432/DATABASE' \
{%- elif values.database_type == 'mysql' %}
  --from-literal=DATABASE_URL='mysql+aiomysql://USER:PASSWORD@HOST:3306/DATABASE' \
{%- endif %}
{%- if password_auth %}
  --from-literal=AUTH_PASSWORD='...' \
{%- endif %}
{%- if values.auth_type == 'jwt' %}
  --from-literal=JWT_SECRET='...' \
{%- endif %}
{%- if values.auth_type == 'api-key' %}
  --from-literal=API_KEYS='["..."]' \
{%- endif %}
{%- if values.enable_caching %}
  --from-literal=REDIS_URL='redis://HOST:6379/0' \
{%- endif %}
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f k8s/
```
{%- else %}

```bash
kubectl apply -f k8s/
```
{%- endif %}

The image is private while the repository is private: give the cluster an image pull
secret for `ghcr.io` or make the package public.
{%- endif %}

## Pipeline

Every push and pull request to `main` runs these workflows; none needs a secret or a
variable.

| Workflow | What it does |
| -------- | ------------ |
| `ci.yaml` | Installs the project on the Python version of `.python-version`, runs `pytest`{% if values.enable_coverage %} with a 90 percent coverage threshold{% endif %} and starts the server; lints the `Dockerfile` with Hadolint, builds the image, starts the container and calls `/health`, reports image vulnerabilities with Trivy and, on a push, publishes the image to `ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}`; reports vulnerable dependencies with Trivy |
{%- if values.enable_linting %}
| `lint.yaml` | `ruff check .` and `ruff format --check .` |
{%- endif %}
{%- if values.enable_type_checking %}
| `typecheck.yaml` | `mypy` in strict mode on sources and tests |
{%- endif %}
{%- if values.containerization == 'docker-compose' %}
| `compose.yaml` | `docker compose up --build --wait`, calls `/health/ready` and runs `scripts/smoke.sh` |
{%- elif values.containerization == 'kubernetes' %}
| `kubernetes.yaml` | Validates `k8s/` with kubeconform |
{%- endif %}

The Trivy reports list findings without failing the build, because the advisory database
changes daily.

## Owner

${{ values.owner }}

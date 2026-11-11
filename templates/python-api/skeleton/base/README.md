{%- set password_auth = values.auth_type in ['jwt', 'basic-auth'] -%}
{%- set server_db = values.database_type in ['postgresql', 'mysql'] -%}
{%- set has_secrets = server_db or values.auth_type != 'none' -%}
{%- set db_names = {'postgresql': 'PostgreSQL', 'mysql': 'MySQL', 'sqlite': 'SQLite'} -%}
{%- set auth_names = {'jwt': 'JWT bearer tokens', 'api-key': 'API key header', 'basic-auth': 'HTTP Basic'} -%}
# ${{ values.name }}

${{ values.description }}

FastAPI service on Python ${{ values.python_version }} with an `items` sample resource
{%- if values.sql %} stored in ${{ db_names[values.database_type] }}{% else %} kept in memory{% endif %}
{%- if values.auth_type != 'none' %}, protected by ${{ auth_names[values.auth_type] }}{% endif %}.

## Getting started

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

The API listens on <http://localhost:8000>.
{%- if values.enable_docs %} Swagger UI is on <http://localhost:8000/docs>.{% endif %}
{%- if values.database_type in ['postgresql', 'mysql'] %}

The default `DATABASE_URL` expects ${{ db_names[values.database_type] }} on localhost with user, password and database `app`.
{%- if values.containerization == 'docker-compose' %} `docker compose up --build --wait` starts the whole stack instead.{% endif %}
{%- elif values.containerization == 'docker-compose' %}

`docker compose up --build --wait` runs the service in a container instead.
{%- endif %}

## Commands

- `pytest` runs the tests{% if values.enable_coverage %} with coverage and fails below 90 percent{% endif %}
{%- if values.enable_linting %}
- `ruff check .` lints the code (`ruff check --fix .` fixes what it can)
- `ruff format --check .` checks the formatting (`ruff format .` applies it)
{%- endif %}
{%- if values.enable_type_checking %}
- `mypy` type-checks sources and tests in strict mode
{%- endif %}
{%- if values.migrations %}
- `alembic upgrade head` applies the database migrations
{%- elif values.sql %}
- `python -m app.init_db` creates missing database tables
{%- endif %}
- `docker build -t ${{ values.name }} .` builds the container image
{%- if values.containerization == 'docker-compose' %}
- `bash scripts/smoke.sh` creates, reads and deletes an item on a running service
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

With `APP_ENV=production` the service refuses to start while
{%- if server_db %} `DATABASE_URL`,{% endif %}
{%- if password_auth %} `AUTH_PASSWORD`,{% endif %}
{%- if values.auth_type == 'jwt' %} `JWT_SECRET`,{% endif %}
{%- if values.auth_type == 'api-key' %} `API_KEYS`,{% endif %} still
{%- if (1 if server_db else 0) + (1 if password_auth else 0) + (1 if values.auth_type in ['jwt', 'api-key'] else 0) > 1 %} have their development defaults{% else %} has its development default{% endif %}.
{%- endif %}

More in [docs/index.md](docs/index.md).

## Owner

${{ values.owner }}

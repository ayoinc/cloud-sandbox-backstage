# Python API Service Template

Creates a repository with a FastAPI service, its tests, a container image and GitHub
Actions workflows that pass on the first push without any secret or variable.

## What every repository gets

- A FastAPI application in `src/app/` (import name `app`, started with `uvicorn app.main:app`)
  with a sample `items` resource under `/api/v1/items`, a liveness endpoint `/health`
  and a readiness endpoint `/health/ready`
- Settings read from environment variables (`src/app/config.py`, `.env.example`). The
  service starts without any; with `APP_ENV=production` it refuses development secrets
- `pyproject.toml` (hatchling) with runtime dependencies bounded by major version, and
  pytest tests of every generated module
- A multi-stage `Dockerfile` (`python:<version>-slim`, unprivileged user, health check)
- `.github/workflows/ci.yaml`: tests, Hadolint, image build, container smoke test on
  `/health`, Trivy reports, image publication to `ghcr.io` on push
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` describing what was generated

## Form

| Parameter                 | Values                                   | Effect on the repository                                                                                                                                                                                                                   |
| ------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `name`                    | lowercase letters, numbers, hyphens      | Repository, catalog entity, package and image name                                                                                                                                                                                         |
| `description`             | text                                     | Description in the catalog, `pyproject.toml` and the docs                                                                                                                                                                                  |
| `owner`                   | group or user                            | `spec.owner` of the catalog entity                                                                                                                                                                                                         |
| `repoUrl`                 | github.com repository                    | Where the repository is published                                                                                                                                                                                                          |
| `python_version`          | `3.11`, `3.12`, `3.13`                   | `.python-version` (read by the workflows), base image, `requires-python`, Ruff and mypy target                                                                                                                                             |
| `database_type`           | `none`, `postgresql`, `mysql`, `sqlite`  | `none` keeps items in memory; the others store them through SQLAlchemy 2 (async) with asyncpg, aiomysql or aiosqlite                                                                                                                       |
| `enable_migrations`       | on/off, shown for a SQL database         | On: Alembic with an initial migration and tests of upgrade and downgrade. Off: `python -m app.init_db` creates the tables                                                                                                                  |
| `enable_caching`          | on/off                                   | Cache-aside reads of items in Redis when `REDIS_URL` is set, otherwise in memory                                                                                                                                                           |
| `auth_type`               | `none`, `jwt`, `api-key`, `basic-auth`   | Protection of the items routes: bearer tokens issued by `POST /api/v1/auth/token`, an `X-API-Key` header, or HTTP Basic                                                                                                                    |
| `enable_rate_limiting`    | on/off                                   | Middleware limiting requests per client address (`RATE_LIMIT`), built on the `limits` library                                                                                                                                              |
| `enable_cors`             | on/off                                   | CORS middleware for the origins in `CORS_ORIGINS`                                                                                                                                                                                          |
| `enable_security_headers` | on/off                                   | Middleware adding security headers to every response                                                                                                                                                                                       |
| `enable_docs`             | on/off                                   | Swagger UI, ReDoc and `/openapi.json` served or not                                                                                                                                                                                        |
| `enable_logging`          | on/off                                   | structlog JSON logging and a request logging middleware                                                                                                                                                                                    |
| `enable_metrics`          | on/off                                   | Prometheus metrics on `/metrics`                                                                                                                                                                                                           |
| `enable_coverage`         | on/off                                   | pytest-cov in the test run, failing below 90 percent                                                                                                                                                                                       |
| `enable_linting`          | on/off                                   | Ruff configuration and `.github/workflows/lint.yaml`                                                                                                                                                                                       |
| `enable_type_checking`    | on/off                                   | mypy strict configuration and `.github/workflows/typecheck.yaml`                                                                                                                                                                           |
| `containerization`        | `docker`, `docker-compose`, `kubernetes` | `docker-compose` adds `docker-compose.yaml` with the database and Redis the options need, `scripts/smoke.sh` and a workflow that starts the stack and calls the API; `kubernetes` adds `k8s/` manifests and a workflow that validates them |

Every option adds its own tests, so the test workflow covers what was selected.

## Steps

1. Render `skeleton/base/` and the `skeleton/<variant>/` directories the options select
2. Publish the result as a private GitHub repository with `main` as default branch
3. Register `catalog-info.yaml` in the catalog

## After creation

The first push starts the workflows; the links of the task page open the repository,
the catalog entity and the workflow runs. The generated `README.md` and `docs/index.md`
list the commands, endpoints and settings of the service.

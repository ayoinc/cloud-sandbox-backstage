# ${{ values.name }}

${{ values.description }}

Rust HTTP service built with axum and tokio{% if values.database == 'postgres' %}, storing its data in PostgreSQL through sqlx{% endif %}.

## Getting started

Requires Rust 1.99 (rustup installs it from `rust-toolchain.toml`){% if values.database == 'postgres' %} and Docker for the local database{% endif %}.

```bash
{%- if values.database == 'postgres' %}
docker compose up -d --wait
cp .env.example .env && set -a && . ./.env && set +a
cargo run -- migrate
{%- endif %}
cargo run
curl http://localhost:${{ values.port }}/health
```

## Commands

- `cargo run` starts the service
{%- if values.database == 'postgres' %}
- `cargo run -- migrate` applies the migrations in `migrations/` and exits
{%- endif %}
- `cargo test` runs the tests{% if values.database == 'postgres' %} (the database tests need `DATABASE_URL`){% endif %}
- `cargo fmt --all` formats the code
- `cargo clippy --all-targets -- -D warnings` lints it
- `cargo deny check` checks advisories, licences and sources ([cargo-deny](https://embarkstudios.github.io/cargo-deny/))

## Endpoints

| Method | Path              | Description                              |
| ------ | ----------------- | ---------------------------------------- |
| GET    | `/health`         | Service status, version and environment  |
| GET    | `/health/live`    | Liveness probe                           |
| GET    | `/health/ready`   | Readiness probe                          |
| GET    | `/api/items`      | List items                               |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/{id}` | One item                                 |

## Configuration

| Variable       | Default              | Purpose                                                  |
| -------------- | -------------------- | -------------------------------------------------------- |
| `PORT`         | `${{ values.port }}` | Port the service listens on                              |
| `APP_ENV`      | `development`        | Environment name reported by `/health`                   |
| `LOG_LEVEL`    | `info`               | `tracing` filter, for example `info,tower_http=debug`    |
{%- if values.database == 'postgres' %}
| `DATABASE_URL` | none, required       | PostgreSQL connection URL                                |
{%- endif %}

Invalid values stop the service at start with a message naming the variable.

## Owner

${{ values.owner }}

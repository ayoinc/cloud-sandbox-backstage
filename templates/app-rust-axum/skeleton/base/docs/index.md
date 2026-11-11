# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Language   | Rust 1.99, edition 2024                                                             |
| Framework  | axum 0.8 on tokio                                                                   |
| Storage    | {% if values.database == 'postgres' %}PostgreSQL through sqlx 0.9{% else %}In memory{% endif %} |
| Port       | `${{ values.port }}`                                                                |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/ci.yaml     # Format, clippy, tests, cargo-deny, image
{%- if values.database == 'postgres' %}
├── migrations/               # SQL migrations, compiled into the binary
{%- endif %}
├── src/
│   ├── main.rs               # Entry point, logging, graceful shutdown
│   ├── lib.rs                # Router and middleware
│   ├── config.rs             # Settings read from the environment
│   ├── error.rs              # Error type and its JSON form
│   ├── store.rs              # {% if values.database == 'postgres' %}Queries{% else %}In-memory store{% endif %}
│   └── routes/               # /health and /api/items
├── tests/api.rs              # Tests through the router
├── Cargo.toml / Cargo.lock
├── deny.toml                 # cargo-deny policy
├── rust-toolchain.toml       # Pinned compiler
{%- if values.database == 'postgres' %}
├── compose.yaml              # PostgreSQL for local development
{%- endif %}
├── Dockerfile
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Request handling

Every request gets an `x-request-id` (kept when the caller sends one), is
traced by `tower-http` and is cut off with `408` after 30 seconds. Logs are
JSON lines on standard output.

Errors are returned as `{ "error": "..." }`. Store failures are logged with
their cause and answered with a plain `500`.
{%- if values.database == 'postgres' %}

## Database

The connection pool connects on first use, so the service starts while the
database is still coming up; `/health/ready` answers `503` until it is
reachable. `/health` and `/health/live` never touch the database.

Queries are checked at run time, so building needs no database. Migrations live
in `migrations/` and are embedded in the binary:

```bash
${{ values.name }} migrate
```

Run it before a new version starts, for example as an init container or a job.
The tests marked `#[sqlx::test]` each run in a temporary database with the
migrations applied.

Pass `DATABASE_URL` from your secret store; it is never written to the image.
{%- else %}

## Storage

Items are kept in process memory: they are lost on restart and not shared
between replicas. `src/store.rs` is the only module to replace when you add a
database; its methods are already asynchronous and fallible.
{%- endif %}

## Shutdown

On `SIGINT` or `SIGTERM` the service stops accepting connections and lets
requests in flight finish.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job               | What it does                                                           |
| ----------------- | ---------------------------------------------------------------------- |
| Lint              | `cargo fmt --check` and clippy with warnings as errors                 |
| Test              | Tests{% if values.database == 'postgres' %} against a PostgreSQL service container, migrations{% endif %}, start check |
| Dependency policy | cargo-deny: licences, bans and sources fail the build; advisories are reported |
| Image             | Hadolint, image build, start check, Trivy report, publish to GHCR      |

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image runs as user 65532 on `gcr.io/distroless/cc`, which has no shell.
Use the HTTP probes of your orchestrator on `/health/live` and `/health/ready`.

## References

- [axum](https://docs.rs/axum/latest/axum/)
- [tokio](https://tokio.rs/)
- [tracing](https://docs.rs/tracing/latest/tracing/)
{%- if values.database == 'postgres' %}
- [sqlx](https://docs.rs/sqlx/latest/sqlx/)
{%- endif %}
- [cargo-deny](https://embarkstudios.github.io/cargo-deny/)

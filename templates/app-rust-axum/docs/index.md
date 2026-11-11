# Rust Axum Service Template

Creates a Rust HTTP service in a new GitHub repository: axum on tokio, JSON
logs with `tracing`, graceful shutdown, optional PostgreSQL through sqlx,
tests, a distroless container image and a pipeline that passes on the first
push.

## Form

| Field        | Effect                                                                    |
| ------------ | ------------------------------------------------------------------------- |
| Project Name | Name of the crate, the binary, the repository and the catalog entry       |
| Description  | Crate description, README, documentation and catalog entry                |
| Owner        | Owner of the catalog entry                                                |
| Database     | In-memory store, or PostgreSQL with sqlx, migrations and a `compose.yaml` |
| Port         | Default of `PORT`; port exposed by the image                              |
| Repository   | GitHub repository to create                                               |

## What is generated

- `src/`: configuration, router, handlers, error type and the store
- `tests/api.rs`: tests of every endpoint through the router
- `Cargo.lock` matching the selected database, so builds are reproducible
- `rust-toolchain.toml` pinning the compiler, `rustfmt` and `clippy`
- `deny.toml`: cargo-deny policy for advisories, licences and sources
- `Dockerfile`: release binary on `gcr.io/distroless/cc`, running as non-root
- `.github/workflows/ci.yaml`: format, clippy, tests, cargo-deny, image build
  with a start check, publication to the GitHub Container Registry on `main`
- `.github/dependabot.yml`: weekly updates of crates, base images and actions
- With PostgreSQL: `migrations/`, a `migrate` subcommand, `compose.yaml`, and
  tests that run against a PostgreSQL service container in the pipeline
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured.

## Template layout

| Directory              | Used                   |
| ---------------------- | ---------------------- |
| `skeleton/base`        | Always                 |
| `skeleton/db-none`     | Database is None       |
| `skeleton/db-postgres` | Database is PostgreSQL |

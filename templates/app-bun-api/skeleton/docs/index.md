# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Runtime    | Bun 1.4 (see `.bun-version`)                                                        |
| Framework  | Hono 4, TypeScript                                                                  |
| Port       | `${{ values.port }}`                                                                |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml        # Weekly dependency updates
│   └── workflows/ci.yaml     # Lint, type check, tests, image
├── src/
│   ├── index.ts              # Entry point: Bun.serve, graceful shutdown
│   ├── app.ts                # Hono application: middleware, health, errors
│   ├── env.ts                # Environment variables, validated and typed
│   ├── config.ts             # Service name
│   ├── logger.ts             # JSON logs and request logging
│   ├── store.ts              # ItemStore interface and in-memory implementation
│   └── routes/items.ts       # /api/items
├── test/                     # bun test
├── bun.lock                  # Locked dependency versions
├── bunfig.toml               # Coverage threshold
├── biome.json                # Lint and format rules
├── Dockerfile
├── catalog-info.yaml         # Catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Request handling

Every request gets an `X-Request-Id`, is logged as one JSON line with method,
path, status and duration, receives security headers and is limited to a 1 MiB
body. Probe requests are logged at `debug` level.

Errors are returned as `{ "error": "..." }`. A JSON body that does not match
its Zod schema is answered with `422` and the list of problems; unhandled
errors are logged with their stack and answered with a plain `500`.

The routes depend on the `ItemStore` interface. The generated implementation
keeps items in memory; implement the interface on your database and pass it to
`createApp` in `src/index.ts`.

## Shutdown

On `SIGINT` or `SIGTERM` the service reports not ready on `/health/ready`,
stops accepting connections and lets requests in flight finish.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job   | What it does                                                         |
| ----- | -------------------------------------------------------------------- |
| Lint  | Biome and the TypeScript type check                                  |
| Test  | `bun test` with coverage, then starts the service and calls it       |
| Image | Hadolint, image build, start check, Trivy report, publish to GHCR    |

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image holds the production dependencies and `src/`, and runs as the
unprivileged `bun` user.

## References

- [Bun](https://bun.com/docs)
- [Hono](https://hono.dev/docs/)
- [Zod](https://zod.dev/)
- [Biome](https://biomejs.dev/)

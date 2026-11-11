# ${{ values.name }}

${{ values.description }}

TypeScript API on [Bun](https://bun.com/), built with [Hono](https://hono.dev/).

## Getting started

Requires Bun (the version in `.bun-version`).

```bash
bun install
bun run dev
curl http://localhost:${{ values.port }}/health
```

## Scripts

- `bun run dev` starts the server and restarts it when a file changes
- `bun run start` starts the server
- `bun test` runs the tests (`bun run test:coverage` adds coverage and its threshold)
- `bun run typecheck` type-checks sources and tests
- `bun run lint` checks linting and formatting with Biome (`bun run format` fixes)

## Endpoints

| Method | Path              | Description                              |
| ------ | ----------------- | ---------------------------------------- |
| GET    | `/health`         | Service status and environment           |
| GET    | `/health/live`    | Liveness probe                           |
| GET    | `/health/ready`   | Readiness probe, 503 while shutting down |
| GET    | `/api/items`      | List items                               |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/:id`  | One item                                 |

## Configuration

Copy `.env.example` to `.env` for local overrides; Bun loads it automatically
and Git ignores it. The variables are validated in `src/env.ts`; an invalid
value stops the service at start with a message naming the variable.

| Variable    | Default              | Purpose                                 |
| ----------- | -------------------- | --------------------------------------- |
| `PORT`      | `${{ values.port }}` | Port the server listens on              |
| `APP_ENV`   | `development`        | Environment name reported by `/health`  |
| `LOG_LEVEL` | `info`               | `debug`, `info`, `warn` or `error`      |

To add a setting, add it to the schema in `src/env.ts`: its type follows.

## Owner

${{ values.owner }}

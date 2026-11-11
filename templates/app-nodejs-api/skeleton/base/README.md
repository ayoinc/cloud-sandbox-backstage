# ${{ values.name }}

${{ values.description }}

Node.js REST API ({% if values.framework == 'fastify' %}Fastify{% else %}Express{% endif %}, TypeScript).

## Getting started

```bash
npm install
npm run dev
```

The API listens on <http://localhost:${{ values.port }}>.

## Scripts

- `npm run dev` starts the server and restarts it when a file changes
- `npm run build` compiles TypeScript to `dist/`
- `npm run start` runs the compiled server
- `npm run lint` runs ESLint
- `npm run format:check` checks formatting with Prettier (`npm run format` fixes it)
- `npm run typecheck` type-checks sources and tests
- `npm test` runs the Vitest tests (`npm run test:coverage` adds coverage)

## Endpoints

| Method | Path            | Description               |
| ------ | --------------- | ------------------------- |
| GET    | `/health`       | Service status            |
| GET    | `/health/ready` | Readiness probe           |
| GET    | `/health/live`  | Liveness probe            |
| GET    | `/api`          | Welcome message           |
| GET    | `/api/example`  | Example endpoint to adapt |

`docs/openapi.yaml` describes them in OpenAPI 3. The build tests the running
service against that description with
[Schemathesis](https://schemathesis.readthedocs.io), so the two cannot drift
apart.

## Configuration

Copy `.env.example` to `.env` to change the defaults.

- `PORT` (default `${{ values.port }}`): port the server listens on
- `APP_ENV` (default `${{ values.environment }}`): environment name reported by `/health`
- `LOG_LEVEL` (default `info`): Pino log level

## Owner

${{ values.owner }}

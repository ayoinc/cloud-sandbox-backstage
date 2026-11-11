# ${{ values.name }}

${{ values.description }}

## Overview

| Setting     | Value                                                                               |
| ----------- | ----------------------------------------------------------------------------------- |
| Service     | `${{ values.name }}`                                                                |
| Owner       | `${{ values.owner }}`                                                               |
| Environment | `${{ values.environment }}`                                                         |
| Framework   | {% if values.framework == 'fastify' %}Fastify 5{% else %}Express 4{% endif %}, TypeScript |
| Port        | `${{ values.port }}`                                                                |
| Node.js     | 22 (see `.nvmrc`)                                                                   |
| Repository  | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

client: Client {
  shape: oval
}

api: ${{ values.name }} {
  app: "app.ts\nmiddleware, error handling"
  health: "routes/health.ts\n/health"
  routes: "routes/api.ts\n/api"
  config: config.ts {
    shape: page
  }
  app -> health
  app -> routes
  config -> app
}

client -> api.app: HTTP ${{ values.port }}
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
│   ├── nodejs.yaml           # Lint, type check, tests, build
{%- if values.enableDocker %}
│   └── docker.yaml           # Image build, smoke test and publish
{%- endif %}
├── docs/
│   ├── index.md              # This page
│   └── openapi.yaml          # OpenAPI 3 description of the endpoints
├── src/
│   ├── app.ts                # Application: middleware, routes, error handling
│   ├── config.ts             # Settings read from the environment
│   ├── index.ts              # Entry point: starts the server
{%- if values.framework != 'fastify' %}
│   ├── logger.ts             # Pino logger
{%- endif %}
│   └── routes/
│       ├── api.ts            # /api
│       └── health.ts         # /health
├── tests/
│   └── api.test.ts           # Vitest tests of every endpoint
{%- if values.enableDocker %}
├── Dockerfile
├── k8s/                      # Deployment and Service
{%- endif %}
├── catalog-info.yaml         # Backstage catalog entry
└── mkdocs.yml                # TechDocs configuration
```

## Local development

Requires Node.js 22 and npm.

```bash
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}
npm install
npm run dev
```

```bash
curl http://localhost:${{ values.port }}/health
curl http://localhost:${{ values.port }}/api
```

| Command                 | Purpose                                     |
| ----------------------- | ------------------------------------------- |
| `npm run dev`           | Server with restart on change               |
| `npm run build`         | Compile TypeScript to `dist/`               |
| `npm run start`         | Run the compiled server                     |
| `npm run lint`          | ESLint                                      |
| `npm run format`        | Format with Prettier                        |
| `npm run typecheck`     | Type-check sources and tests                |
| `npm test`              | Vitest                                      |
| `npm run test:coverage` | Vitest with coverage (70% thresholds)       |

## Endpoints

| Method | Path            | Response                                              |
| ------ | --------------- | ----------------------------------------------------- |
| GET    | `/health`       | `status`, `timestamp`, `service`, `environment`       |
| GET    | `/health/ready` | `{ "ready": true }`                                   |
| GET    | `/health/live`  | `{ "alive": true }`                                   |
| GET    | `/api`          | `message`, `version`                                  |
| GET    | `/api/example`  | `{ "data": "Example endpoint" }`                      |

Unknown routes return `404` with `{ "error": "Not Found" }`. Unhandled errors
return `500` with `{ "error": "Internal Server Error" }` and are logged.

Add routes in `src/routes/` and describe them in `docs/openapi.yaml`.

## Configuration

| Variable    | Default                     | Purpose                                 |
| ----------- | --------------------------- | --------------------------------------- |
| `PORT`      | `${{ values.port }}`        | Port the server listens on              |
| `APP_ENV`   | `${{ values.environment }}` | Environment name reported by `/health`  |
| `LOG_LEVEL` | `info`                      | Pino log level                          |

Copy `.env.example` to `.env` for local overrides; `.env` is ignored by Git.

## Continuous integration

`.github/workflows/nodejs.yaml` runs on every push and pull request to `main`:

| Job             | What it does                                                    |
| --------------- | --------------------------------------------------------------- |
| Lint            | ESLint, Prettier and the TypeScript type check                  |
| Test            | Vitest with coverage                                            |
| Build           | Compiles, starts the server and calls `/health`                 |
| Dependency scan | Trivy report of known vulnerabilities in `package-lock.json`    |

The dependency scan reports and does not fail the build. In a public
repository its results also appear in the repository's Security tab.
{%- if values.enableDocker %}

`.github/workflows/docker.yaml` runs on the same events:

| Job   | What it does                                                            |
| ----- | ----------------------------------------------------------------------- |
| Lint  | Hadolint on the `Dockerfile`, kubeconform on `k8s/`                     |
| Image | Builds the image, starts it, calls `/health`, scans it with Trivy       |

On pushes to `main` the image is published to the GitHub Container Registry
with the workflow's own token; no secret has to be configured.

## Docker

```bash
docker build -t ${{ values.name }} .
docker run --rm -p ${{ values.port }}:${{ values.port }} ${{ values.name }}
```

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

## Kubernetes

`k8s/` contains a Deployment (two replicas, probes on `/health/live` and
`/health/ready`) and a ClusterIP Service on port 80.

```bash
kubectl apply -f k8s/
```

The package is private by default. Either make it public in the package
settings or add an image pull secret to the Deployment.
{%- endif %}

## References

- [Node.js documentation](https://nodejs.org/docs/)
- [Express](https://expressjs.com/)
- [Fastify](https://fastify.dev/docs/latest/)
- [Vitest](https://vitest.dev/)

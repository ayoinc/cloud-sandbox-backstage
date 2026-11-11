# Node.js API Template

Creates a Node.js REST API in TypeScript, with Express or Fastify, in a new
GitHub repository, with tests and a pipeline that passes on the first push.

## Form

| Field         | Effect                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------ |
| Project Name  | Name of the service, the package and the catalog entry                                     |
| Description   | Package description, OpenAPI description, catalog entry                                    |
| Owner         | Owner of the catalog entry                                                                 |
| Environment   | Default of `APP_ENV`, reported by `/health`; lifecycle of the catalog entry                |
| Framework     | Express 4 or Fastify 5: sources, tests and dependencies of the selected framework          |
| Port          | Default of `PORT`; port of the image and the Kubernetes manifests                          |
| Enable Docker | Adds a Dockerfile, Kubernetes manifests and a workflow that builds and publishes the image |
| Repository    | GitHub repository to create                                                                |

## What is generated

- `src/`: application, configuration, `/health` and `/api` routes
- `tests/`: Vitest tests of every endpoint, with a coverage threshold
- `docs/openapi.yaml`: OpenAPI 3 description of the endpoints
- ESLint (typescript-eslint) and Prettier configuration
- `package-lock.json` matching the selected framework
- `.github/workflows/nodejs.yaml`: lint, type check, tests, build with a start
  check, dependency report
- With Docker: `Dockerfile`, `k8s/`, and `.github/workflows/docker.yaml`, which
  lints the Dockerfile and manifests, builds the image, starts it, calls
  `/health` and publishes to the GitHub Container Registry on `main`
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured: the image is published with the
workflow's own token.

## Template layout

| Directory                    | Used                      |
| ---------------------------- | ------------------------- |
| `skeleton/base`              | Always                    |
| `skeleton/framework-express` | Framework is Express      |
| `skeleton/framework-fastify` | Framework is Fastify      |
| `skeleton/docker`            | Enable Docker is selected |

Each framework directory holds the `package-lock.json` for its dependency set.
After changing `skeleton/base/package.json`, render the template for both
frameworks, run `npm install` in each result and copy the lockfile back with
the package name replaced by `${{ values.name }}`.

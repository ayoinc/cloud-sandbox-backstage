# Bun API Template

Creates a TypeScript API that runs on Bun, built with Hono, in a new GitHub
repository: environment variables validated at start, JSON logs, graceful
shutdown, tests with `bun test`, a container image and a pipeline that passes
on the first push.

## Form

| Field        | Effect                                                                 |
| ------------ | ---------------------------------------------------------------------- |
| Project Name | Name of the service, the package, the repository and the catalog entry |
| Description  | Package description, README, documentation and catalog entry           |
| Owner        | Owner of the catalog entry                                             |
| Port         | Default of `PORT`; port exposed by the image                           |
| Repository   | GitHub repository to create                                            |

## What is generated

- `src/env.ts`: environment variables parsed and typed with Zod; the service
  refuses to start on an invalid value
- `src/app.ts`, `src/routes/`: Hono application with `/health` and `/api/items`
- `src/logger.ts`: levelled JSON logs and request logging
- `src/index.ts`: `Bun.serve` with graceful shutdown
- `test/`: `bun test` tests of every endpoint and of the environment parsing
- `bun.lock` and `.bun-version`, so installs are reproducible
- Biome for linting and formatting, strict TypeScript
- `Dockerfile`: production dependencies only, running as the unprivileged
  `bun` user, with a health check
- `.github/workflows/ci.yaml`: lint, type check, tests with coverage, start
  check, image build and publication to the GitHub Container Registry on `main`
- `.github/dependabot.yml`: weekly updates of packages, base images and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured.

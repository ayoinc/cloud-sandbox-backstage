# .NET Minimal API Template

Creates an ASP.NET Core minimal API on .NET 10 (the current long-term support
release) in a new GitHub repository: OpenAPI document, health checks, request
validation, JSON logs, integration tests, a chiseled container image and a
pipeline that passes on the first push.

## Form

| Field        | Effect                                                       |
| ------------ | ------------------------------------------------------------ |
| Project Name | Name of the service, the repository and the catalog entry    |
| Description  | OpenAPI description, README, documentation and catalog entry |
| Owner        | Owner of the catalog entry                                   |
| Port         | Port for local runs and port exposed by the image            |
| Repository   | GitHub repository to create                                  |

## What is generated

- `src/Api`: minimal API with `/health`, liveness and readiness checks,
  `/api/items` with validated input and problem details for errors, and the
  OpenAPI document at `/openapi/v1.json`
- `tests/Api.Tests`: xUnit v3 tests that call the API in memory through
  `WebApplicationFactory`
- `App.slnx`, `global.json` pinning the SDK, `Directory.Build.props` with
  nullable reference types and warnings as errors, and central package versions
  in `Directory.Packages.props`
- `.editorconfig`, verified by `dotnet format` in the pipeline
- `Dockerfile`: published app on the chiseled ASP.NET runtime image, which has
  no shell and no package manager and runs as non-root
- `.github/workflows/ci.yaml`: format check, build, tests, start check, image
  build and publication to the GitHub Container Registry on `main`
- `.github/dependabot.yml`: weekly updates of packages, base images and actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured.

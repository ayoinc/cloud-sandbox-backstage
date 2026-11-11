# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Platform   | .NET 10 (LTS), ASP.NET Core minimal API                                             |
| Port       | `${{ values.port }}`                                                                |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml          # Weekly dependency updates
│   └── workflows/ci.yaml       # Format, build, tests, image
├── src/Api/
│   ├── Program.cs              # Services, middleware, health endpoints
│   ├── ServiceOptions.cs       # Name and description of the service
│   ├── Items/                  # /api/items: endpoints, contracts, store
│   └── appsettings*.json       # Configuration
├── tests/Api.Tests/            # xUnit v3 tests through WebApplicationFactory
├── App.slnx                    # Solution
├── global.json                 # SDK version and test runner
├── Directory.Build.props       # Settings shared by every project
├── Directory.Packages.props    # Package versions, in one place
├── .editorconfig               # Code style, enforced by dotnet format
├── Dockerfile
├── catalog-info.yaml           # Catalog entry
└── mkdocs.yml                  # TechDocs configuration
```

## Request handling

- Request bodies are validated from their data annotations before the handler
  runs (`AddValidation`); an invalid body is answered with `400` and the
  errors per field.
- Unhandled exceptions and empty error responses become problem details; no
  stack trace leaves the service.
- Outside the `Development` environment every log line is one JSON object.

The endpoints depend on `IItemStore`. The generated implementation keeps items
in memory; implement the interface on your database and register it in
`Program.cs`.

## Health checks

`/health/live` runs no check: it answers while the process does.
`/health/ready` runs the checks registered with the `ready` tag, for example:

```csharp
builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database", tags: ["ready"]);
```

## OpenAPI

The document is generated from the endpoints at run time and served at
`/openapi/v1.json`. Its title and description come from the `Service` section
of `appsettings.json`.

## Tests

`tests/Api.Tests` starts the API in memory with `WebApplicationFactory` and
calls it over HTTP. The tests run on Microsoft.Testing.Platform, selected in
`global.json`.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job            | What it does                                                           |
| -------------- | ---------------------------------------------------------------------- |
| Build and test | `dotnet format` check, build with warnings as errors, tests, start check, vulnerable packages report |
| Image          | Hadolint, image build, start check, Trivy report, publish to GHCR      |

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image is built on the chiseled ASP.NET runtime: no shell, no package
manager, non-root user. Use the HTTP probes of your orchestrator on
`/health/live` and `/health/ready`.

## References

- [Minimal APIs](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis)
- [OpenAPI in ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/openapi/overview)
- [Health checks](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks)
- [xUnit.net v3](https://xunit.net/docs/getting-started/v3/getting-started)

# ${{ values.name }}

${{ values.description }}

ASP.NET Core minimal API on .NET 10.

## Getting started

Requires the .NET 10 SDK (`global.json` pins the version).

```bash
dotnet run --project src/Api
curl http://localhost:${{ values.port }}/health
```

## Commands

- `dotnet run --project src/Api` starts the API
- `dotnet test` runs the tests
- `dotnet format` formats the code as `.editorconfig` says
- `dotnet build` builds with warnings as errors

## Endpoints

| Method | Path               | Description                                   |
| ------ | ------------------ | --------------------------------------------- |
| GET    | `/health`          | Service status, version and environment       |
| GET    | `/health/live`     | Liveness probe                                |
| GET    | `/health/ready`    | Readiness probe: checks tagged `ready`        |
| GET    | `/api/items`       | List items                                    |
| POST   | `/api/items`       | Create an item: `{"name": "..."}`             |
| GET    | `/api/items/{id}`  | One item                                      |
| GET    | `/openapi/v1.json` | OpenAPI description of the endpoints          |

Errors are answered as RFC 9457 problem details (`application/problem+json`).

## Configuration

ASP.NET Core reads `src/Api/appsettings.json`, then environment variables,
which win. A nested key is written with two underscores: `Service__Name`.

| Setting                    | Default                    | Purpose                                 |
| -------------------------- | -------------------------- | --------------------------------------- |
| `ASPNETCORE_HTTP_PORTS`    | `${{ values.port }}` in the image | Port the server listens on       |
| `ASPNETCORE_ENVIRONMENT`   | `Production`               | Environment name reported by `/health`  |
| `Logging__LogLevel__Default` | `Information`            | Minimum log level                       |

Keep secrets out of `appsettings.json`: use `dotnet user-secrets` locally and
environment variables or your secret store when deployed.

## Owner

${{ values.owner }}

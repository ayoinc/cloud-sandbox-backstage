# ${{ values.name }}

${{ values.description }}

## Overview

| Setting    | Value                                                                               |
| ---------- | ----------------------------------------------------------------------------------- |
| Service    | `${{ values.name }}`                                                                |
| Owner      | `${{ values.owner }}`                                                               |
| Framework  | Ktor 3 on Netty, Kotlin 2.4, JDK 25                                                 |
| Package    | `${{ values.packageName }}`                                                         |
| Port       | `${{ values.port }}`                                                                |
| Repository | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

## Project structure

```
${{ values.name }}/
├── .github/
│   ├── dependabot.yml          # Weekly dependency updates
│   └── workflows/ci.yaml       # ktlint, tests, image
├── gradle/
│   ├── libs.versions.toml      # Version catalog
│   └── wrapper/                # Gradle wrapper, with its checksum
├── src/
│   ├── main/kotlin/
│   │   ├── Application.kt      # Entry point and module
│   │   ├── Settings.kt         # Service name and environment
│   │   ├── Plugins.kt          # Serialization, request IDs, logging, errors
│   │   ├── HealthRoutes.kt     # /health
│   │   ├── ItemRoutes.kt       # /api/items
│   │   └── ItemStore.kt        # Store interface and in-memory implementation
│   ├── main/resources/
│   │   ├── application.yaml    # Ktor and service settings
│   │   └── logback.xml         # JSON logs
│   └── test/kotlin/            # Tests with Ktor's test host
├── build.gradle.kts
├── settings.gradle.kts
├── Dockerfile
├── catalog-info.yaml           # Catalog entry
└── mkdocs.yml                  # TechDocs configuration
```

The sources declare the package `${{ values.packageName }}` and sit directly
in `src/main/kotlin`, as the Kotlin coding conventions allow for a single
root package.

## Request handling

- Bodies are read and written as JSON with kotlinx.serialization; a body with
  unknown properties is rejected with `400`.
- Every request gets an identifier: the caller's `X-Request-Id` when present,
  a new one otherwise. It is returned in the response and is the `requestId`
  field of every log line of the request.
- Errors are returned as `{ "error": "..." }`. Unhandled exceptions are logged
  with their stack trace and answered with a plain `500`.
- Requests to `/health` are not logged.

The routes depend on the `ItemStore` interface. The generated implementation
keeps items in memory; implement the interface on your database and pass it to
`app()` in `Application.kt`.

## Shutdown

On `SIGTERM` the server stops accepting connections and gives requests in
flight the grace period set in `application.yaml` to finish.

## Continuous integration

`.github/workflows/ci.yaml` runs on every push to `main` and on demand:

| Job            | What it does                                                         |
| -------------- | -------------------------------------------------------------------- |
| Build and test | ktlint, tests, fat JAR, then starts the service and calls it         |
| Image          | Hadolint, image build, start check, Trivy report, publish to GHCR    |

The Gradle wrapper JAR is verified against the checksums published by Gradle,
and the distribution it downloads against `distributionSha256Sum`.

Published images:

```
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:sha-<commit>
```

The image runs as user 65532 on `gcr.io/distroless/java25`, which has no
shell. Use the HTTP probes of your orchestrator on `/health/live` and
`/health/ready`.

## References

- [Ktor](https://ktor.io/docs/)
- [kotlinx.serialization](https://kotlinlang.org/docs/serialization.html)
- [Gradle version catalogs](https://docs.gradle.org/current/userguide/version_catalogs.html)
- [ktlint](https://pinterest.github.io/ktlint/)

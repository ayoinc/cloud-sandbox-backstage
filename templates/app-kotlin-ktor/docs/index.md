# Kotlin Ktor Service Template

Creates a Ktor 3 service written in Kotlin in a new GitHub repository: Gradle
Kotlin DSL with a version catalog, kotlinx.serialization, JSON logs with
request identifiers, tests, a distroless container image and a pipeline that
passes on the first push.

## Form

| Field          | Effect                                                                     |
| -------------- | -------------------------------------------------------------------------- |
| Project Name   | Name of the service, the Gradle project, the repository, the catalog entry |
| Description    | README, documentation and catalog entry                                    |
| Owner          | Owner of the catalog entry                                                 |
| Kotlin Package | Package of the sources and Gradle group                                    |
| Port           | Default of `PORT`; port exposed by the image                               |
| Repository     | GitHub repository to create                                                |

## What is generated

- `src/main/kotlin`: Ktor application on Netty with `/health` and `/api/items`,
  JSON content negotiation, request identifiers, request logging and error
  handling
- `src/main/resources`: `application.yaml` (settings, overridable from the
  environment) and `logback.xml` (JSON logs)
- `src/test/kotlin`: tests of every endpoint with Ktor's test host
- `gradle/libs.versions.toml`: every dependency and plugin version in one place
- The Gradle wrapper, so no local Gradle installation is needed
- ktlint through its Gradle plugin
- `Dockerfile`: fat JAR on `gcr.io/distroless/java25`, running as non-root
- `.github/workflows/ci.yaml`: ktlint, tests, start check, image build and
  publication to the GitHub Container Registry on `main`
- `.github/dependabot.yml`: weekly updates of dependencies, base images and
  actions
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured.

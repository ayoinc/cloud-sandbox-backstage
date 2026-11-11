# ${{ values.name }}

${{ values.description }}

[Ktor](https://ktor.io/) 3 service written in Kotlin.

## Getting started

Requires JDK 25. Gradle is downloaded by the wrapper.

```bash
./gradlew run
curl http://localhost:${{ values.port }}/health
```

## Commands

- `./gradlew run` starts the service
- `./gradlew test` runs the tests
- `./gradlew ktlintCheck` checks the code style (`./gradlew ktlintFormat` fixes it)
- `./gradlew buildFatJar` builds `build/libs/app.jar`, runnable with `java -jar`

## Endpoints

| Method | Path              | Description                              |
| ------ | ----------------- | ---------------------------------------- |
| GET    | `/health`         | Service status, version and environment  |
| GET    | `/health/live`    | Liveness probe                           |
| GET    | `/health/ready`   | Readiness probe                          |
| GET    | `/api/items`      | List items                               |
| POST   | `/api/items`      | Create an item: `{"name": "..."}`        |
| GET    | `/api/items/{id}` | One item                                 |

## Configuration

Settings are in `src/main/resources/application.yaml`; the environment
overrides them.

| Variable    | Default              | Purpose                                 |
| ----------- | -------------------- | --------------------------------------- |
| `PORT`      | `${{ values.port }}` | Port the server listens on              |
| `APP_ENV`   | `development`        | Environment name reported by `/health`  |
| `LOG_LEVEL` | `INFO`               | Root log level (`logback.xml`)          |

Dependency and plugin versions are in `gradle/libs.versions.toml`.

## Owner

${{ values.owner }}

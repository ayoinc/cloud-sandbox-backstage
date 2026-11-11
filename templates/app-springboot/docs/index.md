# Spring Boot Application Template

Creates a Spring Boot 3.5 service built with Maven in a new GitHub repository,
with tests and a pipeline that passes on the first push.

## Form

| Field        | Effect                                                                          |
| ------------ | ------------------------------------------------------------------------------- |
| Project Name | Maven artifact, `spring.application.name` and the catalog entry                 |
| Description  | Maven description and catalog entry                                             |
| Owner        | Owner of the catalog entry                                                      |
| Environment  | Default of `APP_ENV`, reported by `/api/health`; lifecycle of the catalog entry |
| Java Version | 17 or 21: `java.version` in the POM, `.java-version` for CI, and the image      |
| Server Port  | Default of `SERVER_PORT`; port exposed by the image                             |
| Repository   | GitHub repository to create                                                     |

## What is generated

- `src/main/java/com/example/`: the application and a controller with `/api`
  and `/api/health`; Spring Boot Actuator serves `/actuator/health`
- `src/test/java/com/example/`: context test and MockMvc tests
- `pom.xml` with the Web, Actuator and Validation starters and the SpotBugs
  plugin
- `Dockerfile`: Maven build stage, JRE runtime stage, non-root user
- `.github/workflows/springboot.yaml`: `mvn verify`, SpotBugs, dependency
  report, Dockerfile lint, image build with a start check, and publishing to
  the GitHub Container Registry on `main`
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

The workflow uses the Maven that is installed on GitHub's runners, so the
repository has no Maven wrapper. No secret or variable has to be configured.

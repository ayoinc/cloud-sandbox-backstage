# Docker Application Template

Creates a small containerised HTTP service in a new GitHub repository, with a
pipeline that lints, tests, scans and publishes the image and passes on the
first push.

## Form

| Field               | Effect                                                                                 |
| ------------------- | -------------------------------------------------------------------------------------- |
| Name                | Name of the service and the catalog entry                                              |
| Description         | Catalog entry and documentation                                                        |
| Owner               | Owner of the catalog entry                                                             |
| Base Image          | Image the application is built on; it also selects the language of the starter service |
| Container Port      | Default of `PORT`, the exposed port, and the port in `compose.yaml` and the tests      |
| Include Healthcheck | Adds a `HEALTHCHECK` that calls `/health`; the container test waits for it to pass     |
| Repository          | GitHub repository to create                                                            |

| Base image                      | Starter service                                    |
| ------------------------------- | -------------------------------------------------- |
| `node:24-alpine`                | Node.js, `node:http`, tests with `node --test`     |
| `python:3.13-alpine`            | Python, `http.server`, tests with `unittest`       |
| `eclipse-temurin:21-jdk-alpine` | Java, JDK HTTP server, tests with plain assertions |
| `golang:1.27-alpine`            | Go, `net/http`, tests with `go test`               |

The starter services use the standard library only and answer on `/` and
`/health`.

## What is generated

- The starter service and its unit tests
- `Dockerfile` with a `test` stage that runs the unit tests and a runtime
  stage that runs as a non-root user
- `compose.yaml` for local runs
- `tests/container-structure-test.yaml` and `tests/docker-test.sh`, which
  check the image metadata and the running container
- `.github/workflows/docker.yaml`: Hadolint, unit tests, image build,
  structure and container tests, Trivy report, bill of materials, and a
  multi-platform image published to the GitHub Container Registry on pushes
- `catalog-info.yaml`, `mkdocs.yml` and `docs/index.md` for the portal

No secret or variable has to be configured: the image is published with the
workflow's own token.

## Template layout

| Directory         | Used                                          |
| ----------------- | --------------------------------------------- |
| `skeleton/base`   | Always                                        |
| `skeleton/node`   | Base image is `node:24-alpine`                |
| `skeleton/python` | Base image is `python:3.13-alpine`            |
| `skeleton/java`   | Base image is `eclipse-temurin:21-jdk-alpine` |
| `skeleton/golang` | Base image is `golang:1.27-alpine`            |

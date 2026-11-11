# ${{ values.name }}

${{ values.description }}

## Overview

| Setting     | Value                                                                               |
| ----------- | ----------------------------------------------------------------------------------- |
| Application | `${{ values.name }}`                                                                |
| Owner       | `${{ values.owner }}`                                                               |
| Language    | {% if values.baseImage.startsWith('node') %}Node.js{% elif values.baseImage.startsWith('python') %}Python{% elif values.baseImage.startsWith('golang') %}Go{% else %}Java{% endif %} |
| Base image  | `${{ values.baseImage }}`                                                           |
| Port        | `${{ values.port }}`                                                                |
| Healthcheck | {% if values.includeHealthcheck %}`HEALTHCHECK` calling `/health`{% else %}Not included{% endif %} |
| Repository  | <https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}> |

```d2
direction: right

push: Push or pull request {
  shape: oval
}

pipeline: Docker workflow {
  lint: "Lint\nHadolint, compose.yaml"
  test: "Build and test\nunit tests, structure tests,\ncontainer checks, Trivy"
  publish: "Publish\nlinux/amd64, linux/arm64"
  lint -> test -> publish
}

registry: ghcr.io {
  shape: cylinder
}

push -> pipeline.lint
pipeline.publish -> registry: pushes to main and v* tags
```

## Project structure

```
${{ values.name }}/
├── .github/workflows/
│   └── docker.yaml                    # Lint, build, test, scan, publish
├── Dockerfile                         # Build, test and runtime stages
├── compose.yaml                       # Local run with Docker Compose
{%- if values.baseImage.startsWith('node') %}
├── package.json
├── package-lock.json
├── src/
│   ├── index.js                       # Entry point: starts the server
│   └── server.js                      # Request handling
├── test/
│   └── server.test.js                 # Unit tests (node --test)
{%- elif values.baseImage.startsWith('python') %}
├── app.py                             # The service
├── test_app.py                        # Unit tests (unittest)
├── requirements.txt                   # Dependencies (none yet)
{%- elif values.baseImage.startsWith('golang') %}
├── go.mod
├── main.go                            # The service
├── main_test.go                       # Unit tests (go test)
{%- else %}
├── src/main/java/app/Main.java        # The service
├── src/test/java/app/MainTest.java    # Unit tests (plain assertions)
{%- endif %}
├── tests/
│   ├── container-structure-test.yaml  # Checks of the image metadata
│   └── docker-test.sh                 # Starts the image and calls it
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```

## The service

| Method | Path      | Response                                               |
| ------ | --------- | ------------------------------------------------------ |
| GET    | `/`       | `{ "service": "${{ values.name }}", "message": "..." }` |
| GET    | `/health` | `{ "status": "healthy" }`                              |
| other  | any       | `404` with `{ "error": "Not Found" }`                  |

The port comes from the `PORT` environment variable and defaults to
`${{ values.port }}`.

## The image

The `Dockerfile` has three stages:

| Stage   | Purpose                                                                  |
| ------- | ------------------------------------------------------------------------ |
{%- if values.baseImage.startsWith('node') %}
| `base`  | Installs the production dependencies with `npm ci` and copies the source |
| `test`  | Runs the unit tests with `node --test`                                   |
| final   | The `base` stage with the runtime settings                               |
{%- elif values.baseImage.startsWith('python') %}
| `base`  | Installs `requirements.txt` and copies the source                        |
| `test`  | Runs the unit tests with `python -m unittest`                            |
| final   | The `base` stage with the runtime settings                               |
{%- elif values.baseImage.startsWith('golang') %}
| `build` | Compiles a static binary                                                 |
| `test`  | Runs `go vet` and `go test`                                              |
| final   | `alpine` with only the binary                                            |
{%- else %}
| `build` | Compiles the sources and packages `app.jar`                              |
| `test`  | Compiles and runs the tests with assertions enabled                      |
| final   | `eclipse-temurin:21-jre-alpine` with only `app.jar`                      |
{%- endif %}

The final image runs as the non-root user `10001`, exposes port
`${{ values.port }}`{% if values.includeHealthcheck %} and has a `HEALTHCHECK` that calls `/health` every 30 seconds{% endif %}.

## Local development

```bash
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.destination.repo }}

# Build and run
docker compose up --build

# Unit tests, inside the image build
docker build --target test .

# Build the image and check it from the outside
docker build -t ${{ values.name }}:local .
bash tests/docker-test.sh
```

`tests/docker-test.sh` starts the image on a free port, calls `/` and
`/health`, expects `404` for an unknown path{% if values.includeHealthcheck %}, waits for the image's
`HEALTHCHECK` to report healthy{% endif %} and removes the container.

## Continuous integration

`.github/workflows/docker.yaml` runs on pushes to `main`, on `v*` tags and on
pull requests to `main`:

| Job            | What it does                                                                                              |
| -------------- | --------------------------------------------------------------------------------------------------------- |
| Lint           | Hadolint on the `Dockerfile` (fails on warnings), `docker compose config` on `compose.yaml`               |
| Build and test | Unit tests (`--target test`), image build, container-structure-test, `tests/docker-test.sh`, Trivy, SBOM  |
| Publish        | On pushes only: builds for `linux/amd64` and `linux/arm64` and pushes to the GitHub Container Registry    |

The Trivy scan reports known vulnerabilities and does not fail the build. In
a public repository its results also appear in the repository's Security tab.
The CycloneDX bill of materials is kept as the `sbom` artifact of the run.

Publishing uses the workflow's own token; no secret has to be configured.

| Event            | Image tags                                 |
| ---------------- | ------------------------------------------ |
| Push to `main`   | `latest`, `sha-<commit>`                   |
| Tag `v1.2.3`     | `1.2.3`, `1.2`, `sha-<commit>`             |

```bash
docker pull ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}:latest
```

The package is private by default; change its visibility in the package
settings on GitHub if others need to pull it.

## References

- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Hadolint](https://github.com/hadolint/hadolint)
- [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test)
- [Trivy](https://trivy.dev/)

# ${{ values.name }}

${{ values.description }}

Containerised {% if values.baseImage.startsWith('node') %}Node.js{% elif values.baseImage.startsWith('python') %}Python{% elif values.baseImage.startsWith('golang') %}Go{% else %}Java{% endif %} service built on `${{ values.baseImage }}`.

## Getting started

```bash
docker compose up --build
```

The service listens on <http://localhost:${{ values.port }}>.

```bash
curl http://localhost:${{ values.port }}/
curl http://localhost:${{ values.port }}/health
```

## Commands

- `docker build -t ${{ values.name }}:local .` builds the image
- `docker build --target test .` runs the unit tests inside the build
- `docker run --rm -p ${{ values.port }}:${{ values.port }} ${{ values.name }}:local` runs the image
- `bash tests/docker-test.sh` starts the image and checks its endpoints
- `docker compose up --build` builds and runs it with Compose

## Configuration

`PORT` sets the port the service listens on (default `${{ values.port }}`).

## Documentation

`docs/index.md` describes the project structure and the pipeline; it is
published as TechDocs in the developer portal.

## Owner

${{ values.owner }}

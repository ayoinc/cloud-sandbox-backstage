# Docker Base Images

Production-ready Docker base images for common application runtimes.

## Available Images

| Image    | Description          | Base                       |
| -------- | -------------------- | -------------------------- |
| `node`   | Node.js applications | Alpine with tini           |
| `python` | Python applications  | Debian slim with venv      |
| `golang` | Go applications      | Distroless (static)        |
| `java`   | Java/Spring Boot     | Eclipse Temurin JRE Alpine |

## Features

All images include:

- **Multi-stage builds** for minimal final image size
- **Non-root user** execution (UID 1001)
- **Health checks** configured
- **Security hardening** (read-only fs support, no shell in Go)
- **Multi-architecture** support (amd64, arm64)
- **SBOM generation** for supply chain security
- **Trivy scanning** for vulnerabilities

## Usage

### Node.js Application

```dockerfile
FROM ghcr.io/company/base/node:latest AS builder
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM ghcr.io/company/base/node:latest
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main.js"]
```

### Python Application

```dockerfile
FROM ghcr.io/company/base/python:latest AS builder
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY . .

FROM ghcr.io/company/base/python:latest
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Go Application

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /server ./cmd/server

FROM ghcr.io/company/base/golang:latest
COPY --from=builder /server /server
ENTRYPOINT ["/server"]
```

### Java/Spring Boot Application

```dockerfile
FROM ghcr.io/company/base/java:latest AS builder
COPY . .
RUN ./gradlew bootJar
RUN java -Djarmode=layertools -jar build/libs/*.jar extract

FROM ghcr.io/company/base/java:latest
COPY --from=builder /app/extracted/dependencies/ ./
COPY --from=builder /app/extracted/spring-boot-loader/ ./
COPY --from=builder /app/extracted/application/ ./
CMD ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

## Building Locally

```bash
# Build Node.js image
docker build -t base/node:local images/node/

# Build with specific version
docker build --build-arg NODE_VERSION=22 -t base/node:22 images/node/

# Build multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t base/node:latest images/node/
```

## Security

All images are:

- Scanned with Trivy for vulnerabilities
- Built with provenance attestations
- Signed with cosign (when published)
- Include SBOM (Software Bill of Materials)

### Verifying Images

```bash
# Verify signature
cosign verify ghcr.io/company/base/node:latest

# Check SBOM
docker sbom ghcr.io/company/base/node:latest
```

## Customization

### Environment Variables

| Variable    | Description      | Default             |
| ----------- | ---------------- | ------------------- |
| `PORT`      | Application port | 3000/8000/8080      |
| `NODE_ENV`  | Node environment | production          |
| `JAVA_OPTS` | JVM options      | Container-optimized |

### Build Arguments

| Argument         | Description     |
| ---------------- | --------------- |
| `NODE_VERSION`   | Node.js version |
| `PYTHON_VERSION` | Python version  |
| `GO_VERSION`     | Go version      |
| `JAVA_VERSION`   | Java version    |

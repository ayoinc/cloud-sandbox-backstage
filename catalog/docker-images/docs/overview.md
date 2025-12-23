# Overview

## Architecture

The Docker Images Registry provides centralized container image management with security scanning, signing, and multi-architecture support. All images follow security best practices and are regularly updated with security patches.

```
+------------------------------------------------------------------+
|                    IMAGE BUILD PIPELINE                           |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+         +-------------------+              |
|  |   Dockerfile      |         |   .dockerignore   |              |
|  |   Multi-stage     |-------->|   Build Context   |              |
|  |   Optimized       |         |   Minimal         |              |
|  +-------------------+         +-------------------+              |
|           |                            |                          |
|           v                            v                          |
|  +--------------------------------------------------+            |
|  |              DOCKER BUILDKIT                      |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Cache      |  | Parallel   |  | Secrets    |  |            |
|  |  | Layers     |  | Stages     |  | Mount      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              SECURITY PIPELINE                    |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Trivy      |  | SBOM       |  | Cosign     |  |            |
|  |  | Scan       |  | Generate   |  | Sign       |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## Dockerfile Best Practices

### Multi-Stage Build (Node.js)

```dockerfile
# Build stage
FROM registry.company.com/base/node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (cache optimization)
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source and build
COPY . .
RUN npm run build

# Production stage
FROM registry.company.com/base/node:20-alpine AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy only production artifacts
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Security: Run as non-root
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "dist/main.js"]
```

### Multi-Stage Build (Python)

```dockerfile
# Build stage
FROM registry.company.com/base/python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Production stage
FROM registry.company.com/base/python:3.12-slim AS production

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY --chown=appuser:appuser . .

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:app"]
```

### Multi-Stage Build (Go)

```dockerfile
# Build stage
FROM registry.company.com/base/golang:1.22-alpine AS builder

WORKDIR /app

# Download dependencies first (cache optimization)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy source and build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o /app/server ./cmd/server

# Production stage - distroless
FROM gcr.io/distroless/static-debian12:nonroot AS production

COPY --from=builder /app/server /server

USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/server"]
```

### Multi-Stage Build (Java/Spring Boot)

```dockerfile
# Build stage
FROM registry.company.com/base/java:21-alpine AS builder

WORKDIR /app

# Copy gradle files first (cache dependencies)
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
COPY gradlew ./

RUN ./gradlew dependencies --no-daemon

# Copy source and build
COPY src ./src
RUN ./gradlew bootJar --no-daemon -x test

# Extract layers for better caching
RUN java -Djarmode=layertools -jar build/libs/*.jar extract --destination extracted

# Production stage
FROM registry.company.com/base/java:21-alpine AS production

RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring

WORKDIR /app

# Copy layers in order of change frequency
COPY --from=builder --chown=spring:spring /app/extracted/dependencies/ ./
COPY --from=builder --chown=spring:spring /app/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=spring:spring /app/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=spring:spring /app/extracted/application/ ./

USER spring

HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

## Security Hardening

### Non-Root User

```dockerfile
# Alpine
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Debian/Ubuntu
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /bin/false appuser

USER appuser
```

### Read-Only Filesystem

```dockerfile
# Create required writable directories
RUN mkdir -p /tmp /app/logs && \
    chown -R appuser:appgroup /tmp /app/logs

USER appuser

# In docker-compose.yaml or Kubernetes
# read_only: true
# tmpfs:
#   - /tmp
```

### Minimal Attack Surface

```dockerfile
# Remove shells and utilities
FROM gcr.io/distroless/static-debian12:nonroot

# Or remove after build
RUN rm -rf /bin/sh /bin/bash /usr/bin/wget /usr/bin/curl
```

### Secrets Handling

```dockerfile
# Use BuildKit secrets (never copy secrets into image)
# syntax=docker/dockerfile:1.4

RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    npm ci --only=production

# Build with: docker build --secret id=npm_token,src=.npmrc .
```

## Layer Optimization

### Order Matters

```dockerfile
# Less frequently changed -> more frequently changed
FROM base

# 1. System packages (rarely change)
RUN apt-get update && apt-get install -y package

# 2. Dependencies (change occasionally)
COPY package.json package-lock.json ./
RUN npm ci

# 3. Source code (change frequently)
COPY . .
RUN npm run build
```

### Combine RUN Commands

```dockerfile
# Bad: Multiple layers
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2
RUN rm -rf /var/lib/apt/lists/*

# Good: Single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        package1 \
        package2 \
    && rm -rf /var/lib/apt/lists/*
```

### .dockerignore

```
# .dockerignore
.git
.gitignore
.dockerignore
Dockerfile*
docker-compose*
README.md
LICENSE
.env*
.vscode
.idea
node_modules
__pycache__
*.pyc
.pytest_cache
coverage
.nyc_output
dist
build
*.log
.DS_Store
Thumbs.db
tests/
docs/
*.md
!README.md
```

## Multi-Architecture Builds

### Building for Multiple Platforms

```bash
# Create builder instance
docker buildx create --name multiarch --driver docker-container --use

# Build for multiple platforms
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag registry.company.com/apps/myapp:v1.0.0 \
    --push \
    .

# Inspect manifest
docker buildx imagetools inspect registry.company.com/apps/myapp:v1.0.0
```

### Platform-Specific Build Args

```dockerfile
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder

RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

# Cross-compile for target
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /app/server
```

## Image Signing with Cosign

```bash
# Generate key pair
cosign generate-key-pair

# Sign image
cosign sign --key cosign.key registry.company.com/apps/myapp:v1.0.0

# Verify signature
cosign verify --key cosign.pub registry.company.com/apps/myapp:v1.0.0

# Sign with OIDC (keyless)
COSIGN_EXPERIMENTAL=1 cosign sign registry.company.com/apps/myapp:v1.0.0

# Attach attestation
cosign attest --key cosign.key --predicate sbom.json \
    registry.company.com/apps/myapp:v1.0.0
```

## SBOM Generation

```bash
# Generate SBOM with Syft
syft registry.company.com/apps/myapp:v1.0.0 -o spdx-json > sbom.json

# Attach SBOM to image
cosign attach sbom --sbom sbom.json registry.company.com/apps/myapp:v1.0.0

# Generate with Docker
docker sbom registry.company.com/apps/myapp:v1.0.0

# Include in build (BuildKit)
docker buildx build --sbom=true --push -t registry.company.com/apps/myapp:v1.0.0 .
```

## Vulnerability Scanning

### Trivy Scanner

```bash
# Scan image
trivy image registry.company.com/apps/myapp:v1.0.0

# Scan with severity filter
trivy image --severity HIGH,CRITICAL registry.company.com/apps/myapp:v1.0.0

# Output as JSON
trivy image --format json --output results.json registry.company.com/apps/myapp:v1.0.0

# Fail on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL registry.company.com/apps/myapp:v1.0.0

# Ignore unfixed vulnerabilities
trivy image --ignore-unfixed registry.company.com/apps/myapp:v1.0.0
```

### Grype Scanner

```bash
# Scan image
grype registry.company.com/apps/myapp:v1.0.0

# Output formats
grype registry.company.com/apps/myapp:v1.0.0 -o json
grype registry.company.com/apps/myapp:v1.0.0 -o sarif

# Fail on severity
grype registry.company.com/apps/myapp:v1.0.0 --fail-on critical
```

### Docker Scout

```bash
# Scan image
docker scout cves registry.company.com/apps/myapp:v1.0.0

# Show recommendations
docker scout recommendations registry.company.com/apps/myapp:v1.0.0

# Compare images
docker scout compare registry.company.com/apps/myapp:v1.0.0 \
    --to registry.company.com/apps/myapp:v0.9.0
```

## Registry Configuration

### Harbor Registry

```yaml
# harbor-core configuration
version: 1
registries:
  - name: company-registry
    url: https://registry.company.com
    description: Company private registry
    
replication:
  - name: replicate-to-dr
    target: https://dr-registry.company.com
    trigger:
      type: scheduled
      cron: "0 0 * * *"
    filters:
      - resource: image
        pattern: "apps/**"
```

### Docker Daemon Configuration

```json
{
  "insecure-registries": [],
  "registry-mirrors": ["https://mirror.company.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "features": {
    "buildkit": true
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

## Base Image Maintenance

### Update Schedule

| Image Type | Update Frequency | Security Patches |
|------------|------------------|------------------|
| OS Base | Monthly | Within 24 hours |
| Runtime | Minor releases | Within 48 hours |
| Build Tools | Monthly | Within 1 week |

### Automated Updates

```yaml
# renovate.json
{
  "extends": ["config:base"],
  "docker": {
    "fileMatch": ["Dockerfile$", "Dockerfile\\..*$"]
  },
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "matchPackagePatterns": ["^registry.company.com/base/"],
      "groupName": "base images",
      "automerge": true,
      "automergeType": "pr",
      "schedule": ["after 10pm and before 5am on monday"]
    }
  ]
}
```

## Related Resources

- [Docker Documentation](https://docs.docker.com/)
- [BuildKit](https://docs.docker.com/build/buildkit/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Cosign](https://docs.sigstore.dev/cosign/overview/)
- [Trivy](https://aquasecurity.github.io/trivy/)

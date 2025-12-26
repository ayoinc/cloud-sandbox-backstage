# Usage Guide

## Docker Image Build Pipeline

```d2
direction: right

title: Docker Image Lifecycle {
  shape: text
  near: top-center
  style.font-size: 24
}

build: Build Phase {
  style.fill: "#E3F2FD"

  dockerfile: Dockerfile {
    shape: document
    style.fill: "#2196F3"
    style.font-color: white
  }

  buildx: Docker Buildx {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  cache: Build Cache {
    shape: cylinder
    style.fill: "#64B5F6"
    style.font-color: white
  }

  dockerfile -> buildx
  buildx -> cache
}

security: Security Phase {
  style.fill: "#FFCDD2"

  trivy: Trivy Scan {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }

  cosign: Cosign Sign {
    shape: hexagon
    style.fill: "#F44336"
    style.font-color: white
  }

  sbom: SBOM Generate {
    shape: document
    style.fill: "#EF5350"
    style.font-color: white
  }
}

registry: Registry {
  style.fill: "#E8F5E9"

  push: Push Image {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  tags: Multi-arch\nManifest {
    shape: rectangle
    style.fill: "#81C784"
    style.font-color: white
  }
}

deploy: Deploy {
  style.fill: "#FFF3E0"

  k8s: Kubernetes {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
  }

  compose: Docker\nCompose {
    shape: hexagon
    style.fill: "#FFB74D"
    style.font-color: white
  }
}

build -> security: Image Built
security -> registry: Verified
registry -> deploy: Pull & Run
```

## Getting Started

### Prerequisites

| Requirement   | Version | Installation                 |
| ------------- | ------- | ---------------------------- |
| Docker        | 24.0+   | `brew install docker`        |
| Docker Buildx | 0.12+   | Included with Docker Desktop |
| Cosign        | 2.2+    | `brew install cosign`        |
| Trivy         | 0.48+   | `brew install trivy`         |

### Installation and Authentication

```bash
# Install Docker Desktop (macOS)
brew install --cask docker

# Or install Docker Engine (Linux)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Verify installation
docker version
docker buildx version

# Login to company registry
docker login registry.company.com
# Username: your-username
# Password: your-token

# Login to public registries
docker login ghcr.io
docker login docker.io
```

## Examples

### Basic Build and Push

```bash
# Build image
docker build -t registry.company.com/apps/myapp:v1.0.0 .

# Test locally
docker run -d -p 8080:8080 --name myapp-test \
    registry.company.com/apps/myapp:v1.0.0

# Verify health
curl http://localhost:8080/health

# Stop test container
docker stop myapp-test && docker rm myapp-test

# Push to registry
docker push registry.company.com/apps/myapp:v1.0.0
```

### Multi-Architecture Build

```bash
# Create and use buildx builder
docker buildx create --name builder --driver docker-container --use

# Build and push multi-arch image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --tag registry.company.com/apps/myapp:v1.0.0 \
    --tag registry.company.com/apps/myapp:latest \
    --push \
    --cache-from type=registry,ref=registry.company.com/cache/myapp \
    --cache-to type=registry,ref=registry.company.com/cache/myapp,mode=max \
    .

# Verify multi-arch manifest
docker buildx imagetools inspect registry.company.com/apps/myapp:v1.0.0
```

### Build with Build Arguments

```bash
# Build with version info
docker build \
    --build-arg VERSION=1.0.0 \
    --build-arg COMMIT_SHA=$(git rev-parse HEAD) \
    --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    -t registry.company.com/apps/myapp:v1.0.0 \
    .
```

```dockerfile
# Dockerfile with build args
ARG VERSION=dev
ARG COMMIT_SHA=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$COMMIT_SHA \
      org.opencontainers.image.created=$BUILD_DATE
```

### Build with Secrets

```bash
# Build with mounted secrets (never baked into image)
DOCKER_BUILDKIT=1 docker build \
    --secret id=npm_token,src=$HOME/.npmrc \
    --secret id=ssh_key,src=$HOME/.ssh/id_rsa \
    -t registry.company.com/apps/myapp:v1.0.0 \
    .
```

```dockerfile
# syntax=docker/dockerfile:1.4

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./

# Use secret at build time
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    npm ci

# Use SSH for private repos
RUN --mount=type=ssh \
    git clone git@github.com:company/private-repo.git
```

### Complete CI/CD Pipeline Example

```yaml
# .github/workflows/docker-build.yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  REGISTRY: registry.company.com
  IMAGE_NAME: apps/myapp

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write # For keyless signing

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=
            type=ref,event=branch
            type=ref,event=pr

      - name: Build and Push
        uses: docker/build-push-action@v5
        id: build
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: true

      - name: Install Cosign
        if: github.event_name != 'pull_request'
        uses: sigstore/cosign-installer@v3

      - name: Sign Image
        if: github.event_name != 'pull_request'
        env:
          DIGEST: ${{ steps.build.outputs.digest }}
        run: |
          cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${DIGEST}

      - name: Scan for Vulnerabilities
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'

      - name: Upload Scan Results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

### Local Development with Docker Compose

```yaml
# docker-compose.yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: development
      args:
        - NODE_ENV=development
    image: myapp:dev
    container_name: myapp-dev
    ports:
      - '3000:3000'
      - '9229:9229' # Debug port
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    command: npm run dev

  db:
    image: postgres:16-alpine
    container_name: myapp-db
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - '5432:5432'
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U user -d myapp']
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

```bash
# Start development environment
docker compose up -d

# View logs
docker compose logs -f app

# Execute commands in container
docker compose exec app npm test

# Rebuild and restart
docker compose up -d --build

# Stop and remove
docker compose down -v
```

### Production Deployment

```yaml
# docker-compose.prod.yaml
version: '3.8'

services:
  app:
    image: registry.company.com/apps/myapp:${VERSION:-latest}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
      rollback_config:
        parallelism: 0
        order: stop-first
    ports:
      - '8080:8080'
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    healthcheck:
      test:
        [
          'CMD',
          'wget',
          '--no-verbose',
          '--tries=1',
          '--spider',
          'http://localhost:8080/health',
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    read_only: true
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
    logging:
      driver: json-file
      options:
        max-size: '100m'
        max-file: '3'
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: myapp
          image: registry.company.com/apps/myapp:v1.0.0
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
              protocol: TCP
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
          volumeMounts:
            - name: tmp
              mountPath: /tmp
          env:
            - name: NODE_ENV
              value: production
          envFrom:
            - configMapRef:
                name: myapp-config
            - secretRef:
                name: myapp-secrets
      volumes:
        - name: tmp
          emptyDir: {}
      imagePullSecrets:
        - name: registry-credentials
```

## Advanced Topics

### Build Cache Optimization

```bash
# Use registry cache
docker buildx build \
    --cache-from type=registry,ref=registry.company.com/cache/myapp:buildcache \
    --cache-to type=registry,ref=registry.company.com/cache/myapp:buildcache,mode=max \
    -t registry.company.com/apps/myapp:v1.0.0 \
    --push .

# Use local cache
docker buildx build \
    --cache-from type=local,src=/tmp/.buildx-cache \
    --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
    -t myapp:latest .
```

### Image Inspection

```bash
# View image layers
docker history registry.company.com/apps/myapp:v1.0.0

# Inspect image metadata
docker inspect registry.company.com/apps/myapp:v1.0.0

# View labels
docker inspect --format='{{json .Config.Labels}}' \
    registry.company.com/apps/myapp:v1.0.0 | jq

# Analyze image with dive
dive registry.company.com/apps/myapp:v1.0.0
```

### Image Cleanup

```bash
# Remove unused images
docker image prune -a

# Remove all stopped containers
docker container prune

# Remove unused volumes
docker volume prune

# Remove all unused data
docker system prune -a --volumes

# Remove images older than 24h
docker image prune -a --filter "until=24h"

# Remove specific images by pattern
docker images | grep 'myapp' | awk '{print $3}' | xargs docker rmi
```

### Tagging Strategy

```bash
# Tag with version
docker tag myapp:latest registry.company.com/apps/myapp:v1.2.3

# Tag with commit SHA
docker tag myapp:latest registry.company.com/apps/myapp:$(git rev-parse --short HEAD)

# Tag with branch
docker tag myapp:latest registry.company.com/apps/myapp:$(git branch --show-current)

# Tag with date
docker tag myapp:latest registry.company.com/apps/myapp:$(date +%Y%m%d)
```

## Troubleshooting

| Issue                                        | Cause                    | Solution                                              |
| -------------------------------------------- | ------------------------ | ----------------------------------------------------- |
| `Cannot connect to Docker daemon`            | Docker not running       | Start Docker Desktop or `sudo systemctl start docker` |
| `unauthorized: authentication required`      | Not logged in            | Run `docker login registry.company.com`               |
| `no space left on device`                    | Disk full                | Run `docker system prune -a`                          |
| `manifest unknown`                           | Image doesn't exist      | Check image name and tag                              |
| `failed to solve: failed to read dockerfile` | Invalid Dockerfile path  | Use `-f` flag or check filename                       |
| `COPY failed: file not found`                | File in .dockerignore    | Update .dockerignore                                  |
| `permission denied`                          | User not in docker group | `sudo usermod -aG docker $USER`                       |
| `image platform does not match`              | Architecture mismatch    | Use `--platform` flag                                 |
| `failed to fetch oauth token`                | Registry auth failed     | Re-login to registry                                  |
| Build cache not working                      | Cache not exported       | Add `--cache-to` and `--cache-from`                   |

### Debug Commands

```bash
# View Docker daemon logs
sudo journalctl -u docker.service

# Debug build process
DOCKER_BUILDKIT=1 docker build --progress=plain --no-cache .

# Check available disk space
docker system df

# Inspect running container
docker exec -it <container> sh

# View container logs
docker logs -f --tail 100 <container>

# Check container resource usage
docker stats

# Export container filesystem
docker export <container> > container.tar

# Debug networking
docker network inspect bridge
docker exec <container> ping other-container
```

## Best Practices Checklist

### Dockerfile

- [ ] Use official or company base images
- [ ] Pin specific versions (not `latest`)
- [ ] Use multi-stage builds
- [ ] Run as non-root user
- [ ] Minimize layers (combine RUN commands)
- [ ] Order commands by change frequency
- [ ] Use .dockerignore
- [ ] Set appropriate health checks
- [ ] Add OCI labels (maintainer, version, description)

### Security

- [ ] Scan images for vulnerabilities
- [ ] Sign images with Cosign
- [ ] Generate and attach SBOM
- [ ] Use read-only root filesystem
- [ ] Drop all capabilities
- [ ] No secrets in image layers
- [ ] Regular base image updates
- [ ] Use distroless/scratch for production

### CI/CD

- [ ] Automate builds on push
- [ ] Build multi-architecture images
- [ ] Use build cache
- [ ] Run tests before push
- [ ] Fail on critical vulnerabilities
- [ ] Tag with semantic versions
- [ ] Push to multiple registries (HA)

## CLI Reference

| Command                          | Description          |
| -------------------------------- | -------------------- |
| `docker build -t <tag> .`        | Build image          |
| `docker buildx build --platform` | Multi-arch build     |
| `docker push <image>`            | Push to registry     |
| `docker pull <image>`            | Pull from registry   |
| `docker run -d <image>`          | Run container        |
| `docker compose up -d`           | Start services       |
| `docker exec -it <container> sh` | Shell into container |
| `docker logs -f <container>`     | Stream logs          |
| `docker stop <container>`        | Stop container       |
| `docker rm <container>`          | Remove container     |
| `docker rmi <image>`             | Remove image         |
| `docker system prune -a`         | Clean up             |
| `docker inspect <image>`         | Show metadata        |
| `docker history <image>`         | Show layers          |
| `docker scout cves <image>`      | Scan vulnerabilities |
| `docker sbom <image>`            | Generate SBOM        |

## Related Resources

- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [BuildKit](https://docs.docker.com/build/buildkit/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Trivy Scanner](https://aquasecurity.github.io/trivy/)
- [Cosign](https://docs.sigstore.dev/cosign/overview/)

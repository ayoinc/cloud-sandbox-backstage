# Docker Images Registry

Company Docker images and base images for application development and deployment.

## Quick Start

```bash
# Login to company registry
docker login registry.company.com

# Pull base image
docker pull registry.company.com/base/node:20-alpine

# Build application image
docker build -t registry.company.com/apps/myapp:v1.0.0 .

# Push to registry
docker push registry.company.com/apps/myapp:v1.0.0

# Run container
docker run -d -p 8080:8080 registry.company.com/apps/myapp:v1.0.0

# Scan for vulnerabilities
docker scout cves registry.company.com/apps/myapp:v1.0.0
```

## Features

| Feature                | Description                                        | Status |
| ---------------------- | -------------------------------------------------- | ------ |
| Base Images            | Hardened base images for Node.js, Python, Go, Java | Active |
| Multi-Arch Support     | AMD64 and ARM64 builds                             | Active |
| Vulnerability Scanning | Automated Trivy/Grype scans                        | Active |
| Image Signing          | Cosign/Notary signature verification               | Active |
| SBOM Generation        | Software Bill of Materials with Syft               | Active |
| Cache Optimization     | BuildKit cache for faster builds                   | Active |
| Slim Images            | Distroless and Alpine variants                     | Active |
| CI/CD Integration      | GitHub Actions, GitLab CI templates                | Active |

## Architecture

```d2
direction: down

source: Source Code {
  style.fill: "#e3f2fd"
  git: Git Repository
}

dockerfile: Dockerfile {
  style.fill: "#e8f5e9"
  multistage: Multi-stage Build
}

source -> dockerfile

buildkit: BuildKit {
  style.fill: "#fff3e0"
  build: Docker Build
  buildx: buildx
}

base: Base Images {
  style.fill: "#c8e6c9"
  registry: "registry.co/base/*"
}

base -> buildkit
dockerfile -> buildkit

scan: Security Scan {
  style.fill: "#ffcdd2"
  trivy: Trivy/Grype
  sbom: SBOM Gen
}

sign: Image Sign {
  style.fill: "#e1bee7"
  cosign: Cosign
  notary: Notary
}

buildkit -> scan -> sign

registry: Container Registry {
  style.fill: "#b3e5fc"
  harbor: Harbor (On-Prem)
  ecr: ECR (AWS)
  gcr: GCR (GCP)
}

sign -> registry
```

## Available Base Images

| Image                | Tags                                | Size   | Description            |
| -------------------- | ----------------------------------- | ------ | ---------------------- |
| `base/node`          | 20-alpine, 20-slim, 18-alpine       | ~50MB  | Node.js runtime        |
| `base/python`        | 3.12-alpine, 3.12-slim, 3.11-alpine | ~45MB  | Python runtime         |
| `base/golang`        | 1.22-alpine, 1.22                   | ~300MB | Go build environment   |
| `base/java`          | 21-alpine, 21-slim, 17-alpine       | ~200MB | OpenJDK runtime        |
| `base/nginx`         | 1.25-alpine                         | ~25MB  | Nginx web server       |
| `base/rust`          | 1.75-alpine, 1.75-slim              | ~800MB | Rust build environment |
| `base/dotnet`        | 8.0-alpine, 8.0-slim                | ~100MB | .NET runtime           |
| `runtime/distroless` | static, base, cc                    | ~2MB   | Minimal runtime        |

## Image Naming Convention

```
registry.company.com/<category>/<name>:<tag>

Categories:
  base/      - Base images and runtimes
  apps/      - Application images
  tools/     - CI/CD and development tools
  infra/     - Infrastructure components

Tags:
  v1.2.3                    - Semantic version
  v1.2.3-<commit-sha>       - Version with commit
  latest                    - Latest stable (avoid in production)
  main-<commit-sha>         - Main branch builds
  pr-123-<commit-sha>       - Pull request builds
```

## Docker Commands Reference

| Command                                                  | Description                 |
| -------------------------------------------------------- | --------------------------- |
| `docker build -t <tag> .`                                | Build image from Dockerfile |
| `docker buildx build --platform linux/amd64,linux/arm64` | Multi-arch build            |
| `docker push <image>`                                    | Push to registry            |
| `docker pull <image>`                                    | Pull from registry          |
| `docker run -d <image>`                                  | Run container detached      |
| `docker compose up -d`                                   | Start services              |
| `docker scout cves <image>`                              | Scan vulnerabilities        |
| `docker history <image>`                                 | Show layer history          |
| `docker inspect <image>`                                 | Show image details          |

## Related Documentation

- [Overview](overview.md) - Dockerfile best practices, multi-stage builds, security
- [Usage](usage.md) - Building, pushing, and deploying images

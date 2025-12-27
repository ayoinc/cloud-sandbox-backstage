# ${{ values.name }}

${{ values.description }}

## Overview

This Docker application template provides a production-ready containerized service with:

- Multi-platform container builds (amd64/arm64)
- Automated CI/CD pipeline with security scanning
- Container registry integration (GitHub Container Registry)
- Health check endpoints for orchestration platforms
- Best practices for Dockerfile structure and security
- Support for multiple runtime environments (Node.js, Python, Java, Go)

```d2
direction: right

title: {
  label: Docker Container Deployment Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

developer: Developer {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

source: Source Code {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  dockerfile: Dockerfile
  app: Application
}

cicd: CI/CD Pipeline {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  build: Build {
    label: "Multi-platform\nBuild"
  }
  scan: Security Scan {
    label: "Trivy\nGrype\nHadolint"
  }
  test: Test {
    label: "Container\nTests"
  }

  build -> scan -> test
}

registry: Container Registry {
  shape: cylinder
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "ghcr.io\n${{ values.name }}"
}

orchestration: Container Orchestration {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  kubernetes: Kubernetes {
    shape: hexagon
  }
  compose: Docker Compose {
    shape: hexagon
  }
  ecs: AWS ECS {
    shape: hexagon
  }
}

runtime: Runtime Environment {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"

  container: Container {
    shape: oval
    label: "${{ values.name }}\nPort: ${{ values.port }}"
  }
  health: Health Check {
    shape: diamond
    label: "/health\n/ready"
  }

  container -> health
}

developer -> source
source -> cicd
cicd.test -> registry: push
registry -> orchestration
orchestration -> runtime
```

## Configuration Summary

| Setting              | Value                                                              |
| -------------------- | ------------------------------------------------------------------ |
| Application Name     | `${{ values.name }}`                                               |
| Base Image           | `${{ values.baseImage }}`                                          |
| Exposed Port         | `${{ values.port }}`                                               |
| Owner                | `${{ values.owner }}`                                              |
| Repository           | `${{ values.destination.owner }}/${{ values.destination.repo }}`   |
| Health Check Enabled | `${{ values.includeHealthcheck }}`                                 |
| Container Registry   | `ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}` |

---

## Multi-Platform Build Support

This template supports multiple application runtimes. The Dockerfile automatically configures the build process based on the selected base image.

### Supported Platforms

| Platform   | Base Image             | Package Manager | Entry Point          |
| ---------- | ---------------------- | --------------- | -------------------- |
| Node.js    | `node:18-alpine`       | npm             | `node index.js`      |
| Python     | `python:3.11-alpine`   | pip             | `python app.py`      |
| Java       | `openjdk:17-alpine`    | Gradle          | `java -jar app.jar`  |
| Go         | `golang:1.20-alpine`   | go modules      | `./main`             |

### Node.js Configuration

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE ${{ values.port }}
CMD ["node", "index.js"]
```

**Required files:**
- `package.json` - Dependencies and scripts
- `index.js` - Application entry point

### Python Configuration

```dockerfile
FROM python:3.11-alpine
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE ${{ values.port }}
CMD ["python", "app.py"]
```

**Required files:**
- `requirements.txt` - Python dependencies
- `app.py` - Application entry point

### Java Configuration

```dockerfile
FROM openjdk:17-alpine
WORKDIR /app
COPY . .
RUN ./gradlew build --no-daemon
EXPOSE ${{ values.port }}
CMD ["java", "-jar", "build/libs/app.jar"]
```

**Required files:**
- `build.gradle` - Gradle build configuration
- `src/` - Java source files

### Go Configuration

```dockerfile
FROM golang:1.20-alpine
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o main .
EXPOSE ${{ values.port }}
CMD ["./main"]
```

**Required files:**
- `go.mod` - Go module definition
- `main.go` - Application entry point

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline for building, testing, and deploying Docker containers.

### Pipeline Features

- **Linting**: Hadolint for Dockerfile best practices
- **Multi-platform Builds**: linux/amd64 and linux/arm64
- **Security Scanning**: Trivy and Grype vulnerability detection
- **SBOM Generation**: Software Bill of Materials in CycloneDX format
- **Container Testing**: Structure tests and health check verification
- **Multi-environment Deployment**: Staging and production workflows
- **Caching**: GitHub Actions cache for faster builds

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Hadolint\nBest Practices"
}

build: Build {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Multi-arch\nBuildx"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Trivy\nGrype\nSBOM"
}

test: Test {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Structure Tests\nHealth Check"
}

registry: Push {
  shape: cylinder
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "ghcr.io"
}

staging: Staging {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Deploy\nStaging"
}

prod: Production {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
  label: "Deploy\nProduction"
}

pr -> lint -> build
build -> security
build -> test
security -> registry
test -> registry
registry -> staging: develop branch
registry -> prod: version tag
```

### Pipeline Triggers

| Trigger                      | Actions                                        |
| ---------------------------- | ---------------------------------------------- |
| Pull Request to `main`       | Lint, Build, Security Scan, Test               |
| Push to `main`               | Lint, Build, Security Scan, Test, Push to GHCR |
| Push to `develop`            | Full pipeline + Deploy to Staging              |
| Version tag (`v*`)           | Full pipeline + Deploy to Production           |

### Image Tagging Strategy

| Tag Pattern           | Example                          | Trigger           |
| --------------------- | -------------------------------- | ----------------- |
| `latest`              | `ghcr.io/org/app:latest`         | Push to main      |
| Branch name           | `ghcr.io/org/app:develop`        | Push to branch    |
| Semantic version      | `ghcr.io/org/app:1.2.3`          | Version tag       |
| Major.Minor           | `ghcr.io/org/app:1.2`            | Version tag       |
| Branch-SHA            | `ghcr.io/org/app:main-abc1234`   | Every push        |
| PR number             | `ghcr.io/org/app:pr-42`          | Pull request      |

---

## Prerequisites

### 1. Docker Installation

Install Docker Desktop or Docker Engine on your development machine.

#### macOS

```bash
# Using Homebrew
brew install --cask docker

# Or download from https://docs.docker.com/desktop/mac/install/
```

#### Linux (Ubuntu/Debian)

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER
```

#### Windows

Download and install [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/install/).

### 2. Container Registry Access

#### GitHub Container Registry (Default)

Authentication is handled automatically via GitHub Actions using `GITHUB_TOKEN`.

For local development:

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

#### Alternative Registries

| Registry         | Login Command                                                   |
| ---------------- | --------------------------------------------------------------- |
| Docker Hub       | `docker login -u USERNAME`                                      |
| AWS ECR          | `aws ecr get-login-password \| docker login --username AWS ...` |
| Google GCR       | `gcloud auth configure-docker`                                  |
| Azure ACR        | `az acr login --name REGISTRY_NAME`                             |

### 3. GitHub Repository Setup

#### Required Permissions

The workflow requires these repository permissions (configured automatically):

| Permission       | Purpose                              |
| ---------------- | ------------------------------------ |
| `contents: read` | Checkout repository                  |
| `packages: write`| Push images to GHCR                  |
| `security-events: write` | Upload security scan results |
| `id-token: write`| OIDC authentication (optional)       |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules              | Deployment Branch    |
| ----------- | ----------------------------- | -------------------- |
| `staging`   | None (auto-deploy)            | `develop`            |
| `production`| Required reviewers            | Tags only (`v*`)     |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}.git
cd ${{ values.name }}

# Build the Docker image
docker build -t ${{ values.name }}:local .

# Run the container
docker run -d \
  --name ${{ values.name }} \
  -p ${{ values.port }}:${{ values.port }} \
  -e LOG_LEVEL=debug \
  ${{ values.name }}:local

# View logs
docker logs -f ${{ values.name }}

# Access the application
curl http://localhost:${{ values.port }}

# Stop and remove the container
docker stop ${{ values.name }} && docker rm ${{ values.name }}
```

### Docker Build Commands

```bash
# Standard build
docker build -t ${{ values.name }} .

# Build with build arguments
docker build \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=1.0.0 \
  -t ${{ values.name }}:1.0.0 .

# Multi-platform build (requires buildx)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ${{ values.name }}:latest \
  --push .

# Build with no cache
docker build --no-cache -t ${{ values.name }} .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t ${{ values.name }}:prod .
```

### Docker Run Commands

```bash
# Basic run
docker run -p ${{ values.port }}:${{ values.port }} ${{ values.name }}

# Run in detached mode
docker run -d -p ${{ values.port }}:${{ values.port }} ${{ values.name }}

# Run with environment variables
docker run -d \
  -p ${{ values.port }}:${{ values.port }} \
  -e PORT=${{ values.port }} \
  -e LOG_LEVEL=info \
  -e NODE_ENV=production \
  ${{ values.name }}

# Run with volume mount
docker run -d \
  -p ${{ values.port }}:${{ values.port }} \
  -v $(pwd)/data:/app/data \
  ${{ values.name }}

# Run with resource limits
docker run -d \
  -p ${{ values.port }}:${{ values.port }} \
  --memory=512m \
  --cpus=1 \
  ${{ values.name }}

# Run with restart policy
docker run -d \
  -p ${{ values.port }}:${{ values.port }} \
  --restart=unless-stopped \
  ${{ values.name }}
```

### Using Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Scale the application
docker-compose up -d --scale app=3

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Remove volumes
docker-compose down -v
```

### Pushing to Registry

```bash
# Tag for GitHub Container Registry
docker tag ${{ values.name }}:latest ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:latest

# Push to registry
docker push ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:latest

# Tag with version
docker tag ${{ values.name }}:latest ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:v1.0.0
docker push ghcr.io/${{ values.destination.owner }}/${{ values.destination.repo }}:v1.0.0
```

---

## Container Security Best Practices

This template follows container security best practices to minimize vulnerabilities.

### Dockerfile Security

| Practice                    | Implementation                                          |
| --------------------------- | ------------------------------------------------------- |
| Use specific base image tags| `node:18-alpine` instead of `node:latest`               |
| Run as non-root user        | `USER node` or `USER 1000`                              |
| Minimize layers             | Combine RUN commands where appropriate                  |
| Use multi-stage builds      | Separate build and runtime stages                       |
| Don't store secrets         | Use environment variables or secrets management         |
| Scan for vulnerabilities    | Trivy and Grype in CI/CD pipeline                       |

### Recommended Dockerfile Improvements

```dockerfile
# Use specific version tags
FROM ${{ values.baseImage }}

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy dependency files first (better layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

EXPOSE ${{ values.port }}

# Use exec form for proper signal handling
CMD ["node", "index.js"]
```

### Security Scanning Tools

| Tool     | Purpose                                | Integration            |
| -------- | -------------------------------------- | ---------------------- |
| Hadolint | Dockerfile linting                     | CI/CD, pre-commit      |
| Trivy    | Container vulnerability scanning       | CI/CD pipeline         |
| Grype    | SBOM-based vulnerability detection     | CI/CD pipeline         |
| Snyk     | Container and dependency scanning      | Optional integration   |
| Cosign   | Container image signing                | Supply chain security  |

### Runtime Security

```bash
# Run with read-only filesystem
docker run --read-only -v /tmp:/tmp ${{ values.name }}

# Drop all capabilities
docker run --cap-drop=ALL ${{ values.name }}

# Run with security options
docker run \
  --security-opt=no-new-privileges:true \
  --read-only \
  --cap-drop=ALL \
  ${{ values.name }}
```

---

## Health Checks

{% if values.includeHealthcheck %}
This application includes built-in health check endpoints for container orchestration platforms.
{% else %}
Consider adding health check endpoints for better container orchestration support.
{% endif %}

### Health Check Endpoints

| Endpoint   | Purpose                    | Expected Response        |
| ---------- | -------------------------- | ------------------------ |
| `/health`  | Basic health check         | `200 OK`                 |
| `/ready`   | Readiness probe            | `200 OK` when ready      |
| `/live`    | Liveness probe             | `200 OK` if alive        |
| `/metrics` | Prometheus metrics         | Metrics in text format   |

### Dockerfile Health Check

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${{ values.port }}/health || exit 1
```

### Health Check Configuration

| Parameter        | Value  | Description                                    |
| ---------------- | ------ | ---------------------------------------------- |
| `--interval`     | 30s    | Time between health checks                     |
| `--timeout`      | 3s     | Maximum time for health check to complete      |
| `--start-period` | 5s     | Grace period for container startup             |
| `--retries`      | 3      | Consecutive failures before unhealthy          |

### Kubernetes Probes

```yaml
# Kubernetes deployment configuration
livenessProbe:
  httpGet:
    path: /health
    port: ${{ values.port }}
  initialDelaySeconds: 10
  periodSeconds: 30
  timeoutSeconds: 3
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: ${{ values.port }}
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 3
  successThreshold: 1
  failureThreshold: 3
```

### Implementing Health Checks

#### Node.js

```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/ready', async (req, res) => {
  // Check database connection, cache, etc.
  const dbHealthy = await checkDatabase();
  if (dbHealthy) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});
```

#### Python (Flask)

```python
@app.route('/health')
def health():
    return jsonify(status='healthy', timestamp=datetime.utcnow().isoformat()), 200

@app.route('/ready')
def ready():
    # Check dependencies
    if check_database():
        return jsonify(status='ready'), 200
    return jsonify(status='not ready'), 503
```

---

## Troubleshooting

### Build Issues

**Error: Cannot connect to the Docker daemon**

```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Resolution:**
1. Ensure Docker is running: `sudo systemctl start docker`
2. Check Docker status: `docker info`
3. Verify socket permissions: `sudo chmod 666 /var/run/docker.sock`

---

**Error: No space left on device**

```
Error: write /var/lib/docker/...: no space left on device
```

**Resolution:**
```bash
# Remove unused images, containers, and volumes
docker system prune -af

# Remove build cache
docker builder prune -af

# Check disk usage
docker system df
```

---

**Error: failed to solve with frontend dockerfile**

```
failed to solve with frontend dockerfile.v0: failed to create LLB definition
```

**Resolution:**
1. Check Dockerfile syntax
2. Verify base image exists: `docker pull ${{ values.baseImage }}`
3. Run with `--progress=plain` for detailed output

---

### Runtime Issues

**Container exits immediately**

```bash
# Check exit code
docker inspect CONTAINER_ID --format='{{.State.ExitCode}}'

# View logs
docker logs CONTAINER_ID

# Run interactively for debugging
docker run -it ${{ values.name }} /bin/sh
```

---

**Port already in use**

```
Error: Bind for 0.0.0.0:${{ values.port }} failed: port is already allocated
```

**Resolution:**
```bash
# Find process using the port
lsof -i :${{ values.port }}

# Kill the process or use a different port
docker run -p 8081:${{ values.port }} ${{ values.name }}
```

---

**Health check failing**

```bash
# Check health status
docker inspect CONTAINER_ID --format='{{.State.Health.Status}}'

# View health check logs
docker inspect CONTAINER_ID --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Test health endpoint manually
docker exec CONTAINER_ID wget -qO- http://localhost:${{ values.port }}/health
```

---

### Registry Issues

**Error: denied: permission_denied**

```
Error: denied: permission_denied: write_package
```

**Resolution:**
1. Ensure `packages: write` permission in workflow
2. Verify authentication: `docker login ghcr.io`
3. Check package visibility settings in GitHub

---

**Error: unauthorized: authentication required**

```bash
# Re-authenticate
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Verify token has correct scopes
# Required: read:packages, write:packages, delete:packages
```

---

### CI/CD Pipeline Issues

**Security scan reporting false positives**

```yaml
# Add to .trivyignore
CVE-2023-XXXXX  # Reason for ignoring
```

**Build cache not working**

```yaml
# Verify cache configuration in workflow
cache-from: type=gha
cache-to: type=gha,mode=max
```

---

## Related Templates

| Template                                                  | Description                           |
| --------------------------------------------------------- | ------------------------------------- |
| [docker-compose](/docs/default/template/docker-compose)   | Multi-container Docker Compose setup  |
| [kubernetes-deployment](/docs/default/template/k8s-deploy)| Kubernetes deployment manifests       |
| [aws-ecs](/docs/default/template/aws-ecs)                 | AWS Elastic Container Service         |
| [aws-fargate](/docs/default/template/aws-fargate)         | AWS Fargate serverless containers     |
| [azure-container](/docs/default/template/azure-container) | Azure Container Instances             |
| [gcp-cloud-run](/docs/default/template/gcp-cloud-run)     | Google Cloud Run deployment           |
| [helm-chart](/docs/default/template/helm-chart)           | Helm chart for Kubernetes             |

---

## References

- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Buildx](https://docs.docker.com/build/buildx/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Docker Guide](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images)
- [Trivy Scanner](https://trivy.dev/)
- [Hadolint](https://github.com/hadolint/hadolint)
- [Container Security Best Practices](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [12 Factor App](https://12factor.net/)

# CI/CD Pipeline Templates

Production-ready, reusable GitHub Actions workflows for building, testing, deploying, and securing applications.

## Available Workflows

| Workflow            | Description                                         |
| ------------------- | --------------------------------------------------- |
| `build.yaml`        | Build applications (Node, Python, Go, Java)         |
| `test.yaml`         | Run tests with coverage reporting                   |
| `docker-build.yaml` | Build and push Docker images with security scanning |
| `deploy.yaml`       | Deploy to Kubernetes, ECS, or static hosting        |
| `security.yaml`     | SAST, dependency scanning, secret detection         |
| `release.yaml`      | Semantic versioning with changelog generation       |

## Quick Start

### Using in Your Repository

Create `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    uses: company/shared-workflows/.github/workflows/build.yaml@main
    with:
      language: node

  test:
    needs: build
    uses: company/shared-workflows/.github/workflows/test.yaml@main
    with:
      language: node
      coverage-threshold: 80

  security:
    uses: company/shared-workflows/.github/workflows/security.yaml@main
    with:
      language: node

  docker:
    needs: [build, test]
    uses: company/shared-workflows/.github/workflows/docker-build.yaml@main
    with:
      image-name: myapp
      push: ${{ github.ref == 'refs/heads/main' }}

  deploy:
    needs: docker
    if: github.ref == 'refs/heads/main'
    uses: company/shared-workflows/.github/workflows/deploy.yaml@main
    with:
      environment: production
      deploy-type: kubernetes
      image: ghcr.io/company/myapp:${{ github.sha }}
    secrets:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

## Workflow Details

### Build Workflow

Builds applications for Node.js, Python, Go, and Java.

**Inputs:**

- `language` (required): `node`, `python`, `go`, or `java`
- `node-version`: Node.js version (default: `20`)
- `python-version`: Python version (default: `3.12`)
- `go-version`: Go version (default: `1.22`)
- `java-version`: Java version (default: `21`)
- `build-command`: Custom build command
- `working-directory`: Working directory (default: `.`)

**Outputs:**

- `artifact-name`: Name of uploaded artifact
- `build-version`: Generated version string

### Test Workflow

Runs tests with coverage reporting and threshold checking.

**Inputs:**

- `language` (required): Programming language
- `coverage-threshold`: Minimum coverage % (default: `80`)
- `test-command`: Custom test command

**Outputs:**

- `coverage`: Code coverage percentage

### Docker Build Workflow

Builds multi-architecture Docker images with security scanning.

**Inputs:**

- `image-name` (required): Image name
- `dockerfile`: Dockerfile path (default: `Dockerfile`)
- `platforms`: Target platforms (default: `linux/amd64,linux/arm64`)
- `push`: Push to registry (default: `false`)
- `registry`: Container registry (default: `ghcr.io`)

**Outputs:**

- `image-digest`: Image digest
- `image-tags`: Generated tags

### Deploy Workflow

Deploys to Kubernetes, ECS, or static hosting.

**Inputs:**

- `environment` (required): Target environment
- `deploy-type` (required): `kubernetes`, `helm`, `ecs`, or `static`
- `image`: Docker image to deploy
- `namespace`: Kubernetes namespace
- `helm-chart`: Path to Helm chart
- `s3-bucket`: S3 bucket for static

**Secrets:**

- `KUBECONFIG`: Base64-encoded kubeconfig
- `AWS_ROLE_ARN`: AWS IAM role for OIDC

### Security Workflow

Runs comprehensive security scanning.

**Features:**

- SAST with Semgrep
- Dependency scanning (npm audit, pip-audit, govulncheck, OWASP)
- Secret detection (Gitleaks, TruffleHog)
- License compliance
- CodeQL analysis

### Release Workflow

Creates semantic version releases with changelog.

**Inputs:**

- `release-type`: `major`, `minor`, `patch`, or `auto`
- `dry-run`: Perform dry run
- `generate-changelog`: Generate changelog from commits

**Outputs:**

- `version`: Released version
- `release-url`: GitHub release URL

## Security Features

All workflows include:

- Minimal permissions (least privilege)
- OIDC authentication for cloud providers
- SARIF uploads to GitHub Security tab
- Automated vulnerability scanning
- Secret detection before commits

## Customization

### Custom Build Commands

```yaml
jobs:
  build:
    uses: company/shared-workflows/.github/workflows/build.yaml@main
    with:
      language: node
      build-command: 'npm run build:prod'
```

### Custom Test Commands

```yaml
jobs:
  test:
    uses: company/shared-workflows/.github/workflows/test.yaml@main
    with:
      language: python
      test-command: 'pytest -xvs --tb=short'
```

### Multi-Stage Docker Builds

```yaml
jobs:
  docker:
    uses: company/shared-workflows/.github/workflows/docker-build.yaml@main
    with:
      image-name: myapp
      target: production
      dockerfile: Dockerfile.prod
```

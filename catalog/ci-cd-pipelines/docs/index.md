# CI/CD Pipeline Templates

Standardized CI/CD pipeline templates for building, testing, and deploying applications across GitHub Actions, GitLab CI, and Jenkins.

## Quick Start

```yaml
# .github/workflows/ci.yaml - Copy to your repository
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    uses: company/shared-workflows/.github/workflows/build.yaml@v1
    with:
      language: node
      node-version: '20'
    secrets: inherit

  test:
    needs: build
    uses: company/shared-workflows/.github/workflows/test.yaml@v1
    secrets: inherit

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: company/shared-workflows/.github/workflows/deploy.yaml@v1
    with:
      environment: production
    secrets: inherit
```

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| Reusable Workflows | Shared GitHub Actions workflows | Active |
| GitLab CI Includes | Modular GitLab CI templates | Active |
| Jenkins Shared Libraries | Groovy shared libraries | Active |
| Multi-Language Support | Node.js, Python, Go, Java, .NET | Active |
| Security Scanning | SAST, DAST, dependency scanning | Active |
| Container Builds | Docker multi-arch builds | Active |
| Kubernetes Deploy | Helm, Kustomize, ArgoCD | Active |
| Quality Gates | SonarQube, coverage thresholds | Active |

## Architecture

```
+------------------------------------------------------------------+
|                    CI/CD PIPELINE ARCHITECTURE                    |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+    +-------------------+                   |
|  |   Source Code     |    |   Pipeline Trigger|                   |
|  |   Git Push/PR     |--->|   Webhook/Schedule|                   |
|  |                   |    |                   |                   |
|  +-------------------+    +-------------------+                   |
|                                  |                                |
|                                  v                                |
|  +--------------------------------------------------+            |
|  |              BUILD STAGE                          |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Checkout   |  | Install    |  | Compile    |  |            |
|  |  | Code       |  | Deps       |  | Build      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              TEST STAGE                           |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Unit Tests |  | Integration|  | E2E Tests  |  |            |
|  |  | Coverage   |  | Tests      |  | Playwright |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              SECURITY & QUALITY                   |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | SAST       |  | SonarQube  |  | License    |  |            |
|  |  | Scanning   |  | Analysis   |  | Check      |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              DEPLOY STAGE                         |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Build      |  | Push       |  | Deploy     |  |            |
|  |  | Image      |  | Registry   |  | K8s/Cloud  |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## Available Templates

| Template | Platform | Language | Description |
|----------|----------|----------|-------------|
| `node-ci.yaml` | GitHub Actions | Node.js | Build, test, lint Node.js apps |
| `python-ci.yaml` | GitHub Actions | Python | Build, test, lint Python apps |
| `go-ci.yaml` | GitHub Actions | Go | Build, test, lint Go apps |
| `java-ci.yaml` | GitHub Actions | Java | Build, test with Maven/Gradle |
| `docker-build.yaml` | GitHub Actions | Any | Multi-arch Docker builds |
| `helm-deploy.yaml` | GitHub Actions | Any | Helm chart deployment |
| `terraform-ci.yaml` | GitHub Actions | Terraform | Plan, apply Terraform |
| `.gitlab-ci-node.yml` | GitLab CI | Node.js | Node.js CI/CD |
| `.gitlab-ci-python.yml` | GitLab CI | Python | Python CI/CD |
| `Jenkinsfile-node` | Jenkins | Node.js | Node.js pipeline |

## Template Repository Structure

```
shared-workflows/
├── .github/
│   └── workflows/
│       ├── build.yaml           # Reusable build workflow
│       ├── test.yaml            # Reusable test workflow
│       ├── security-scan.yaml   # Security scanning
│       ├── docker-build.yaml    # Container builds
│       ├── deploy.yaml          # Deployment workflow
│       └── release.yaml         # Release automation
├── gitlab/
│   ├── templates/
│   │   ├── build.yml
│   │   ├── test.yml
│   │   ├── security.yml
│   │   └── deploy.yml
│   └── .gitlab-ci-template.yml
├── jenkins/
│   ├── vars/
│   │   ├── buildPipeline.groovy
│   │   ├── testPipeline.groovy
│   │   └── deployPipeline.groovy
│   └── Jenkinsfile-template
└── docs/
    └── README.md
```

## Pipeline Stages

| Stage | Purpose | Tools |
|-------|---------|-------|
| **Checkout** | Clone repository | Git |
| **Setup** | Install dependencies | npm/pip/go mod |
| **Lint** | Code style checks | ESLint, Black, golangci-lint |
| **Build** | Compile/transpile | tsc, webpack, go build |
| **Unit Test** | Run unit tests | Jest, pytest, go test |
| **Integration Test** | API/DB tests | Supertest, pytest |
| **E2E Test** | Browser tests | Playwright, Cypress |
| **Security Scan** | Find vulnerabilities | Trivy, Snyk, CodeQL |
| **Quality Gate** | Code quality | SonarQube |
| **Build Image** | Container build | Docker, Buildx |
| **Push Image** | Registry upload | ECR, GCR, Harbor |
| **Deploy** | Release to environment | Helm, ArgoCD, kubectl |

## Related Documentation

- [Overview](overview.md) - Workflow development, secrets, and matrix builds
- [Usage](usage.md) - Integration examples and troubleshooting

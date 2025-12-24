# Overview

## Architecture

The CI/CD Pipeline Templates provide standardized, reusable workflows across GitHub Actions, GitLab CI, and Jenkins. Templates follow security best practices, include quality gates, and support multi-environment deployments.

```d2
direction: down

templates: Shared Workflow Templates {
  style.fill: "#e3f2fd"
  company: company/shared
}

config: Repository Configuration {
  style.fill: "#e8f5e9"
  github: .github/
}

config -> templates

execution: Workflow Execution {
  style.fill: "#fff3e0"
  runner: Runner (ubuntu-24)
  secrets: Secrets (Vault)
  artifacts: Artifacts (Cache)
}

templates -> execution

environments: Environments {
  style.fill: "#fce4ec"
  dev: Dev (Auto)
  staging: Staging (Auto)
  prod: Production (Manual)

  dev -> staging -> prod
}

execution -> environments
```

## GitHub Actions Workflows

### Reusable Build Workflow

```yaml
# .github/workflows/build.yaml
name: Build

on:
  workflow_call:
    inputs:
      language:
        required: true
        type: string
        description: 'Programming language (node, python, go, java)'
      node-version:
        required: false
        type: string
        default: '20'
      python-version:
        required: false
        type: string
        default: '3.12'
      go-version:
        required: false
        type: string
        default: '1.22'
      java-version:
        required: false
        type: string
        default: '21'
      build-args:
        required: false
        type: string
        default: ''
    outputs:
      artifact-name:
        description: 'Name of the build artifact'
        value: ${{ jobs.build.outputs.artifact-name }}
      build-version:
        description: 'Build version'
        value: ${{ jobs.build.outputs.build-version }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${{ steps.build.outputs.artifact-name }}
      build-version: ${{ steps.version.outputs.version }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate version
        id: version
        run: |
          if [[ "${{ github.ref }}" == refs/tags/* ]]; then
            VERSION=${GITHUB_REF#refs/tags/}
          else
            VERSION=$(git describe --tags --always --dirty)
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      # Node.js setup
      - name: Setup Node.js
        if: inputs.language == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'

      - name: Install Node.js dependencies
        if: inputs.language == 'node'
        run: npm ci

      - name: Build Node.js
        if: inputs.language == 'node'
        run: npm run build ${{ inputs.build-args }}

      # Python setup
      - name: Setup Python
        if: inputs.language == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
          cache: 'pip'

      - name: Install Python dependencies
        if: inputs.language == 'python'
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Build Python
        if: inputs.language == 'python'
        run: python -m build ${{ inputs.build-args }}

      # Go setup
      - name: Setup Go
        if: inputs.language == 'go'
        uses: actions/setup-go@v5
        with:
          go-version: ${{ inputs.go-version }}
          cache: true

      - name: Build Go
        if: inputs.language == 'go'
        run: |
          go mod download
          go build -ldflags="-s -w -X main.version=${{ steps.version.outputs.version }}" \
            -o dist/app ./cmd/... ${{ inputs.build-args }}

      # Java setup
      - name: Setup Java
        if: inputs.language == 'java'
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ inputs.java-version }}
          cache: 'gradle'

      - name: Build Java
        if: inputs.language == 'java'
        run: ./gradlew build -x test ${{ inputs.build-args }}

      - name: Upload artifact
        id: build
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ github.sha }}
          path: |
            dist/
            build/
            target/
          retention-days: 7

      - name: Set artifact name
        run: echo "artifact-name=build-${{ github.sha }}" >> $GITHUB_OUTPUT
```

### Reusable Test Workflow

```yaml
# .github/workflows/test.yaml
name: Test

on:
  workflow_call:
    inputs:
      language:
        required: true
        type: string
      coverage-threshold:
        required: false
        type: number
        default: 80
      run-e2e:
        required: false
        type: boolean
        default: false
    secrets:
      CODECOV_TOKEN:
        required: false
      TEST_DATABASE_URL:
        required: false

jobs:
  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download build artifact
        uses: actions/download-artifact@v4
        with:
          name: build-${{ github.sha }}
        continue-on-error: true

      # Node.js tests
      - name: Setup Node.js
        if: inputs.language == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Run Node.js tests
        if: inputs.language == 'node'
        run: |
          npm ci
          npm run test:coverage
        env:
          DATABASE_URL: ${{ secrets.TEST_DATABASE_URL }}

      # Python tests
      - name: Setup Python
        if: inputs.language == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'

      - name: Run Python tests
        if: inputs.language == 'python'
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov
          pytest --cov=src --cov-report=xml --cov-fail-under=${{ inputs.coverage-threshold }}

      # Go tests
      - name: Setup Go
        if: inputs.language == 'go'
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Run Go tests
        if: inputs.language == 'go'
        run: |
          go test -v -race -coverprofile=coverage.out -covermode=atomic ./...
          go tool cover -func=coverage.out

      # Java tests
      - name: Setup Java
        if: inputs.language == 'java'
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Run Java tests
        if: inputs.language == 'java'
        run: ./gradlew test jacocoTestReport

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: false

  e2e-test:
    if: inputs.run-e2e
    runs-on: ubuntu-latest
    needs: unit-test
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Playwright
        run: |
          npm ci
          npx playwright install --with-deps

      - name: Run E2E tests
        run: npx playwright test
        env:
          BASE_URL: http://localhost:3000

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
```

### Docker Build Workflow

```yaml
# .github/workflows/docker-build.yaml
name: Docker Build

on:
  workflow_call:
    inputs:
      image-name:
        required: true
        type: string
      dockerfile:
        required: false
        type: string
        default: 'Dockerfile'
      context:
        required: false
        type: string
        default: '.'
      platforms:
        required: false
        type: string
        default: 'linux/amd64,linux/arm64'
      push:
        required: false
        type: boolean
        default: true
    secrets:
      REGISTRY_USERNAME:
        required: true
      REGISTRY_PASSWORD:
        required: true
    outputs:
      image-digest:
        description: 'Image digest'
        value: ${{ jobs.build.outputs.digest }}
      image-tags:
        description: 'Image tags'
        value: ${{ jobs.build.outputs.tags }}

env:
  REGISTRY: ghcr.io

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
      tags: ${{ steps.meta.outputs.tags }}

    permissions:
      contents: read
      packages: write
      id-token: write

    steps:
      - uses: actions/checkout@v4

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
          images: ${{ env.REGISTRY }}/${{ inputs.image-name }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=
            type=ref,event=branch
            type=ref,event=pr

      - name: Build and Push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: ${{ inputs.context }}
          file: ${{ inputs.dockerfile }}
          platforms: ${{ inputs.platforms }}
          push: ${{ inputs.push }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          sbom: true
          provenance: true

      - name: Install Cosign
        if: inputs.push
        uses: sigstore/cosign-installer@v3

      - name: Sign Image
        if: inputs.push
        run: |
          cosign sign --yes ${{ env.REGISTRY }}/${{ inputs.image-name }}@${{ steps.build.outputs.digest }}
```

### Deploy Workflow

```yaml
# .github/workflows/deploy.yaml
name: Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      image-tag:
        required: true
        type: string
      helm-chart:
        required: false
        type: string
        default: 'charts/app'
      values-file:
        required: false
        type: string
        default: ''
    secrets:
      KUBECONFIG:
        required: true
      HELM_VALUES:
        required: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3

      - name: Setup Helm
        uses: azure/setup-helm@v3

      - name: Configure kubeconfig
        run: |
          mkdir -p ~/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > ~/.kube/config
          chmod 600 ~/.kube/config

      - name: Deploy with Helm
        run: |
          helm upgrade --install app ${{ inputs.helm-chart }} \
            --namespace ${{ inputs.environment }} \
            --create-namespace \
            --set image.tag=${{ inputs.image-tag }} \
            ${{ inputs.values-file != '' && format('--values {0}', inputs.values-file) || '' }} \
            --wait \
            --timeout 10m

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/app -n ${{ inputs.environment }}
          kubectl get pods -n ${{ inputs.environment }} -l app=app
```

## GitLab CI Templates

### Base Template

```yaml
# gitlab/templates/base.yml
.base:
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: '/certs'
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: '$DOCKER_TLS_CERTDIR/client'

.node-base:
  image: node:20-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
  before_script:
    - npm ci

.python-base:
  image: python:3.12-slim
  cache:
    key:
      files:
        - requirements.txt
    paths:
      - .venv/
  before_script:
    - python -m venv .venv
    - source .venv/bin/activate
    - pip install -r requirements.txt

.go-base:
  image: golang:1.22-alpine
  cache:
    key:
      files:
        - go.sum
    paths:
      - /go/pkg/mod/
  before_script:
    - go mod download
```

### Complete GitLab CI Template

```yaml
# .gitlab-ci.yml
include:
  - project: 'company/gitlab-ci-templates'
    ref: main
    file: '/templates/base.yml'
  - project: 'company/gitlab-ci-templates'
    ref: main
    file: '/templates/security.yml'

stages:
  - build
  - test
  - security
  - package
  - deploy

variables:
  IMAGE_NAME: $CI_REGISTRY_IMAGE
  NODE_VERSION: '20'

build:
  extends: .node-base
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

test:
  extends: .node-base
  stage: test
  script:
    - npm run test:coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

lint:
  extends: .node-base
  stage: test
  script:
    - npm run lint

security-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy fs --exit-code 1 --severity HIGH,CRITICAL .
  allow_failure: true

build-image:
  stage: package
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_NAME:$CI_COMMIT_SHA .
    - docker push $IMAGE_NAME:$CI_COMMIT_SHA
  only:
    - main
    - tags

deploy-staging:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/app app=$IMAGE_NAME:$CI_COMMIT_SHA -n staging
    - kubectl rollout status deployment/app -n staging
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - main

deploy-production:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/app app=$IMAGE_NAME:$CI_COMMIT_SHA -n production
    - kubectl rollout status deployment/app -n production
  environment:
    name: production
    url: https://example.com
  only:
    - tags
  when: manual
```

## Jenkins Shared Library

### Pipeline DSL

```groovy
// vars/buildPipeline.groovy
def call(Map config = [:]) {
    def language = config.language ?: 'node'
    def nodeVersion = config.nodeVersion ?: '20'
    def dockerImage = config.dockerImage ?: ''

    pipeline {
        agent {
            kubernetes {
                yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: builder
    image: node:${nodeVersion}
    command: ['sleep']
    args: ['infinity']
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
"""
            }
        }

        environment {
            REGISTRY = credentials('docker-registry')
        }

        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }

            stage('Build') {
                steps {
                    container('builder') {
                        script {
                            if (language == 'node') {
                                sh 'npm ci'
                                sh 'npm run build'
                            } else if (language == 'python') {
                                sh 'pip install -r requirements.txt'
                                sh 'python -m build'
                            }
                        }
                    }
                }
            }

            stage('Test') {
                steps {
                    container('builder') {
                        script {
                            if (language == 'node') {
                                sh 'npm run test:coverage'
                            } else if (language == 'python') {
                                sh 'pytest --cov=src'
                            }
                        }
                    }
                }
                post {
                    always {
                        publishHTML([
                            reportDir: 'coverage',
                            reportFiles: 'index.html',
                            reportName: 'Coverage Report'
                        ])
                    }
                }
            }

            stage('Build Image') {
                when {
                    branch 'main'
                }
                steps {
                    container('docker') {
                        sh """
                            docker build -t ${dockerImage}:${env.BUILD_NUMBER} .
                            docker push ${dockerImage}:${env.BUILD_NUMBER}
                        """
                    }
                }
            }

            stage('Deploy') {
                when {
                    branch 'main'
                }
                steps {
                    container('builder') {
                        sh """
                            kubectl set image deployment/app app=${dockerImage}:${env.BUILD_NUMBER}
                            kubectl rollout status deployment/app
                        """
                    }
                }
            }
        }

        post {
            always {
                cleanWs()
            }
            failure {
                slackSend(
                    color: 'danger',
                    message: "Build failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
                )
            }
        }
    }
}
```

## Security Scanning Integration

### CodeQL Analysis

```yaml
# .github/workflows/codeql.yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'

jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      actions: read
      contents: read

    strategy:
      fail-fast: false
      matrix:
        language: ['javascript', 'python']

    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
```

## Related Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [GitHub Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

# Usage Guide

## Getting Started

### Prerequisites

| Requirement | Version | Installation |
|-------------|---------|--------------|
| Helm | 3.14+ | `brew install helm` |
| kubectl | 1.28+ | `brew install kubectl` |
| Kubernetes | 1.25+ | Local: Docker Desktop/minikube |

### Installation

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
# version.BuildInfo{Version:"v3.14.0", ...}

# Add chart repository
helm repo add company-charts https://charts.company.com
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# List available charts
helm search repo company-charts
```

## Examples

### Basic Web Application Deployment

```bash
# Create namespace
kubectl create namespace myapp

# Install with default values
helm install myapp company-charts/webapp \
  --namespace myapp

# Install with custom values file
helm install myapp company-charts/webapp \
  --namespace myapp \
  --values values-prod.yaml

# Install with inline value overrides
helm install myapp company-charts/webapp \
  --namespace myapp \
  --set image.repository=company/myapp \
  --set image.tag=v1.2.3 \
  --set replicaCount=3 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=myapp.example.com
```

### Production Values File

```yaml
# values-prod.yaml
replicaCount: 3

image:
  repository: company/myapp
  tag: "v1.2.3"
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: company-registry

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

podDisruptionBudget:
  enabled: true
  minAvailable: 2

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

env:
  - name: NODE_ENV
    value: production
  - name: LOG_LEVEL
    value: info

envFrom:
  - secretRef:
      name: myapp-secrets
  - configMapRef:
      name: myapp-config

livenessProbe:
  httpGet:
    path: /health/live
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: webapp
          topologyKey: kubernetes.io/hostname

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: webapp

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

### Multi-Environment Setup

```bash
# Directory structure
helm-values/
├── base/
│   └── values.yaml          # Shared configuration
├── dev/
│   └── values.yaml          # Dev overrides
├── staging/
│   └── values.yaml          # Staging overrides
└── prod/
    └── values.yaml          # Production overrides
```

```yaml
# helm-values/base/values.yaml
replicaCount: 1

image:
  repository: company/myapp
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

```yaml
# helm-values/dev/values.yaml
image:
  tag: "latest"

env:
  - name: NODE_ENV
    value: development
  - name: DEBUG
    value: "true"

ingress:
  enabled: true
  hosts:
    - host: myapp.dev.example.com
      paths:
        - path: /
          pathType: Prefix
```

```yaml
# helm-values/prod/values.yaml
replicaCount: 5

image:
  tag: "v1.2.3"

autoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 50

podDisruptionBudget:
  enabled: true
  minAvailable: 3

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

```bash
# Deploy to environments
helm upgrade --install myapp company-charts/webapp \
  --namespace dev \
  --values helm-values/base/values.yaml \
  --values helm-values/dev/values.yaml

helm upgrade --install myapp company-charts/webapp \
  --namespace prod \
  --values helm-values/base/values.yaml \
  --values helm-values/prod/values.yaml
```

### API Service with Database

```yaml
# values-api.yaml
replicaCount: 3

image:
  repository: company/api-service
  tag: "v2.0.0"

service:
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
  hosts:
    - host: api.example.com
      paths:
        - path: /v1
          pathType: Prefix
        - path: /v2
          pathType: Prefix

env:
  - name: PORT
    value: "3000"
  - name: DATABASE_HOST
    value: "$(RELEASE_NAME)-postgresql"
  - name: REDIS_HOST
    value: "$(RELEASE_NAME)-redis-master"

envFrom:
  - secretRef:
      name: api-secrets

# Enable PostgreSQL subchart
postgresql:
  enabled: true
  auth:
    database: apidb
    username: api
    existingSecret: api-db-secret
  primary:
    persistence:
      size: 50Gi
    resources:
      requests:
        cpu: 250m
        memory: 256Mi
      limits:
        cpu: 2000m
        memory: 2Gi

# Enable Redis subchart
redis:
  enabled: true
  architecture: replication
  auth:
    existingSecret: api-redis-secret
  master:
    persistence:
      size: 10Gi
  replica:
    replicaCount: 2
    persistence:
      size: 10Gi
```

```bash
# Install with dependencies
helm dependency update charts/api-service

helm install api company-charts/api-service \
  --namespace api \
  --create-namespace \
  --values values-api.yaml \
  --wait
```

### Background Worker Deployment

```yaml
# values-worker.yaml
replicaCount: 5

image:
  repository: company/worker
  tag: "v1.5.0"

# No service needed for workers
service:
  enabled: false

# No ingress needed
ingress:
  enabled: false

# Worker-specific command
command:
  - "/app/worker"
args:
  - "--queue=default,high,low"
  - "--concurrency=10"

env:
  - name: REDIS_URL
    valueFrom:
      secretKeyRef:
        name: worker-secrets
        key: redis-url
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: worker-secrets
        key: database-url

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi

# Scale based on queue depth (KEDA)
autoscaling:
  enabled: false
  
kedaScaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 50
  triggers:
    - type: redis
      metadata:
        address: redis-master:6379
        listName: job_queue
        listLength: "10"

# Graceful shutdown for long-running jobs
terminationGracePeriodSeconds: 300

lifecycle:
  preStop:
    exec:
      command:
        - /bin/sh
        - -c
        - "kill -TERM 1 && sleep 30"
```

### CronJob Deployment

```yaml
# values-cronjob.yaml
schedule: "0 2 * * *"  # Daily at 2 AM

image:
  repository: company/batch-processor
  tag: "v1.0.0"

command:
  - "/app/process.sh"

env:
  - name: BATCH_SIZE
    value: "1000"
  - name: DRY_RUN
    value: "false"

envFrom:
  - secretRef:
      name: batch-secrets

resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 4000m
    memory: 4Gi

# Job configuration
concurrencyPolicy: Forbid
successfulJobsHistoryLimit: 3
failedJobsHistoryLimit: 5
startingDeadlineSeconds: 600

# Pod configuration
restartPolicy: OnFailure
backoffLimit: 3
activeDeadlineSeconds: 7200  # 2 hours max
```

## GitOps Integration

### ArgoCD Application

```yaml
# argocd/myapp.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/company/helm-values
    targetRevision: main
    path: apps/myapp
    helm:
      releaseName: myapp
      valueFiles:
        - values.yaml
        - values-prod.yaml
      parameters:
        - name: image.tag
          value: "v1.2.3"
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Flux HelmRelease

```yaml
# flux/myapp.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: myapp
  namespace: myapp
spec:
  interval: 5m
  chart:
    spec:
      chart: webapp
      version: "2.5.x"
      sourceRef:
        kind: HelmRepository
        name: company-charts
        namespace: flux-system
  releaseName: myapp
  targetNamespace: myapp
  values:
    replicaCount: 3
    image:
      repository: company/myapp
      tag: "v1.2.3"
  valuesFrom:
    - kind: ConfigMap
      name: myapp-values
      valuesKey: values.yaml
    - kind: Secret
      name: myapp-secrets
      valuesKey: secrets.yaml
  upgrade:
    remediation:
      retries: 3
  rollback:
    timeout: 5m
    recreate: true
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/helm-release.yaml
name: Helm Chart Release

on:
  push:
    paths:
      - 'charts/**'
    branches:
      - main

jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: azure/setup-helm@v3
        with:
          version: v3.14.0

      - name: Lint charts
        run: |
          helm lint charts/*

      - name: Run chart-testing
        uses: helm/chart-testing-action@v2.6.1

      - name: Run chart-testing (lint)
        run: ct lint --config .ct.yaml

      - name: Create kind cluster
        uses: helm/kind-action@v1.8.0

      - name: Run chart-testing (install)
        run: ct install --config .ct.yaml

  release:
    needs: lint-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.name "$GITHUB_ACTOR"
          git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Run chart-releaser
        uses: helm/chart-releaser-action@v1.6.0
        env:
          CR_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test
  - package
  - publish

variables:
  HELM_VERSION: "3.14.0"

.helm-setup:
  before_script:
    - curl https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar xz
    - mv linux-amd64/helm /usr/local/bin/helm
    - helm repo add bitnami https://charts.bitnami.com/bitnami

lint:
  stage: lint
  extends: .helm-setup
  script:
    - helm lint charts/*
    - helm template charts/webapp --values charts/webapp/ci/test-values.yaml

test:
  stage: test
  extends: .helm-setup
  services:
    - name: registry.gitlab.com/gitlab-org/cluster-integration/test-utils/k3s-gitlab-ci/releases/v1.26.0-k3s1
      alias: k3s
  script:
    - export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    - helm install test-release charts/webapp --values charts/webapp/ci/test-values.yaml --wait
    - helm test test-release

package:
  stage: package
  extends: .helm-setup
  script:
    - helm package charts/*
  artifacts:
    paths:
      - "*.tgz"

publish:
  stage: publish
  extends: .helm-setup
  script:
    - helm registry login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - for chart in *.tgz; do helm push $chart oci://$CI_REGISTRY/charts; done
  only:
    - main
```

## Upgrade and Rollback

### Upgrade Strategies

```bash
# Upgrade with new values
helm upgrade myapp company-charts/webapp \
  --namespace myapp \
  --values values-prod.yaml \
  --set image.tag=v1.3.0

# Upgrade keeping existing values
helm upgrade myapp company-charts/webapp \
  --namespace myapp \
  --reuse-values \
  --set image.tag=v1.3.0

# Upgrade with atomic (rollback on failure)
helm upgrade myapp company-charts/webapp \
  --namespace myapp \
  --atomic \
  --timeout 10m \
  --values values-prod.yaml

# Dry run to preview changes
helm upgrade myapp company-charts/webapp \
  --namespace myapp \
  --dry-run \
  --debug \
  --values values-prod.yaml
```

### Rollback Operations

```bash
# View release history
helm history myapp --namespace myapp

# Rollback to previous revision
helm rollback myapp --namespace myapp

# Rollback to specific revision
helm rollback myapp 3 --namespace myapp

# Rollback with wait
helm rollback myapp 3 --namespace myapp --wait --timeout 5m
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `Error: INSTALLATION FAILED: cannot re-use a name that is still in use` | Release already exists | Use `helm upgrade --install` or uninstall first |
| `Error: rendered manifests contain a resource that already exists` | Resource exists outside Helm | Delete resource or use `--force` |
| `Error: UPGRADE FAILED: another operation is in progress` | Previous operation failed | Run `helm rollback` or delete secret |
| `Error: timed out waiting for the condition` | Pods not becoming ready | Check pod logs and events |
| `Error: chart requires kubeVersion: >=1.25.0` | Kubernetes version mismatch | Upgrade cluster or use older chart |
| `Error: failed to download` | Repository not accessible | Run `helm repo update` |
| `Warning: Kubernetes configuration file is group-readable` | Insecure kubeconfig | `chmod 600 ~/.kube/config` |
| Template rendering errors | Invalid values or templates | Use `helm template --debug` |

### Debug Commands

```bash
# View generated manifests
helm template myapp company-charts/webapp \
  --namespace myapp \
  --values values-prod.yaml \
  --debug

# Get release information
helm get all myapp --namespace myapp
helm get values myapp --namespace myapp
helm get manifest myapp --namespace myapp
helm get hooks myapp --namespace myapp

# Check release status
helm status myapp --namespace myapp

# View release history
helm history myapp --namespace myapp

# List all releases
helm list --all-namespaces
helm list --pending --failed --superseded

# Force delete stuck release
kubectl delete secret -l owner=helm,name=myapp -n myapp
```

### Common Fixes

```bash
# Fix pending-install status
helm rollback myapp 0 --namespace myapp

# Force upgrade with potential downtime
helm upgrade myapp company-charts/webapp \
  --namespace myapp \
  --force \
  --values values-prod.yaml

# Clean uninstall including PVCs
helm uninstall myapp --namespace myapp
kubectl delete pvc -l app.kubernetes.io/instance=myapp -n myapp

# Reset failed release
kubectl delete secret sh.helm.release.v1.myapp.v1 -n myapp
helm install myapp company-charts/webapp --namespace myapp
```

## Best Practices

### Version Pinning

```yaml
# Always pin chart versions
dependencies:
  - name: postgresql
    version: "14.0.5"  # Specific version, not 14.x.x
    repository: "https://charts.bitnami.com/bitnami"
```

### Secrets Management

```bash
# Use external secrets (don't store in values)
kubectl create secret generic app-secrets \
  --from-literal=database-password=secret \
  --from-literal=api-key=key123 \
  -n myapp

# Reference in values
envFrom:
  - secretRef:
      name: app-secrets

# Use sealed-secrets or external-secrets-operator
```

### Resource Quotas

```yaml
# Always set resources
resources:
  requests:
    cpu: 100m      # Minimum guaranteed
    memory: 128Mi
  limits:
    cpu: 500m      # Maximum allowed
    memory: 512Mi
```

### Health Checks

```yaml
# Configure appropriate probes
livenessProbe:
  httpGet:
    path: /health/live
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3

# Optional: startup probe for slow-starting apps
startupProbe:
  httpGet:
    path: /health/started
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 30
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `helm create <name>` | Create new chart scaffold |
| `helm dependency update` | Update chart dependencies |
| `helm package <chart>` | Package chart into archive |
| `helm lint <chart>` | Lint chart for issues |
| `helm template <chart>` | Render templates locally |
| `helm install <name> <chart>` | Install chart |
| `helm upgrade <name> <chart>` | Upgrade release |
| `helm upgrade --install` | Install or upgrade |
| `helm rollback <name> [rev]` | Rollback release |
| `helm uninstall <name>` | Delete release |
| `helm list` | List releases |
| `helm history <name>` | Show release history |
| `helm get values <name>` | Get deployed values |
| `helm get manifest <name>` | Get deployed manifests |
| `helm repo add <name> <url>` | Add repository |
| `helm repo update` | Update repositories |
| `helm search repo <keyword>` | Search charts |
| `helm show values <chart>` | Show default values |
| `helm diff upgrade` | Show upgrade diff (plugin) |

## Related Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Hub](https://artifacthub.io/)
- [Chart Testing](https://github.com/helm/chart-testing)
- [Helm Secrets Plugin](https://github.com/jkroepke/helm-secrets)

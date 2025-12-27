# ${{ values.name }}

${{ values.description }}

## Overview

A production-ready Kubernetes microservice built with **${{ values.language }}**, featuring:

- Container deployment with multi-stage Dockerfile builds
- Horizontal Pod Autoscaling (HPA) for automatic scaling
- Pod Disruption Budget (PDB) for high availability
- Ingress with TLS termination and rate limiting
- Network policies for secure pod-to-pod communication
- Prometheus metrics and distributed tracing support
- CI/CD pipeline with security scanning

```d2
direction: right

title: {
  label: Kubernetes Microservice Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

cluster: Kubernetes Cluster {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  ingress: Ingress Controller {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "NGINX Ingress\nTLS Termination\nRate Limiting"
  }

  namespace: ${{ values.kubernetes_namespace }} Namespace {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"

    service: Service {
      shape: hexagon
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
      label: "ClusterIP\nPort 80"
    }

    deployment: Deployment {
      style.fill: "#FFECB3"
      style.stroke: "#FFA000"

      pod1: Pod 1 {
        style.fill: "#E1F5FE"
        style.stroke: "#0288D1"
      }
      pod2: Pod 2 {
        style.fill: "#E1F5FE"
        style.stroke: "#0288D1"
      }
      pod3: Pod 3 {
        style.fill: "#E1F5FE"
        style.stroke: "#0288D1"
      }
    }

    hpa: HPA {
      shape: diamond
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
      label: "Auto Scaling\n3-10 replicas"
    }

    pdb: PDB {
      shape: diamond
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
      label: "Min Available: 2"
    }

    configmap: ConfigMap {
      shape: cylinder
      style.fill: "#E0E0E0"
      style.stroke: "#616161"
    }

    secret: Secret {
      shape: cylinder
      style.fill: "#FFCDD2"
      style.stroke: "#D32F2F"
    }

    service -> deployment
    hpa -> deployment: scales
    pdb -> deployment: protects
    configmap -> deployment: mounts
    secret -> deployment: injects
  }

  ingress -> namespace.service

  netpol: Network Policy {
    shape: document
    style.fill: "#FFCDD2"
    style.stroke: "#D32F2F"
    label: "Ingress/Egress\nRules"
  }

  netpol -> namespace: enforces
}

internet -> cluster.ingress

monitoring: Observability {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  prometheus: Prometheus {
    shape: cylinder
  }
  jaeger: Jaeger {
    shape: cylinder
  }
}

cluster.namespace.deployment -> monitoring: metrics/traces
```

---

## Configuration Summary

| Setting | Value |
| ------- | ----- |
| Service Name | `${{ values.name }}` |
| Language | `${{ values.language }}` |
| Namespace | `${{ values.kubernetes_namespace }}` |
| Deployment Strategy | `${{ values.deployment_strategy }}` |
| Replicas | 3 (min) - 10 (max) |
| Cloud Provider | `${{ values.cloud_provider }}` |
| Architecture | `${{ values.architecture_type }}` |
| Owner | `${{ values.owner }}` |

---

## Language-Specific Configuration

### Runtime Ports

| Language | Application Port | Metrics Port |
| -------- | ---------------- | ------------ |
| Node.js | 3000 | 9090 |
| Python | 8000 | 9090 |
| Java | 8080 | 8081 |
| Go | 8080 | 9090 |
| .NET | 5000 | 9090 |

{% if values.language == 'nodejs' %}
### Node.js Specifics

- **Runtime**: Node.js 18 Alpine
- **Package Manager**: npm (with lockfile)
- **Build**: `npm run build`
- **Entry Point**: `dist/index.js`
- **Test Framework**: Jest with coverage

```bash
# Local development
npm install
npm run dev

# Production build
npm run build
npm start

# Testing
npm run test:coverage
npm run lint
```
{% elif values.language == 'python' %}
### Python Specifics

- **Runtime**: Python 3.11 slim
- **Framework**: FastAPI with uvicorn
- **Entry Point**: `main:app`
- **Test Framework**: pytest with coverage

```bash
# Local development
pip install -r requirements.txt -r requirements-dev.txt
uvicorn main:app --reload

# Testing
pytest --cov=app --cov-report=xml
flake8 . && black --check . && isort --check-only .
```
{% elif values.language == 'java' %}
### Java Specifics

- **Runtime**: OpenJDK 17
- **Build Tool**: Maven
- **Framework**: Spring Boot
- **Entry Point**: JAR execution

```bash
# Local development
mvn spring-boot:run

# Production build
mvn clean package -DskipTests

# Testing
mvn clean test jacoco:report
mvn spotless:check
```
{% elif values.language == 'golang' %}
### Go Specifics

- **Runtime**: Go 1.21 Alpine
- **Build**: Static binary (CGO disabled)
- **Entry Point**: `./main`
- **Test Framework**: Go testing with race detection

```bash
# Local development
go run .

# Production build
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Testing
go test -v -race -coverprofile=coverage.out ./...
golangci-lint run
```
{% elif values.language == 'dotnet' %}
### .NET Specifics

- **Runtime**: .NET 7.0
- **Build Tool**: dotnet CLI
- **Entry Point**: `${{ values.name }}.dll`
- **Test Framework**: xUnit with coverage

```bash
# Local development
dotnet run

# Production build
dotnet publish -c Release -o out

# Testing
dotnet test --verbosity normal --collect:"XPlat Code Coverage"
```
{% endif %}

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with multi-stage workflows:

- **Lint and Test**: Code quality checks and unit tests
- **Security Scanning**: Trivy, Snyk, and OWASP dependency scanning
- **Build and Push**: Multi-architecture container builds
- **Deployment**: Staged rollout to staging and production
- **Performance Testing**: K6 load testing post-deployment

### Pipeline Workflow

```d2
direction: right

title: {
  label: CI/CD Pipeline Flow
  near: top-center
  shape: text
  style.font-size: 20
  style.bold: true
}

trigger: Git Push {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint & Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Linting\nUnit Tests\nCoverage"
}

security: Security Scan {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Trivy\nSnyk\nOWASP"
}

build: Build & Push {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Docker Build\nMulti-arch\nGHCR Push"
}

staging: Deploy Staging {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Kubernetes\nSmoke Tests"
}

approval: Approval {
  shape: diamond
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Manual\nReview"
}

production: Deploy Production {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "${{ values.deployment_strategy }}\nDeployment"
}

perf: Performance Test {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "K6 Load\nTesting"
}

trigger -> lint -> security -> build -> staging -> approval -> production -> perf
```

### Deployment Strategies

| Strategy | Description | Use Case |
| -------- | ----------- | -------- |
| `rolling-update` | Gradual pod replacement with zero downtime | Default, most workloads |
| `blue-green` | Full environment switch with instant rollback | Critical services |
| `canary` | Progressive traffic shifting (10% -> 100%) | Risk-sensitive deployments |

---

## Prerequisites

### 1. Container Registry Access

Configure access to GitHub Container Registry (GHCR):

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Or for other registries
docker login <registry-url>
```

#### Required Secrets

Configure in **Settings > Secrets and variables > Actions**:

| Secret | Description | Required |
| ------ | ----------- | -------- |
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions | Yes |
{% if values.cloud_provider == 'aws' %}
| `AWS_ACCESS_KEY_ID` | AWS access key for EKS | Yes |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | Yes |
{% elif values.cloud_provider == 'azure' %}
| `AZURE_CREDENTIALS` | Azure service principal JSON | Yes |
{% elif values.cloud_provider == 'gcp' %}
| `GCP_SA_KEY` | GCP service account key | Yes |
| `GCP_PROJECT_ID` | GCP project identifier | Yes |
{% endif %}
| `SNYK_TOKEN` | Snyk API token for security scanning | Optional |
| `SONAR_TOKEN` | SonarQube token for code quality | Optional |
| `K6_CLOUD_TOKEN` | K6 cloud token for performance tests | Optional |
| `BACKSTAGE_TOKEN` | Backstage API token for deployment tracking | Optional |

### 2. Kubernetes Cluster Access

{% if values.cloud_provider == 'aws' %}
#### AWS EKS Setup

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Configure credentials
aws configure

# Update kubeconfig for EKS
aws eks update-kubeconfig --region us-west-2 --name <cluster-name>

# Verify access
kubectl get nodes
```
{% elif values.cloud_provider == 'azure' %}
#### Azure AKS Setup

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Get AKS credentials
az aks get-credentials --resource-group <resource-group> --name <cluster-name>

# Verify access
kubectl get nodes
```
{% elif values.cloud_provider == 'gcp' %}
#### Google GKE Setup

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash

# Authenticate
gcloud auth login
gcloud config set project <project-id>

# Get GKE credentials
gcloud container clusters get-credentials <cluster-name> --zone <zone>

# Verify access
kubectl get nodes
```
{% endif %}

### 3. Namespace Setup

```bash
# Create the namespace
kubectl create namespace ${{ values.kubernetes_namespace }}

# Apply resource quotas (optional)
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ${{ values.name }}-quota
  namespace: ${{ values.kubernetes_namespace }}
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
EOF
```

---

## Usage

### Local Development

```bash
# Clone the repository
git clone https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}
cd ${{ values.destination.repo }}

# Build the Docker image locally
docker build -t ${{ values.name }}:local .

# Run locally with Docker
docker run -p {% if values.language == 'nodejs' %}3000:3000{% elif values.language == 'python' %}8000:8000{% elif values.language == 'java' %}8080:8080{% elif values.language == 'golang' %}8080:8080{% elif values.language == 'dotnet' %}5000:5000{% endif %} \
  -e LOG_LEVEL=debug \
  -e SERVICE_NAME=${{ values.name }} \
  ${{ values.name }}:local

# Test health endpoint
curl http://localhost:{% if values.language == 'nodejs' %}3000{% elif values.language == 'python' %}8000{% elif values.language == 'java' %}8080{% elif values.language == 'golang' %}8080{% elif values.language == 'dotnet' %}5000{% endif %}/health
```

### Kubernetes Deployment

#### Deploy All Resources

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Verify deployment
kubectl get all -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }}

# Check pod status
kubectl get pods -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }} -w
```

#### Manual Image Update

```bash
# Update deployment image
kubectl set image deployment/${{ values.name }} \
  ${{ values.name }}=ghcr.io/${{ values.destination.owner }}/${{ values.name }}:latest \
  -n ${{ values.kubernetes_namespace }}

# Watch rollout status
kubectl rollout status deployment/${{ values.name }} -n ${{ values.kubernetes_namespace }}

# Rollback if needed
kubectl rollout undo deployment/${{ values.name }} -n ${{ values.kubernetes_namespace }}
```

#### Scaling

```bash
# Manual scaling
kubectl scale deployment/${{ values.name }} --replicas=5 -n ${{ values.kubernetes_namespace }}

# Check HPA status
kubectl get hpa ${{ values.name }}-hpa -n ${{ values.kubernetes_namespace }}

# Describe HPA for detailed metrics
kubectl describe hpa ${{ values.name }}-hpa -n ${{ values.kubernetes_namespace }}
```

### Running the Pipeline

#### Automatic Triggers

| Trigger | Branch | Actions |
| ------- | ------ | ------- |
| Pull Request | `main` | Lint, Test, Security Scan |
| Push | `develop` | Full pipeline, Deploy to Staging |
| Push | `main` | Full pipeline, Deploy to Production |

#### Manual Deployment

1. Navigate to **Actions** tab in GitHub
2. Select **CI/CD Pipeline** workflow
3. Click **Run workflow**
4. Select target branch and environment
5. Monitor deployment progress

---

## Security Scanning

The pipeline includes comprehensive security scanning at multiple stages:

| Tool | Stage | Purpose | Documentation |
| ---- | ----- | ------- | ------------- |
| **Trivy** | CI | Container and filesystem vulnerability scanning | [trivy.dev](https://trivy.dev) |
| **Snyk** | CI | Dependency vulnerability detection | [snyk.io](https://snyk.io) |
| **OWASP Dependency Check** | CI | Known CVE detection in dependencies | [owasp.org](https://owasp.org/www-project-dependency-check/) |
{% if values.enable_code_quality %}
| **SonarQube** | CI | Code quality and security hotspots | [sonarqube.org](https://www.sonarqube.org) |
{% endif %}
| **ModSecurity** | Runtime | WAF rules on Ingress | [modsecurity.org](https://modsecurity.org) |

### Container Security Features

- **Non-root user**: Containers run as UID 1001
- **Read-only filesystem**: Root filesystem is read-only
- **Dropped capabilities**: All Linux capabilities dropped
- **Seccomp profile**: RuntimeDefault seccomp enabled
- **No privilege escalation**: `allowPrivilegeEscalation: false`

### Network Security

```yaml
# Network Policy enforces:
- Ingress only from nginx-ingress namespace
- Egress only to DNS (port 53) and HTTPS (port 443)
{% if values.database_type !== 'none' %}
- Database access on port {% if values.database_type == 'postgresql' %}5432{% elif values.database_type == 'mysql' %}3306{% elif values.database_type == 'mongodb' %}27017{% elif values.database_type == 'redis' %}6379{% endif %}
{% endif %}
{% if values.message_queue !== 'none' %}
- Message queue access on port {% if values.message_queue == 'rabbitmq' %}5672{% elif values.message_queue == 'kafka' %}9092{% elif values.message_queue == 'redis-pub-sub' %}6379{% endif %}
{% endif %}
```

### Viewing Security Results

Security scan results are uploaded to GitHub Security tab as SARIF reports:

1. Go to **Security** tab in repository
2. Select **Code scanning alerts**
3. Filter by tool (Trivy, Snyk, etc.)
4. Review and remediate findings

---

## Observability

### Metrics

{% if values.monitoring_stack == 'prometheus-grafana' %}
Prometheus metrics are exposed at `/metrics` endpoint:

| Metric | Type | Description |
| ------ | ---- | ----------- |
| `http_requests_total` | Counter | Total HTTP requests |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `http_requests_in_flight` | Gauge | Current in-flight requests |
| `process_cpu_seconds_total` | Counter | CPU time consumed |
| `process_resident_memory_bytes` | Gauge | Memory usage |

#### Prometheus Scrape Configuration

```yaml
scrape_configs:
  - job_name: '${{ values.name }}'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: ${{ values.name }}
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

#### Grafana Dashboard

Access the pre-configured dashboard at:
`https://grafana.company.com/d/${{ values.name }}`
{% else %}
Configure your monitoring stack to scrape the `/metrics` endpoint on port 9090.
{% endif %}

### Logging

Structured JSON logging with the following fields:

| Field | Description |
| ----- | ----------- |
| `timestamp` | ISO 8601 timestamp |
| `level` | Log level (debug, info, warn, error) |
| `message` | Log message |
| `service` | Service name (`${{ values.name }}`) |
| `version` | Application version |
| `trace_id` | Distributed trace ID |
| `span_id` | Current span ID |

#### Log Aggregation

```bash
# View logs with kubectl
kubectl logs -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }} -f

# View logs with stern (recommended)
stern -n ${{ values.kubernetes_namespace }} ${{ values.name }}

# Filter by log level
kubectl logs -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }} | jq 'select(.level == "error")'
```

### Distributed Tracing

{% if values.enable_tracing %}
OpenTelemetry tracing is enabled with Jaeger backend:

- **Service Name**: `${{ values.name }}`
- **Jaeger Endpoint**: `http://jaeger-collector:14268/api/traces`
- **Trace Propagation**: W3C Trace Context

#### Viewing Traces

Access Jaeger UI at:
`https://jaeger.company.com/search?service=${{ values.name }}`

#### Trace Context Headers

| Header | Description |
| ------ | ----------- |
| `traceparent` | W3C trace context propagation |
| `tracestate` | Vendor-specific trace state |
| `x-request-id` | Request correlation ID |
{% else %}
Enable tracing by setting `enable_tracing: true` in template parameters.
{% endif %}

---

## Health Checks

The application exposes three health endpoints:

| Endpoint | Purpose | Probe Type |
| -------- | ------- | ---------- |
| `/health` | Liveness check | `livenessProbe` |
| `/ready` | Readiness check | `readinessProbe` |
| `/metrics` | Prometheus metrics | Scrape target |

### Probe Configuration

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 30
```

---

## Troubleshooting

### Pod Not Starting

**Error: ImagePullBackOff**

```bash
# Check pod events
kubectl describe pod -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }}

# Verify image exists
docker pull ghcr.io/${{ values.destination.owner }}/${{ values.name }}:latest

# Check image pull secrets
kubectl get secrets -n ${{ values.kubernetes_namespace }}
```

**Resolution:**
1. Verify container registry credentials
2. Check image tag exists
3. Ensure pull secrets are configured

### Pod Crash Loop

**Error: CrashLoopBackOff**

```bash
# View pod logs
kubectl logs -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }} --previous

# Check resource limits
kubectl top pod -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }}

# Describe pod for events
kubectl describe pod -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }}
```

**Resolution:**
1. Check application logs for errors
2. Verify environment variables are set
3. Ensure resource limits are adequate
4. Check liveness probe configuration

### Service Unavailable

**Error: Connection refused or 503**

```bash
# Check service endpoints
kubectl get endpoints ${{ values.name }} -n ${{ values.kubernetes_namespace }}

# Verify pod readiness
kubectl get pods -n ${{ values.kubernetes_namespace }} -l app=${{ values.name }} -o wide

# Test service internally
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://${{ values.name }}.${{ values.kubernetes_namespace }}.svc.cluster.local/health
```

**Resolution:**
1. Ensure pods are Ready
2. Verify service selector matches pod labels
3. Check readiness probe is passing

### HPA Not Scaling

**Issue: Pods not scaling up/down**

```bash
# Check HPA status
kubectl get hpa ${{ values.name }}-hpa -n ${{ values.kubernetes_namespace }}

# Describe HPA for events
kubectl describe hpa ${{ values.name }}-hpa -n ${{ values.kubernetes_namespace }}

# Verify metrics-server is running
kubectl get pods -n kube-system | grep metrics-server
```

**Resolution:**
1. Ensure metrics-server is deployed
2. Verify resource requests are set on containers
3. Check HPA target metrics are being collected

### Ingress Not Working

**Error: 404 or connection timeout**

```bash
# Check ingress status
kubectl get ingress ${{ values.name }}-ingress -n ${{ values.kubernetes_namespace }}

# Verify ingress controller
kubectl get pods -n ingress-nginx

# Check TLS certificate
kubectl get certificate -n ${{ values.kubernetes_namespace }}
```

**Resolution:**
1. Verify ingress class is correct
2. Check DNS resolution for hostname
3. Ensure TLS certificate is issued
4. Verify ingress controller is running

### Network Policy Issues

**Error: Connection timeout between services**

```bash
# List network policies
kubectl get networkpolicies -n ${{ values.kubernetes_namespace }}

# Describe network policy
kubectl describe networkpolicy ${{ values.name }}-netpol -n ${{ values.kubernetes_namespace }}

# Test connectivity
kubectl run debug --image=nicolaka/netshoot --rm -it --restart=Never -- \
  curl -v http://${{ values.name }}.${{ values.kubernetes_namespace }}.svc.cluster.local/health
```

**Resolution:**
1. Review network policy ingress/egress rules
2. Verify source namespace labels match policy
3. Check if required ports are allowed

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yaml          # CI/CD pipeline configuration
├── k8s/
│   ├── deployment.yaml         # Deployment manifest
│   ├── service.yaml            # Service, ConfigMap, Secret
│   └── scaling-and-networking.yaml  # HPA, PDB, Ingress, NetworkPolicy
├── src/                        # Application source code
├── tests/
│   ├── kubeconform.yaml        # Kubernetes manifest validation
│   └── k8s-test.sh             # Kubernetes integration tests
├── docs/
│   └── index.md                # This documentation
├── Dockerfile                  # Multi-stage container build
├── api-spec.yaml               # OpenAPI specification
├── catalog-info.yaml           # Backstage catalog metadata
├── mkdocs.yml                  # TechDocs configuration
└── README.md                   # Quick start guide
```

---

## Related Templates

| Template | Description |
| -------- | ----------- |
| [aws-eks](/docs/default/template/aws-eks) | Amazon EKS Kubernetes cluster |
| [azure-aks](/docs/default/template/azure-aks) | Azure Kubernetes Service cluster |
| [gcp-gke](/docs/default/template/gcp-gke) | Google Kubernetes Engine cluster |
| [aws-rds](/docs/default/template/aws-rds) | Amazon RDS database |
| [postgresql](/docs/default/template/postgresql) | PostgreSQL database on Kubernetes |
| [rabbitmq](/docs/default/template/rabbitmq) | RabbitMQ message queue |
| [kafka](/docs/default/template/kafka) | Apache Kafka cluster |
| [prometheus-stack](/docs/default/template/prometheus-stack) | Prometheus monitoring stack |

---

## API Specification

See [api-spec.yaml](../api-spec.yaml) for the complete OpenAPI specification.

### Endpoints

| Path | Method | Description |
| ---- | ------ | ----------- |
| `/health` | GET | Liveness health check |
| `/ready` | GET | Readiness check |
| `/metrics` | GET | Prometheus metrics |
| `/api/v1/*` | * | Application API endpoints |

---

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [Trivy Security Scanner](https://trivy.dev/)
- [Backstage Software Catalog](https://backstage.io/docs/features/software-catalog/)

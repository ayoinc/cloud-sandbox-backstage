# Helm Charts Repository

Kubernetes Helm charts for deploying applications and infrastructure services with consistent, repeatable deployments.

## Quick Start

```bash
# Add the repository
helm repo add company-charts https://charts.company.com
helm repo update

# Search available charts
helm search repo company-charts

# Install a chart
helm install my-app company-charts/webapp \
  --namespace my-namespace \
  --create-namespace \
  --values custom-values.yaml

# List releases
helm list --all-namespaces

# Upgrade a release
helm upgrade my-app company-charts/webapp \
  --reuse-values \
  --set image.tag=v2.0.0

# Uninstall a release
helm uninstall my-app --namespace my-namespace
```

## Features

| Feature               | Description                             | Status |
| --------------------- | --------------------------------------- | ------ |
| Template Library      | Reusable template helpers and functions | Active |
| Multi-Environment     | Dev, staging, production value files    | Active |
| OCI Registry Support  | Push/pull charts as OCI artifacts       | Active |
| Dependency Management | Sub-chart dependencies and conditions   | Active |
| Hooks                 | Pre/post install, upgrade, delete hooks | Active |
| Tests                 | Chart testing with helm test            | Active |
| JSON Schema           | values.schema.json validation           | Active |
| GitOps Ready          | ArgoCD and Flux compatible              | Active |

## Architecture

```d2
direction: down

source: Chart Source {
  style.fill: "#e3f2fd"
  git: Git Repository
  charts: "charts/"
}

pipeline: CI/CD Pipeline {
  style.fill: "#e8f5e9"
  lint: Lint & Package
  helm: helm package
}

source -> pipeline

chartmuseum: Chart Museum {
  style.fill: "#fff3e0"
  url: "charts.company.com"
}

oci: OCI Registry {
  style.fill: "#c8e6c9"
  harbor: Harbor/ECR
  ghcr: ghcr.io
}

pipeline -> chartmuseum
pipeline -> oci

helm: Helm CLI {
  style.fill: "#ffcdd2"
  install: helm install
  upgrade: helm upgrade
}

gitops: GitOps {
  style.fill: "#e1bee7"
  argocd: ArgoCD / Flux
  sync: Continuous Sync
}

chartmuseum -> helm
oci -> helm
helm -> gitops

cluster: Kubernetes Cluster {
  style.fill: "#b3e5fc"
  dev: Namespace dev
  staging: Namespace staging
  prod: Namespace prod
}

gitops -> cluster
helm -> cluster
```

## Available Charts

| Chart              | Version | Description              | Type           |
| ------------------ | ------- | ------------------------ | -------------- |
| `webapp`           | 2.5.0   | Generic web application  | Application    |
| `api-service`      | 1.8.0   | REST/GraphQL API service | Application    |
| `worker`           | 1.4.0   | Background job processor | Application    |
| `cronjob`          | 1.2.0   | Scheduled job runner     | Application    |
| `postgresql`       | 14.0.0  | PostgreSQL database      | Infrastructure |
| `redis`            | 18.0.0  | Redis cache/queue        | Infrastructure |
| `mongodb`          | 14.0.0  | MongoDB database         | Infrastructure |
| `kafka`            | 26.0.0  | Apache Kafka cluster     | Infrastructure |
| `elasticsearch`    | 8.5.0   | Elasticsearch cluster    | Infrastructure |
| `prometheus-stack` | 55.0.0  | Monitoring stack         | Observability  |

## Chart Structure

```
charts/
├── webapp/
│   ├── Chart.yaml              # Chart metadata
│   ├── Chart.lock              # Dependency lock
│   ├── values.yaml             # Default values
│   ├── values.schema.json      # Value validation
│   ├── README.md               # Chart documentation
│   ├── .helmignore             # Ignore patterns
│   ├── templates/
│   │   ├── _helpers.tpl        # Template helpers
│   │   ├── deployment.yaml     # Deployment resource
│   │   ├── service.yaml        # Service resource
│   │   ├── ingress.yaml        # Ingress resource
│   │   ├── hpa.yaml            # HorizontalPodAutoscaler
│   │   ├── pdb.yaml            # PodDisruptionBudget
│   │   ├── serviceaccount.yaml # ServiceAccount
│   │   ├── configmap.yaml      # ConfigMap
│   │   ├── secret.yaml         # Secret
│   │   ├── NOTES.txt           # Post-install notes
│   │   └── tests/
│   │       └── test-connection.yaml
│   ├── charts/                 # Subcharts
│   └── ci/                     # CI values for testing
│       ├── test-values.yaml
│       └── prod-values.yaml
└── library/
    └── common/                 # Shared library chart
        ├── Chart.yaml
        └── templates/
            └── _helpers.tpl
```

## Helm Commands Reference

| Command                       | Description              |
| ----------------------------- | ------------------------ |
| `helm repo add <name> <url>`  | Add chart repository     |
| `helm repo update`            | Update repository index  |
| `helm search repo <keyword>`  | Search for charts        |
| `helm show values <chart>`    | Display default values   |
| `helm install <name> <chart>` | Install a chart          |
| `helm upgrade <name> <chart>` | Upgrade a release        |
| `helm rollback <name> <rev>`  | Rollback to revision     |
| `helm uninstall <name>`       | Delete a release         |
| `helm list`                   | List releases            |
| `helm history <name>`         | View release history     |
| `helm get values <name>`      | Get deployed values      |
| `helm template <chart>`       | Render templates locally |

## Related Documentation

- [Overview](overview.md) - Chart development, templates, and best practices
- [Usage](usage.md) - Deployment examples and troubleshooting

# Backstage Software Catalog

This directory contains the software catalog entities for the Cloud Sandbox Backstage Developer Portal. The catalog provides a centralized registry of all software components, APIs, resources, systems, and teams.

## Catalog Structure

```
catalog/
├── catalog-info.yaml      # Main Location file (registers all entities)
├── users.yaml             # Groups and users
├── domains.yaml           # Business domains
├── devops-domains.yaml    # DevOps-specific domains
├── systems.yaml           # Systems definitions
├── devops-systems.yaml    # DevOps-specific systems
├── apis-and-resources.yaml # API and Resource definitions
└── [component-name]/      # Component directories
    ├── catalog-info.yaml  # Component entity definition
    ├── mkdocs.yml         # TechDocs configuration
    └── docs/              # Component documentation
        ├── index.md
        ├── overview.md
        └── usage.md
```

## Entity Types

### Domains (6 total)

Business domains that group related systems:

| Domain           | Description                       |
| ---------------- | --------------------------------- |
| `cloud-platform` | Cloud infrastructure and services |
| `data-analytics` | Data processing and analytics     |
| `devops`         | CI/CD and automation              |
| `observability`  | Monitoring and logging            |
| `security`       | Security and compliance           |
| `applications`   | Application services              |

### Systems (12 total)

Systems that group related components:

| System                            | Domain         | Components                           |
| --------------------------------- | -------------- | ------------------------------------ |
| `cloud-services-platform`         | cloud-platform | AWS, Azure, GCP services             |
| `data-platform`                   | data-analytics | Kafka, Spark, Airflow, databases     |
| `awx-automation-platform`         | devops         | AWX core, operator, Helm chart       |
| `ci-cd-platform`                  | devops         | CI/CD pipelines, artifact repository |
| `infrastructure-as-code-platform` | devops         | Terraform, CloudFormation, Pulumi    |
| `observability-platform`          | observability  | Prometheus, ELK, Jaeger              |
| `security-compliance-platform`    | security       | Security scanning, SonarQube         |
| `testing-automation-platform`     | devops         | Testing frameworks                   |
| `kubernetes-operators`            | cloud-platform | Kubernetes operators                 |
| `sample-applications`             | applications   | Sample apps                          |

### Components (40 total)

#### By Category

**Ansible Automation**

- `ansible-docker-host` - Docker host configuration role
- `ansible-webserver` - Web server configuration role

**Data Platform**

- `apache-airflow` - Workflow orchestration
- `apache-kafka` - Event streaming platform
- `apache-spark` - Data processing engine
- `elasticsearch-data` - Search and analytics
- `minio-storage` - S3-compatible object storage
- `mongodb-cluster` - Document database
- `postgresql-cluster` - Relational database
- `rabbitmq-cluster` - Message broker
- `redis-cluster` - In-memory cache
- `zookeeper-ensemble` - Distributed coordination

**AWX Automation Platform**

- `awx-core` - AWX application core
- `awx-helm-chart` - Kubernetes Helm chart
- `awx-operator` - Kubernetes operator

**Cloud Services**

- `aws-services` - AWS service integrations
- `azure-services` - Azure service integrations
- `gcp-services` - GCP service integrations
- `multi-cloud-management` - Multi-cloud orchestration

**CI/CD and DevOps**

- `artifact-repository` - Binary artifact storage
- `ci-cd-pipelines` - Pipeline definitions
- `docker-images` - Container image library
- `helm-charts` - Kubernetes Helm charts
- `packer` - Machine image builder

**Infrastructure as Code**

- `cloudformation-templates` - AWS CloudFormation
- `pulumi-projects` - Pulumi IaC projects
- `terraform-modules` - Terraform module library

**Observability**

- `datadog-integration` - Datadog monitoring
- `elk-stack` - Elasticsearch, Logstash, Kibana
- `jaeger-tracing` - Distributed tracing
- `new-relic-integration` - New Relic APM
- `pagerduty-integration` - Incident management
- `prometheus-stack` - Prometheus & Grafana
- `splunk-enterprise` - Log management

**Sample Applications**

- `sample-nodejs-api` - Example Node.js API
- `sample-react-frontend` - Example React app

**Security and Testing**

- `performance-testing` - Load testing tools
- `security-scanning-suite` - Security scanners
- `sonarqube` - Code quality analysis
- `testing-frameworks` - Test automation tools

### APIs (29 total)

All APIs are defined in `apis-and-resources.yaml` with full OpenAPI/AsyncAPI specifications:

| API              | Type     | System                  |
| ---------------- | -------- | ----------------------- |
| `aws-api`        | OpenAPI  | cloud-services-platform |
| `azure-api`      | OpenAPI  | cloud-services-platform |
| `gcp-api`        | OpenAPI  | cloud-services-platform |
| `postgresql-api` | OpenAPI  | data-platform           |
| `mongodb-api`    | OpenAPI  | data-platform           |
| `redis-api`      | OpenAPI  | data-platform           |
| `kafka-api`      | AsyncAPI | data-platform           |
| `rabbitmq-api`   | AsyncAPI | data-platform           |
| `prometheus-api` | OpenAPI  | observability-platform  |
| `grafana-api`    | OpenAPI  | observability-platform  |
| ... and more     |

### Resources (15 total)

Infrastructure resources defined in `apis-and-resources.yaml`:

| Resource                | Type          | System                 |
| ----------------------- | ------------- | ---------------------- |
| `postgresql-database`   | database      | data-platform          |
| `mongodb-database`      | database      | data-platform          |
| `redis-cache`           | cache         | data-platform          |
| `kafka-cluster`         | message-queue | data-platform          |
| `elasticsearch-cluster` | search        | observability-platform |
| ... and more            |

## Component Documentation

Each component includes TechDocs documentation:

- **index.md** - Overview and quick start
- **overview.md** - Architecture and design
- **usage.md** - Usage examples and configuration

Documentation is rendered via Backstage TechDocs at `/docs/default/component/<component-name>`.

## Adding New Components

1. Create a new directory: `catalog/<component-name>/`
2. Add `catalog-info.yaml`:
   ```yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: my-component
     title: My Component
     description: Description of my component
     annotations:
       backstage.io/techdocs-ref: dir:.
     tags:
       - relevant-tag
   spec:
     type: service|library|website
     lifecycle: production|experimental
     owner: team-name
     system: system-name
     providesApis:
       - my-api
   ```
3. Add `mkdocs.yml` for TechDocs
4. Add `docs/` folder with documentation
5. Register in `catalog/catalog-info.yaml` targets

## Validation

Validate catalog entities:

```bash
# In Backstage directory
yarn backstage-cli catalog validate catalog/
```

## Groups and Ownership

Groups are defined in `users.yaml`:

| Group           | Description          |
| --------------- | -------------------- |
| `platform-team` | Platform engineering |
| `cloud-team`    | Cloud infrastructure |
| `data-team`     | Data engineering     |
| `devops-team`   | DevOps and CI/CD     |
| `sre-team`      | Site reliability     |
| `security-team` | Security             |
| `quality-team`  | QA and testing       |
| `awx-team`      | AWX automation       |

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on adding catalog entities.

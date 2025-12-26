# Backstage Scaffolder Templates

This directory contains all scaffolder templates for the Cloud Sandbox Backstage Developer Portal. These templates enable self-service provisioning of infrastructure, applications, documentation, and more.

## Template Categories

### Cloud Infrastructure (14 templates)

#### AWS
| Template | Description |
|----------|-------------|
| `aws-cloudfront` | CloudFront CDN distribution with S3 origin |
| `aws-eks` | Elastic Kubernetes Service cluster |
| `aws-lambda` | Serverless Lambda function with API Gateway |
| `aws-rds` | RDS PostgreSQL/MySQL database instance |
| `aws-s3` | S3 bucket with versioning and encryption |
| `aws-vpc` | VPC with public/private subnets |

#### Azure
| Template | Description |
|----------|-------------|
| `azure-aks` | Azure Kubernetes Service cluster |
| `azure-functions` | Azure Functions serverless app |
| `azure-static-web` | Static Web App with CDN |
| `azure-vnet` | Virtual Network with subnets |

#### GCP
| Template | Description |
|----------|-------------|
| `gcp-cloud-run` | Cloud Run serverless container |
| `gcp-cloud-sql` | Cloud SQL managed database |
| `gcp-gke` | Google Kubernetes Engine cluster |
| `gcp-vpc` | VPC network with subnets |

### Applications (6 templates)

| Template | Description |
|----------|-------------|
| `app-nextjs` | Next.js 14 application with TypeScript |
| `app-nodejs-api` | Node.js REST API with Express |
| `app-springboot` | Spring Boot Java application |
| `python-api` | FastAPI Python application |
| `react-frontend` | React 18 SPA with TypeScript |
| `docker-application` | Generic Docker containerized application |

### Infrastructure as Code (4 templates)

| Template | Description |
|----------|-------------|
| `terraform-module` | Reusable Terraform module with tests |
| `terraform-infrastructure` | Multi-cloud Terraform configuration |
| `cloud-sandbox` | Quick sandbox environment provisioning |
| `packer-image` | Packer machine image builder |

### Ansible Automation (3 templates)

| Template | Description |
|----------|-------------|
| `ansible-playbook` | Ansible playbook with inventory |
| `ansible-docker` | Ansible role for Docker installation |
| `ansible-nginx` | Ansible role for Nginx configuration |

### Kubernetes (2 templates)

| Template | Description |
|----------|-------------|
| `kubernetes-microservice` | K8s microservice with Deployment, Service, Ingress |
| `awx-deployment` | AWX automation platform deployment |

### Data Engineering (3 templates)

| Template | Description |
|----------|-------------|
| `data-airflow` | Apache Airflow DAG project |
| `data-dbt` | dbt data transformation project |
| `data-superset` | Apache Superset dashboard configuration |

### Documentation (4 templates)

| Template | Description |
|----------|-------------|
| `docs-project` | Full project documentation with TechDocs |
| `docs-adr` | Architecture Decision Records |
| `docs-runbook` | Operations runbook documentation |
| `docs-d2-guide` | D2 diagram documentation guide |

### Testing (2 templates)

| Template | Description |
|----------|-------------|
| `test-k6-load` | k6 load testing project |
| `test-playwright` | Playwright E2E testing project |

### DevOps & SRE (2 templates)

| Template | Description |
|----------|-------------|
| `sre-monitoring` | Prometheus/Grafana monitoring stack |
| `vagrant-environment` | Vagrant development environment |

### Marketing (2 templates)

| Template | Description |
|----------|-------------|
| `marketing-landing-page` | Marketing landing page |
| `marketing-static-site` | Hugo static site |

### GitHub Management (3 templates)

| Template | Description |
|----------|-------------|
| `github-team` | Create GitHub team |
| `github-team-member` | Add member to GitHub team |
| `github-user` | Invite user to GitHub organization |

## Template Structure

Each template follows this standard structure:

```
template-name/
├── template.yaml          # Backstage scaffolder template definition
├── skeleton/              # Template files to be scaffolded
│   ├── catalog-info.yaml  # Backstage catalog entity
│   ├── mkdocs.yml         # TechDocs configuration
│   ├── docs/              # Documentation
│   │   └── index.md
│   ├── README.md          # Project README
│   └── .github/
│       └── workflows/     # CI/CD pipelines
├── docs/                  # Template documentation (optional)
│   └── index.md
└── mkdocs.yml             # Template-level TechDocs (optional)
```

## Standards

All templates adhere to these standards:

### Infrastructure Templates (Terraform)
- **Module-based architecture** - Root modules only contain module calls, no raw resources
- **Testing** - Terraform tests in `tests/` directory
- **CI/CD** - GitHub Actions for `terraform init`, `plan`, `apply`
- **Documentation** - TechDocs with architecture diagrams

### Application Templates
- **Containerization** - Dockerfile included
- **CI/CD** - Build, test, lint, security scan pipelines
- **Testing** - Unit and integration test scaffolding
- **Documentation** - TechDocs with API documentation

### Ansible Templates
- **Role structure** - Proper `tasks/`, `handlers/`, `defaults/`, `meta/` structure
- **Testing** - Molecule tests with Docker driver
- **Dependencies** - `requirements.yml` for Galaxy dependencies
- **CI/CD** - GitHub Actions for linting and testing

### Documentation
- **TechDocs** - All templates include `mkdocs.yml` and `docs/` folder
- **D2 Diagrams** - Architecture diagrams using D2 notation
- **Catalog Integration** - `catalog-info.yaml` for Backstage registration

## Creating New Templates

1. Create a new directory under `templates/`
2. Add `template.yaml` with scaffolder steps
3. Create `skeleton/` with template files
4. Include `catalog-info.yaml` for catalog registration
5. Add `mkdocs.yml` and `docs/` for TechDocs
6. Add CI/CD workflows in `.github/workflows/`
7. Test the template using the Backstage UI

## Usage

Templates are available in the Backstage UI under **Create** > **Templates**. Select a template, fill in the required parameters, and the scaffolder will create your new project.

```
/create
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on adding or modifying templates.

# Backstage Scaffolder Templates

This directory contains all scaffolder templates for the Cloud Sandbox Backstage Developer Portal. These templates enable self-service provisioning of infrastructure, applications, documentation, and more.

## Template Categories

### Cloud Infrastructure (30 templates)

#### AWS

| Template                  | Description                                                                                                                                           |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `aws-cloudfront`          | Create a CloudFront CDN distribution with Origin Access Control and caching configuration                                                             |
| `aws-eks`                 | Create an EKS Kubernetes cluster with managed node groups and cluster autoscaler                                                                      |
| `aws-full-infrastructure` | Complete AWS infrastructure stack with all resource categories - networking, compute, containers, storage, databases, security, monitoring, and more. |
| `aws-lambda`              | Create an AWS Lambda function with IAM role, CloudWatch logs, and optional VPC configuration                                                          |
| `aws-rds`                 | Create an RDS PostgreSQL or MySQL database with Multi-AZ, encryption, and automated backups                                                           |
| `aws-s3`                  | Create an S3 bucket with encryption, versioning, and lifecycle policies                                                                               |
| `aws-vpc`                 | Create an AWS VPC with public/private subnets, NAT gateways, and flow logs                                                                            |

#### Azure

| Template                    | Description                                                                                                                                                                                   |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `azure-aks`                 | Create an Azure Kubernetes Service cluster with node pools, RBAC, and monitoring                                                                                                              |
| `azure-container-apps`      | Create an Azure Container Apps environment and app with a managed identity, Log Analytics, HTTPS ingress and autoscaling                                                                      |
| `azure-full-infrastructure` | Complete Azure infrastructure stack with Terraform. Enable the modules you need (networking, compute, containers, storage, database, security, identity, monitoring, integration, governance) |
| `azure-functions`           | Create an Azure Functions App for serverless event-driven compute                                                                                                                             |
| `azure-key-vault`           | Create an Azure Key Vault with Azure RBAC, purge protection, a deny-by-default firewall and an optional private endpoint                                                                      |
| `azure-postgresql`          | Create an Azure Database for PostgreSQL flexible server with private networking, Entra ID authentication and optional zone-redundant high availability                                        |
| `azure-static-web`          | Create an Azure Static Web App for hosting static sites, SPAs, and serverless APIs                                                                                                            |
| `azure-storage-account`     | Create a private Azure Storage account with Entra ID access, versioning, lifecycle rules and optional customer-managed keys                                                                   |
| `azure-vnet`                | Create an Azure VNet with subnets, NSGs, and peering-ready configuration                                                                                                                      |

#### GCP

| Template                  | Description                                                                                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gcp-cloud-functions`     | Create a Cloud Run function (Cloud Functions 2nd gen) for Node.js with a dedicated service account, an HTTP or Pub/Sub trigger and Terraform deployment |
| `gcp-cloud-run`           | Create a Cloud Run serverless container service with auto-scaling and custom domains                                                                    |
| `gcp-cloud-sql`           | Create a managed Cloud SQL database instance with high availability, automated backups, and private networking                                          |
| `gcp-cloud-storage`       | Create a Cloud Storage bucket with uniform access, public access prevention, versioning, lifecycle rules and optional customer-managed encryption       |
| `gcp-full-infrastructure` | Complete GCP infrastructure stack with all resource categories - networking, compute, containers, storage, databases, security, monitoring, and more.   |
| `gcp-gke`                 | Create a GKE Kubernetes cluster with Autopilot or Standard mode, Workload Identity, and monitoring                                                      |
| `gcp-pubsub`              | Create a Pub/Sub topic with subscriptions, dead-letter handling, regional message storage and an optional Avro or Protocol Buffers schema               |
| `gcp-vpc`                 | Create a GCP VPC with subnets, firewall rules, Cloud NAT, and Cloud Router                                                                              |

#### Cloudflare

| Template                      | Description                                                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `cloudflare-workers-platform` | Deploy a Cloudflare Worker with an R2 bucket, a D1 database or KV namespace and a custom domain, all managed by Terraform |
| `cloudflare-zone`             | Manage a Cloudflare zone with hardened TLS settings, DNS records, DNSSEC and WAF rulesets using Terraform                 |

#### DigitalOcean

| Template                  | Description                                                                                                           |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `digitalocean-droplet`    | Create hardened DigitalOcean Droplets in a VPC with a cloud firewall, reserved IPs and cloud-init                     |
| `digitalocean-kubernetes` | Create a DigitalOcean Kubernetes (DOKS) cluster with autoscaling node pools, a VPC and container registry integration |

#### Hetzner

| Template               | Description                                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `hetzner-cloud-server` | Create hardened Hetzner Cloud servers on a private network with a firewall, an optional load balancer and cloud-init |

#### Oracle Cloud

| Template      | Description                                                                                                                                |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `oci-compute` | Create an Oracle Cloud Infrastructure compute instance in its own VCN with network security groups, including the Always Free Ampere shape |

### Applications (14 templates)

| Template             | Description                                                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app-astro-site`     | Create an Astro content site with typed Markdown collections, Tailwind CSS v4 and a deployment workflow for GitHub Pages, Cloudflare or Amazon S3 |
| `app-bun-api`        | Create a TypeScript API on Bun with Hono, validated environment variables, bun test and a non-root container image                                |
| `app-dotnet-api`     | Create a .NET 10 minimal API with OpenAPI, health checks, JSON logs, xUnit integration tests and a chiseled container image                       |
| `app-go-service`     | Create a Go HTTP service with structured logging, OpenTelemetry tracing and a distroless image                                                    |
| `app-hono-worker`    | Create a TypeScript Hono API on Cloudflare Workers with an optional D1 or KV binding and tests that run in the Workers runtime                    |
| `app-kotlin-ktor`    | Create a Ktor 3 service in Kotlin with a Gradle version catalog, kotlinx.serialization, JSON logs, tests and a distroless image                   |
| `app-nextjs`         | Create a Next.js 14 application with TypeScript and App Router                                                                                    |
| `app-nodejs-api`     | Create a Node.js TypeScript API with Express or Fastify                                                                                           |
| `app-rust-axum`      | Create a Rust HTTP service with axum and tokio, structured tracing, optional PostgreSQL through sqlx and a distroless image                       |
| `app-springboot`     | Create a Spring Boot 3 REST API with Java                                                                                                         |
| `app-sveltekit`      | Create a SvelteKit app with Svelte 5 runes and TypeScript, Vitest and Playwright tests, and the adapter for your host                             |
| `docker-application` | Create a containerised service with a tested, scanned and published Docker image                                                                  |
| `python-api`         | Create a tested FastAPI service with a container image and a GitHub Actions pipeline                                                              |
| `react-frontend`     | Create a React single-page application with Vite, TypeScript, Vitest and a GitHub Actions pipeline                                                |

### Infrastructure as Code (12 templates)

| Template                   | Description                                                                                                                                                                                                       |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cloud-sandbox`            | Create a cloud development sandbox with VPC, compute, and optional services                                                                                                                                       |
| `crossplane-composition`   | Create a Crossplane v2 configuration with a namespaced composite resource definition, a function-pipeline composition for AWS, Azure or Google Cloud, an example resource and render tests                        |
| `opentofu-stack`           | Create an OpenTofu root stack for AWS, Azure or Google Cloud with client-side state encryption, per-environment variables, mocked tests and an OIDC pipeline                                                      |
| `packer-image`             | Create machine images for AWS, Azure, GCP, or VMware with Packer                                                                                                                                                  |
| `policy-as-code`           | Create a policy repository for Terraform and OpenTofu with OPA policies for plans tested with Conftest, custom Checkov checks, a shared TFLint configuration and a reusable workflow that other repositories call |
| `pulumi-python`            | Create a Pulumi Python project managed with uv for AWS, Azure or Google Cloud with a tested component, a stack per environment, Pulumi ESC guidance and an OIDC pipeline                                          |
| `pulumi-typescript`        | Create a Pulumi TypeScript project for AWS, Azure or Google Cloud with a tested component, a stack per environment, Pulumi ESC guidance and an OIDC pipeline                                                      |
| `terraform-component`      | Creates a Terraform infrastructure component on AWS, Azure or Google Cloud with naming and tagging conventions, isolated state per environment, tests and a validation and deployment pipeline                    |
| `terraform-infrastructure` | Create enterprise-grade cloud infrastructure with Terraform, including security, monitoring, and compliance                                                                                                       |
| `terraform-module`         | Create a production-ready Terraform module with best practices for AWS, Azure, or GCP                                                                                                                             |
| `terragrunt-live`          | Create a Terragrunt live repository for AWS, Azure or Google Cloud with a root configuration, an environment and region hierarchy, stacks of reusable units, generated remote state and an OIDC pipeline          |
| `vagrant-environment`      | Create a local VM development environment with Vagrant                                                                                                                                                            |

### Ansible Automation (11 templates)

| Template                        | Description                                                                                                                                                               |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ansible-collection`            | Create an Ansible Galaxy collection with an example module, filter and role, ansible-test sanity, unit and integration tests, antsibull-changelog and a publish workflow  |
| `ansible-docker`                | Create an Ansible role for installing and configuring Docker                                                                                                              |
| `ansible-execution-environment` | Create an ansible-builder v3 execution environment with pinned collections, ansible-navigator configuration and a workflow that builds, scans, pushes and signs the image |
| `ansible-k3s-cluster`           | Create playbooks for a highly available k3s cluster with embedded etcd, an optional kube-vip API address, rolling upgrades and reset                                      |
| `ansible-linux-hardening`       | Create a CIS-aligned Linux hardening role covering sshd, sysctl, auditd, firewall and unattended upgrades, with a toggle per control and Molecule verification            |
| `ansible-nginx`                 | Create an Ansible role for installing and configuring Nginx web server                                                                                                    |
| `ansible-playbook`              | Create a new Ansible playbook project with best practices                                                                                                                 |
| `ansible-postgresql`            | Create a PostgreSQL role with tuned configuration, declared roles and databases, pgBackRest backups and an optional streaming replica                                     |
| `ansible-role-molecule`         | Create a tested Ansible role with Molecule, a multi-distribution matrix, argument specs and the ansible-lint production profile                                           |
| `ansible-windows`               | Create playbooks for Windows hosts over WinRM or SSH with a security baseline, features, Windows Update and Chocolatey or winget packages                                 |
| `awx-deployment`                | Deploy AWX instance using the AWX Operator in Kubernetes                                                                                                                  |

### Kubernetes and GitOps (2 templates)

| Template                     | Description                                                                                                                   |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `kubernetes-microservice`    | Create a containerised microservice with Kubernetes manifests, a tested pipeline and a deployment workflow                    |
| `kubernetes-platform-addons` | Install an ingress controller, cert-manager, ExternalDNS and Metrics Server on any Kubernetes cluster with Terraform and Helm |

### Data Engineering (3 templates)

| Template        | Description                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| `data-airflow`  | Create an Apache Airflow DAG project with best practices, testing, and CI/CD       |
| `data-dbt`      | Create a dbt (data build tool) project for data transformation with best practices |
| `data-superset` | Create an Apache Superset dashboard configuration project                          |

### Documentation and Delivery (6 templates)

| Template               | Description                                                                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docs-adr`             | Create an ADR repository for documenting architecture decisions                                                                                         |
| `docs-architecture-c4` | A high-level and low-level design for one system, with C4 diagrams in D2, published as documentation and exported to branded PDF and Word               |
| `docs-d2-guide`        | Template for creating documentation with D2 declarative diagrams                                                                                        |
| `docs-delivery-pack`   | A delivery plan, RAID log, RACI matrix and status report kept as data, published as documentation and built into a branded Excel workbook, Word and PDF |
| `docs-project`         | Create comprehensive project documentation with TechDocs                                                                                                |
| `docs-runbook`         | Create operational runbooks for incident response and procedures                                                                                        |

### Testing (2 templates)

| Template          | Description                                                           |
| ----------------- | --------------------------------------------------------------------- |
| `test-k6-load`    | Create a k6 load testing project for performance and stress testing   |
| `test-playwright` | Create a Playwright end-to-end testing project with Page Object Model |

### DevOps and SRE (1 templates)

| Template         | Description                                                                     |
| ---------------- | ------------------------------------------------------------------------------- |
| `sre-monitoring` | Create a monitoring stack with Prometheus alerting rules and Grafana dashboards |

### Marketing (2 templates)

| Template                 | Description                                                 |
| ------------------------ | ----------------------------------------------------------- |
| `marketing-landing-page` | Create a responsive marketing landing page                  |
| `marketing-static-site`  | Create a Hugo static website for marketing or documentation |

### GitHub Management (3 templates)

| Template             | Description                                                                       |
| -------------------- | --------------------------------------------------------------------------------- |
| `github-team`        | Create a new team in a GitHub organization.                                       |
| `github-team-member` | Add a GitHub user to a team of a GitHub organization, or change their role in it. |
| `github-user`        | Invite a person to join a GitHub organization by email, optionally into teams.    |

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

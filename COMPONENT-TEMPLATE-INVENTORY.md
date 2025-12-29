# Cloud Sandbox Developer Portal - Complete Component & Template Inventory

## 📋 Executive Summary

**Total Templates:** 52
**Total Catalog Components:** 125+ catalog-info.yaml files across 40+ services
**Cloud Providers:** Azure, AWS, GCP
**Infrastructure-as-Code:** Terraform, Ansible, Packer, CloudFormation, Pulumi

---

## 🏗️ Infrastructure-as-Code Templates (19)

### Full Infrastructure Stacks (New - 3)

1. **aws-full-infrastructure** - Complete AWS stack with VPC, EKS, RDS, S3, DynamoDB, ElastiCache, IAM, CloudWatch
2. **azure-full-infrastructure** - Complete Azure stack with VNet, AKS, SQL, Cosmos DB, Storage, Key Vault, Monitor
3. **gcp-full-infrastructure** - Complete GCP stack with VPC, GKE, Cloud SQL, Firestore, Cloud Storage, Secret Manager

### AWS Infrastructure (6)

4. **aws-cloudfront** - CloudFront CDN distribution with S3 origin
5. **aws-eks** - Elastic Kubernetes Service cluster with node groups
6. **aws-lambda** - Serverless Lambda function with API Gateway
7. **aws-rds** - RDS PostgreSQL/MySQL database instance
8. **aws-s3** - S3 bucket with versioning, encryption, lifecycle policies
9. **aws-vpc** - VPC with public/private subnets, NAT gateway

### Azure Infrastructure (4)

10. **azure-aks** - Azure Kubernetes Service cluster
11. **azure-functions** - Azure Functions serverless app
12. **azure-static-web** - Static Web App with CDN integration
13. **azure-vnet** - Virtual Network with subnets, NSGs

### GCP Infrastructure (4)

14. **gcp-cloud-run** - Cloud Run serverless container service
15. **gcp-cloud-sql** - Cloud SQL managed database (PostgreSQL/MySQL)
16. **gcp-gke** - Google Kubernetes Engine cluster
17. **gcp-vpc** - VPC network with subnets, firewall rules

### Generic IaC (3)

18. **terraform-component** - Multi-cloud Terraform component with modules
19. **terraform-infrastructure** - Reusable Terraform infrastructure patterns
20. **terraform-module** - Terraform module with testing framework

---

## 🚀 Application Templates (6)

21. **app-nextjs** - Next.js 14 application with TypeScript
22. **app-nodejs-api** - Node.js REST API with Express.js
23. **app-springboot** - Spring Boot Java application
24. **python-api** - FastAPI Python application
25. **react-frontend** - React 18 SPA with TypeScript
26. **docker-application** - Generic Docker containerized application

---

## 🤖 Automation & Configuration Templates (8)

### Ansible (3)

27. **ansible-docker** - Ansible role for Docker installation
28. **ansible-nginx** - Ansible role for Nginx configuration
29. **ansible-playbook** - Ansible playbook with inventory

### Packer & CloudFormation (2)

30. **packer-image** - Packer machine image builder
31. **cloud-sandbox** - Quick sandbox environment provisioning

### GitHub Management (3)

32. **github-team** - Create GitHub team
33. **github-team-member** - Add member to GitHub team
34. **github-user** - Invite user to GitHub organization

---

## 📊 Data & Analytics Templates (3)

35. **data-airflow** - Apache Airflow DAG project
36. **data-dbt** - dbt data transformation project
37. **data-superset** - Apache Superset dashboard configuration

---

## 📝 Documentation Templates (4)

38. **docs-project** - Full project documentation with TechDocs
39. **docs-adr** - Architecture Decision Records
40. **docs-runbook** - Operations runbook documentation
41. **docs-d2-guide** - D2 diagram documentation guide

---

## 🧪 Testing Templates (2)

42. **test-k6-load** - k6 load testing project
43. **test-playwright** - Playwright E2E testing project

---

## ☸️ Kubernetes & Orchestration (2)

44. **kubernetes-microservice** - K8s microservice with Deployment, Service, Ingress
45. **awx-deployment** - AWX automation platform deployment

---

## 🔧 SRE & Monitoring (1)

46. **sre-monitoring** - Prometheus/Grafana monitoring stack

---

## 🌐 Web & Marketing (2)

47. **marketing-landing-page** - Marketing landing page
48. **marketing-static-site** - Hugo static site

---

## 💻 Development Environment (1)

49. **vagrant-environment** - Vagrant development environment

---

## 📦 Catalog Components (40 Services)

### Core Infrastructure

- **terraform-modules** - Centralized Terraform modules library
- **terraform-shared-modules** - Cross-provider shared modules
- **terraform-azure-modules** - Azure-specific Terraform modules
- **terraform-aws-modules** - AWS-specific Terraform modules
- **terraform-gcp-modules** - GCP-specific Terraform modules

### Compute & Containers

- **apache-airflow** - Workflow orchestration
- **apache-kafka** - Event streaming platform
- **apache-spark** - Big data processing
- **awx-core** - AWX automation platform
- **awx-operator** - AWX Kubernetes operator
- **awx-helm-chart** - AWX Helm charts

### Storage & Databases

- **elasticsearch-data** - Elasticsearch cluster
- **postgresql-cluster** - PostgreSQL database cluster
- **mongodb-cluster** - MongoDB cluster
- **redis-cluster** - Redis cache cluster
- **minio-storage** - S3-compatible object storage
- **artifact-repository** - Artifact storage (Nexus/Artifactory)

### Monitoring & Observability

- **prometheus-stack** - Prometheus monitoring
- **elk-stack** - ELK logging stack
- **jaeger-tracing** - Distributed tracing
- **datadog-integration** - Datadog monitoring
- **new-relic-integration** - New Relic monitoring
- **splunk-enterprise** - Splunk logging
- **sonarqube** - Code quality
- **pagerduty-integration** - Incident management

### CI/CD & DevOps

- **ci-cd-pipelines** - Pipeline orchestration
- **cloudformation-templates** - AWS CloudFormation templates
- **helm-charts** - Helm chart repository
- **packer** - Machine image builder
- **pulumi-projects** - Pulumi infrastructure
- **testing-frameworks** - Testing tools

### Cloud Services & Management

- **aws-services** - AWS service management
- **azure-services** - Azure service management
- **gcp-services** - GCP service management
- **multi-cloud-management** - Multi-cloud orchestration
- **security-scanning-suite** - Security scanning tools

### Sample Applications

- **sample-nodejs-api** - Sample Node.js API
- **sample-react-frontend** - Sample React frontend

### Network & Infrastructure

- **ansible-docker-host** - Docker host automation
- **ansible-webserver** - Web server automation
- **zookeeper-ensemble** - ZooKeeper coordination

---

## 📂 Template Structure

All templates follow this standard structure:

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

---

## ✅ Quality Standards

All templates include:

- **Infrastructure Templates:**

  - Module-based architecture (no raw resources in root)
  - Terraform tests in `tests/` directory
  - CI/CD with GitHub Actions
  - TechDocs with architecture diagrams
  - Naming/tagging using shared modules

- **Application Templates:**

  - Containerization (Dockerfile)
  - CI/CD pipelines (build, test, lint, security)
  - Testing scaffolding (unit + integration)
  - TechDocs with API documentation

- **Ansible Templates:**
  - Proper role structure (tasks/, handlers/, defaults/, meta/)
  - Molecule tests with Docker driver
  - Requirements.yml for dependencies
  - GitHub Actions for linting/testing

---

## 🚀 Usage

Templates available in Backstage UI at `/create` or **Create** > **Templates**

```bash
# Infrastructure creation
create -> Templates -> Select cloud provider -> Configure resources -> Deploy

# Application creation
create -> Templates -> Select app type -> Configure -> Generate repository
```

---

## 📊 Summary Statistics

- **52 Total Templates** across 8 categories
- **125+ Catalog Entities** in 40 services
- **3 Cloud Providers** fully supported
- **100+ Resource Types** available
- **3 Full Infrastructure Stacks** (NEW)
- **Zero Duplication** - clean separation of templates vs catalog

**Last Updated:** 2024-12-28
**Maintained By:** Platform Team
**Repository:** https://github.com/ayointegral/cloud-sandbox-backstage

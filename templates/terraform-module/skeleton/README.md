# ${{ values.name }}

${{ values.description }}

## Overview

This Terraform module provides production-ready infrastructure components for **{%- if values.provider == 'aws' %}Amazon Web Services (AWS){%- elif values.provider == 'azure' %}Microsoft Azure{%- elif values.provider == 'gcp' %}Google Cloud Platform (GCP){%- else %}Multi-Cloud{%- endif %}**.

## Module Structure

```
.
{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
├── aws/
│   ├── compute/       # EC2, Auto Scaling Groups, Launch Templates
│   ├── network/       # VPC, Subnets, NAT Gateway, Security Groups
│   ├── storage/       # S3 Buckets, EFS
│   ├── database/      # RDS, ElastiCache
│   ├── security/      # KMS, Secrets Manager, IAM
│   ├── observability/ # CloudWatch, SNS Alerts
│   ├── kubernetes/    # EKS, Node Groups, ECR
│   └── serverless/    # Lambda, API Gateway, SQS
{%- endif %}
{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
├── azure/
│   ├── compute/       # Virtual Machine Scale Sets
│   ├── network/       # VNet, Subnets, NSGs, NAT Gateway
│   ├── storage/       # Storage Account, Containers
│   ├── database/      # PostgreSQL Flexible, Redis Cache
│   ├── security/      # Key Vault, Managed Identity
│   ├── observability/ # Log Analytics, Application Insights
│   ├── kubernetes/    # AKS, Node Pools, ACR
│   └── serverless/    # Function App, API Management, Service Bus
{%- endif %}
{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
├── gcp/
│   ├── compute/       # Managed Instance Groups, Instance Templates
│   ├── network/       # VPC, Subnets, Cloud NAT, Firewall
│   ├── storage/       # Cloud Storage, Filestore
│   ├── database/      # Cloud SQL, Memorystore
│   ├── security/      # KMS, Secret Manager, Service Accounts
│   ├── observability/ # Cloud Monitoring, Log Sink, Alerts
│   ├── kubernetes/    # GKE, Node Pools, Artifact Registry
│   └── serverless/    # Cloud Functions, Cloud Run, Pub/Sub
{%- endif %}
├── examples/          # Usage examples
├── tests/             # Terraform tests
└── docs/              # Additional documentation
```

## Prerequisites

- Terraform >= ${{ values.terraform_version }}
  {%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}
- AWS CLI configured with appropriate credentials
  {%- endif %}
  {%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}
- Azure CLI configured with appropriate credentials
  {%- endif %}
  {%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}
- Google Cloud SDK configured with appropriate credentials
  {%- endif %}

## Quick Start

### 1. Initialize the module

```bash
terraform init
```

### 2. Configure your deployment

Copy the example tfvars file and customize:

```bash
{%- if values.provider == 'aws' %}
cp aws/compute/compute.auto.tfvars.example aws/compute/compute.auto.tfvars
{%- elif values.provider == 'azure' %}
cp azure/compute/compute.auto.tfvars.example azure/compute/compute.auto.tfvars
{%- elif values.provider == 'gcp' %}
cp gcp/compute/compute.auto.tfvars.example gcp/compute/compute.auto.tfvars
{%- endif %}
```

### 3. Plan and Apply

```bash
terraform plan
terraform apply
```

## Module Components

### Compute

Virtual machines and auto-scaling infrastructure with:

- Configurable instance types and sizes
- Auto-scaling based on metrics
- User data/startup scripts for initialization

### Network

Complete networking infrastructure with:

- VPC/VNet with configurable CIDR
- Public and private subnets
- NAT Gateway for private subnet egress
- Security groups/NSGs with minimal required rules

### Storage

Object and file storage with:

- Encrypted storage buckets
- Lifecycle policies
- Versioning support

### Database

Managed database services with:

- High availability configurations
- Encryption at rest
- Automated backups

### Security

Security infrastructure with:

- Key management (KMS)
- Secrets management
- IAM roles and policies

### Observability

Monitoring and alerting with:

- Centralized logging
- Metrics and dashboards
- Alert policies

### Kubernetes

Container orchestration with:

- Managed Kubernetes cluster
- Node pools with auto-scaling
- Container registry

### Serverless

Serverless compute with:

- Functions/Lambda
- API Gateway
- Message queues

## Testing

Run Terraform tests:

```bash
terraform test
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` and `terraform validate`
4. Submit a pull request

## License

This module is maintained by ${{ values.owner }}.

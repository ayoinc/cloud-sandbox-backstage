{%- set provider = values.cloud_provider -%}
{%- if provider == "aws" -%}
  {%- set cloud = "AWS" -%}{%- set net = "VPC" -%}{%- set k8s = "EKS" -%}{%- set db = "RDS for PostgreSQL" -%}
{%- elif provider == "azure" -%}
  {%- set cloud = "Azure" -%}{%- set net = "virtual network" -%}{%- set k8s = "AKS" -%}{%- set db = "Azure Database for PostgreSQL" -%}
{%- else -%}
  {%- set cloud = "Google Cloud" -%}{%- set net = "VPC network" -%}{%- set k8s = "GKE Autopilot" -%}{%- set db = "Cloud SQL for PostgreSQL" -%}
{%- endif -%}
# ${{ values.name }}

${{ values.description }}

## Overview

This repository holds a ${{ cloud }} sandbox: an isolated network in
`${{ values.region }}` for development, testing and experiments, described in
Terraform and deployed by GitHub Actions. The sandbox is meant to be created
quickly and thrown away again.

```d2
direction: down

internet: Internet {
  shape: cloud
}

network: "${{ net }} ${{ values.vpc_cidr }}" {
  public: Public subnets (${{ values.public_subnets }}) {
{%- if values.include_bastion %}
    bastion: Bastion host
{%- endif %}
    nat: NAT gateway
  }

  private: Private subnets {
{%- if values.include_eks %}
    k8s: "${{ k8s }} cluster"
{%- endif %}
{%- if values.include_rds %}
    db: PostgreSQL {
      shape: cylinder
    }
{%- endif %}
    workloads: Your workloads
  }

  private -> public.nat: outbound
}

network.public.nat -> internet
{%- if values.include_bastion %}
internet -> network.public.bastion: {% if provider == "aws" %}Session Manager{% elif provider == "azure" %}SSH from allowed CIDRs{% else %}Identity-Aware Proxy{% endif %}
network.public.bastion -> network.private: internal access
{%- endif %}
```

## What Is Created

| Component       | Included | Details |
| --------------- | -------- | ------- |
| Network         | yes      | ${{ net }} `${{ values.vpc_cidr }}` |
| Public subnets  | ${{ values.public_subnets }} | First blocks of the network range |
| Private subnets | ${{ values.private_subnets }} | Outbound internet access through one NAT gateway |
{%- if provider == "aws" %}
| Bastion host    | ${{ "yes" if values.include_bastion else "no" }} | `t3.micro` Amazon Linux 2023, reached with Session Manager; no SSH key, no open port |
| Kubernetes      | ${{ "yes" if values.include_eks else "no" }} | EKS with a managed node group of 1 to 3 `t3.medium` nodes, private API endpoint, encrypted secrets |
| Database        | ${{ "yes" if values.include_rds else "no" }} | RDS PostgreSQL 16 on `db.t4g.micro`, encrypted, private, password in Secrets Manager |
{%- elif provider == "azure" %}
| Bastion host    | ${{ "yes" if values.include_bastion else "no" }} | `Standard_B2ats_v2` Ubuntu 22.04 VM with a public IP; SSH closed until `bastion_allowed_cidrs` is set |
| Kubernetes      | ${{ "yes" if values.include_eks else "no" }} | AKS with two `Standard_D2s_v5` nodes, private API server, Azure network policies |
| Database        | ${{ "yes" if values.include_rds else "no" }} | PostgreSQL 16 flexible server `B_Standard_B1ms`, reachable from the virtual network only |
{%- else %}
| Bastion host    | ${{ "yes" if values.include_bastion else "no" }} | `e2-micro` Debian 12 VM without external IP, reached through Identity-Aware Proxy with OS Login |
| Kubernetes      | ${{ "yes" if values.include_eks else "no" }} | GKE Autopilot with private nodes; API closed to external networks by default |
| Database        | ${{ "yes" if values.include_rds else "no" }} | Cloud SQL PostgreSQL 16 with a private IP address only, encrypted connections |
{%- endif %}

All of this is defined in `modules/sandbox`. The root module passes the values
of `terraform.tfvars` to it.

{% if provider == "aws" -%}
Kubernetes and the database each need subnets in two availability zones. When
one of them is included, at least two private subnets are created even if
fewer were requested.
{%- else -%}
Kubernetes nodes run in a private subnet. When Kubernetes is included, at
least one private subnet is created even if none was requested.
{%- endif %}

## Changing the Sandbox

Edit `terraform.tfvars` and push. The values there are the ones chosen when
the sandbox was created:

```hcl
name        = "${{ values.name }}"
environment = "${{ values.environment }}"
region      = "${{ values.region }}"

vpc_cidr        = "${{ values.vpc_cidr }}"
public_subnets  = ${{ values.public_subnets }}
private_subnets = ${{ values.private_subnets }}

include_bastion = ${{ values.include_bastion | string | lower }}
include_eks     = ${{ values.include_eks | string | lower }}
include_rds     = ${{ values.include_rds | string | lower }}
```

More settings, with their defaults:

| Variable | Purpose |
| -------- | ------- |
{%- if provider == "aws" %}
| `bastion_allowed_cidrs` | CIDR blocks allowed to reach the bastion on SSH; empty means Session Manager only |
| `kubernetes_version` | EKS version; unset uses the current EKS default |
| `eks_public_access_cidrs` | CIDR blocks allowed to reach the EKS API from the internet; empty keeps it private |
| `tags` | Additional tags for all resources |
{%- elif provider == "azure" %}
| `bastion_allowed_cidrs` | CIDR blocks allowed to reach the bastion on SSH; empty keeps SSH closed |
| `kubernetes_version` | AKS version; unset uses the current AKS default |
| `kubernetes_api_allowed_cidrs` | CIDR blocks allowed to reach the AKS API from the internet; empty makes the cluster private |
| `tags` | Additional tags for all resources |
{%- else %}
| `project_id` | Project the sandbox is created in; the pipeline takes it from the `GCP_PROJECT_ID` secret |
| `kubernetes_api_allowed_cidrs` | CIDR blocks allowed to reach the GKE API from the internet |
| `labels` | Additional labels for all resources |
{%- endif %}

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push to `main`, on pull
requests and on demand.

| Job           | What it does                                                                  | Needs credentials |
| ------------- | ----------------------------------------------------------------------------- | ----------------- |
| Validate      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` | No                |
| Lint          | TFLint with the Terraform and ${{ cloud }} rule sets                          | No                |
| Test          | `terraform test`: plans against mocked providers and checks the result        | No                |
| Security scan | Trivy on the Terraform code; fails on HIGH and CRITICAL findings              | No                |
| Plan          | `terraform plan` against the remote state                                     | Yes               |
| Apply         | `terraform apply` of that plan, on pushes to `main`                           | Yes               |

Plan and Apply are skipped, not failed, while their credentials are missing.
Add these repository secrets to turn them on:

{% if provider == "aws" -%}
| Secret            | Purpose                                                    |
| ----------------- | ---------------------------------------------------------- |
| `AWS_ROLE_ARN`    | IAM role the workflow assumes through GitHub OIDC          |
| `TF_STATE_BUCKET` | S3 bucket that stores the Terraform state                  |

The optional repository variable `TF_STATE_REGION` names the region of the
state bucket when it differs from `${{ values.region }}`.
{%- elif provider == "azure" -%}
| Secret                     | Purpose                                                          |
| -------------------------- | ---------------------------------------------------------------- |
| `AZURE_CLIENT_ID`          | App registration with a federated credential for this repository |
| `AZURE_TENANT_ID`          | Tenant of that app registration                                  |
| `AZURE_SUBSCRIPTION_ID`    | Subscription the sandbox is created in                           |
| `TF_STATE_STORAGE_ACCOUNT` | Storage account that stores the Terraform state                  |

The state goes to the blob container `tfstate`; the optional repository
variable `TF_STATE_CONTAINER` names another one. The identity needs the
Contributor role on the subscription and Storage Blob Data Contributor on the
state container.
{%- else -%}
| Secret                           | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload identity provider for this repository  |
| `GCP_SERVICE_ACCOUNT`            | Service account the workflow impersonates       |
| `GCP_PROJECT_ID`                 | Project the sandbox is created in               |
| `TF_STATE_BUCKET`                | Cloud Storage bucket that stores the Terraform state |
{%- endif %}

Apply runs in the GitHub environment `${{ values.environment }}`. Add required
reviewers to that environment to approve each apply by hand.

### Manual runs

Start the workflow from the Actions tab and choose an action:

| Action    | Result                                    |
| --------- | ----------------------------------------- |
| `plan`    | Shows what would change                   |
| `apply`   | Applies the current configuration         |
| `destroy` | Removes everything the sandbox created    |

## Working Locally

These checks need Terraform 1.10 or later and no cloud account:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform test
```

To plan and apply from your machine, initialise with the remote state:

{% if provider == "aws" -%}
```bash
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.name }}/terraform.tfstate" \
  -backend-config="region=${{ values.region }}" \
  -backend-config="use_lockfile=true"
terraform plan
terraform apply
```
{%- elif provider == "azure" -%}
```bash
az login
export ARM_SUBSCRIPTION_ID=<subscription id>
terraform init \
  -backend-config="storage_account_name=<state storage account>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform plan
terraform apply
```
{%- else -%}
```bash
gcloud auth application-default login
export TF_VAR_project_id=<project id>
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="prefix=${{ values.name }}"
terraform plan
terraform apply
```
{%- endif %}

## Accessing the Sandbox
{%- if not (values.include_bastion or values.include_eks or values.include_rds) %}

No bastion, cluster or database is included. Set `include_bastion`,
`include_eks` or `include_rds` to `true` in `terraform.tfvars` to add one.
{%- endif %}
{%- if provider == "aws" %}

### Bastion host

```bash
aws ssm start-session --target "$(terraform output -raw bastion_instance_id)"
```

### Kubernetes

The API endpoint is private. Run `kubectl` from the bastion, or add your
address to `eks_public_access_cidrs`.

```bash
aws eks update-kubeconfig --name ${{ values.name }} --region ${{ values.region }}
kubectl get nodes
```

### Database

The master password is generated by RDS and kept in Secrets Manager:

```bash
terraform output rds_endpoint
aws secretsmanager get-secret-value \
  --secret-id "$(terraform output -raw rds_master_user_secret_arn)" \
  --query SecretString --output text
```

The database accepts connections from inside the VPC as user `sandbox_admin`.
{%- elif provider == "azure" %}

### Bastion host

Add your address to `bastion_allowed_cidrs`, apply, then:

```bash
terraform output -raw bastion_ssh_private_key > bastion.pem
chmod 600 bastion.pem
ssh -i bastion.pem azureuser@"$(terraform output -raw bastion_public_ip)"
```

The key pair is generated by Terraform and stored in the state.

### Kubernetes

The API server is private. Run `kubectl` from the bastion, or add your address
to `kubernetes_api_allowed_cidrs`.

```bash
az aks get-credentials \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name ${{ values.name }}
kubectl get nodes
```

### Database

```bash
terraform output postgresql_fqdn
terraform output -raw postgresql_admin_password
```

The server accepts connections from inside the virtual network as user
`sandbox_admin`.
{%- else %}

### Bastion host

```bash
gcloud compute ssh "$(terraform output -raw bastion_instance_name)" \
  --zone "$(terraform output -raw bastion_zone)" \
  --tunnel-through-iap
```

Your account needs the roles `roles/iap.tunnelResourceAccessor` and
`roles/compute.osLogin`.

### Kubernetes

The API accepts connections from the VPC network. Run `kubectl` from the
bastion, or add your address to `kubernetes_api_allowed_cidrs`.

```bash
gcloud container clusters get-credentials ${{ values.name }} --region ${{ values.region }}
kubectl get nodes
```

### Database

```bash
terraform output cloudsql_private_ip
terraform output -raw cloudsql_admin_password
```

The instance has a private IP address only and accepts encrypted connections
from inside the VPC network as user `sandbox_admin`.
{%- endif %}

## Costs

A sandbox costs money while it exists. The NAT gateway, the Kubernetes cluster
and the database are billed by the hour whether or not they are used. Destroy
the sandbox when it is no longer needed: run the workflow with the action
`destroy`.

## Repository Structure

```
${{ values.name }}/
├── .github/workflows/terraform.yaml   # Validation and deployment pipeline
├── docs/index.md                      # This documentation
├── modules/sandbox/                   # Network, bastion, Kubernetes and database
├── tests/sandbox.tftest.hcl           # Terraform tests against mocked providers
├── backend.tf                         # Remote state
├── main.tf                            # Calls modules/sandbox
├── outputs.tf
├── providers.tf
├── terraform.tfvars                   # The settings of this sandbox
├── variables.tf
├── versions.tf
├── .tflint.hcl                        # TFLint configuration
├── catalog-info.yaml                  # Backstage catalog entry
└── mkdocs.yml                         # TechDocs configuration
```

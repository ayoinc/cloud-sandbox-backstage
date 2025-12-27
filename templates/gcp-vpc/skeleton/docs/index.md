# ${{ values.name }}

Google Cloud Platform Virtual Private Cloud (VPC) infrastructure for the **${{ values.environment }}** environment in **${{ values.region }}**.

## Overview

This VPC provides a production-ready network foundation with:

- Custom VPC with four specialized subnets (public, private, database, GKE)
- Cloud NAT for secure outbound internet access from private resources
- Cloud Router with BGP for hybrid connectivity and dynamic routing
- VPC Flow Logs for comprehensive network monitoring and security auditing
- Identity-Aware Proxy (IAP) SSH access for secure bastion-less administration
- GKE-ready subnet with secondary IP ranges for pods and services
- Private Google Access for accessing Google APIs without public IPs
- Private Service Access for Cloud SQL, Memorystore, and other managed services

```d2
direction: right

title: {
  label: GCP VPC Architecture - ${{ values.name }}
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

gcp: Google Cloud Platform {
  style.fill: "#E8F0FE"
  style.stroke: "#1A73E8"

  vpc: VPC (${{ values.cidrRange }}) {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    router: Cloud Router {
      shape: hexagon
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
      label: "Cloud Router\nBGP ASN: 64514"
    }

    nat: Cloud NAT {
      shape: hexagon
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
      label: "Cloud NAT\nAuto IP Allocation"
    }

    public: Public Subnet {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
      label: "Public Subnet\nLoad Balancers\nBastion Hosts"
    }

    private: Private Subnet {
      style.fill: "#FCE4EC"
      style.stroke: "#C2185B"
      label: "Private Subnet\nApplication Workloads"
    }

    database: Database Subnet {
      style.fill: "#FFF3E0"
      style.stroke: "#FF9800"
      label: "Database Subnet\nCloud SQL\nMemorystore"
    }

    gke: GKE Subnet {
      style.fill: "#E1F5FE"
      style.stroke: "#0288D1"
      label: "GKE Subnet\nNodes + Pods + Services"
    }

    firewall: Firewall Rules {
      shape: shield
      style.fill: "#FFCDD2"
      style.stroke: "#D32F2F"
    }

    logs: Flow Logs {
      shape: cylinder
      style.fill: "#F3E5F5"
      style.stroke: "#7B1FA2"
    }

    router -> nat
    nat -> private
    nat -> database
    nat -> gke
    public -> firewall
    private -> firewall
    database -> firewall
    gke -> firewall
    vpc -> logs: captures
  }

  iap: Identity-Aware Proxy {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  psa: Private Service Access {
    shape: cylinder
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
    label: "Cloud SQL\nMemorystore\nAlloyDB"
  }

  iap -> vpc.private: SSH (22)
  vpc.database -> psa: VPC Peering
}

internet -> gcp.vpc.router
internet -> gcp.vpc.public
```

## Configuration Summary

| Setting              | Value                       |
| -------------------- | --------------------------- |
| VPC Name             | `${{ values.name }}`        |
| Primary CIDR Block   | `${{ values.cidrRange }}`   |
| Region               | `${{ values.region }}`      |
| GCP Project          | `${{ values.gcpProject }}`  |
| Environment          | `${{ values.environment }}` |
| Routing Mode         | `REGIONAL`                  |
| MTU                  | `1460`                      |
| Flow Logs            | Enabled                     |
| Cloud NAT            | Enabled                     |

## Network Layout

| Subnet Type | CIDR Range        | Purpose                                       | Private Google Access |
| ----------- | ----------------- | --------------------------------------------- | --------------------- |
| Public      | `/24` from CIDR   | Load balancers, NAT Gateway, bastion hosts    | Enabled               |
| Private     | `/24` from CIDR   | Application workloads, internal services      | Enabled               |
| Database    | `/24` from CIDR   | Cloud SQL, Memorystore, AlloyDB               | Enabled               |
| GKE         | `/20` from CIDR   | GKE cluster nodes                             | Enabled               |
| GKE Pods    | `10.100.0.0/16`   | Secondary range for Kubernetes pods           | N/A                   |
| GKE Services| `10.101.0.0/20`   | Secondary range for Kubernetes services       | N/A                   |

### Subnet Details

```
VPC CIDR: ${{ values.cidrRange }}

Public Subnet:   For internet-facing resources (load balancers, bastion hosts)
Private Subnet:  For internal application workloads
Database Subnet: For managed database services (Cloud SQL, Memorystore)
GKE Subnet:      For GKE cluster with secondary ranges for pods/services
```

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Native Tests**: Terraform test framework for infrastructure validation
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: On-demand checks for configuration drift
- **OIDC Authentication**: Secure, keyless authentication with GCP

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate\nTerraform Test"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nCost Estimate\n(per environment)"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

apply: Apply {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Deploy\nInfrastructure"
}

drift: Drift Detection {
  shape: oval
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Scheduled\nDrift Check"
}

pr -> validate -> security -> plan -> review -> apply
drift -> plan
```

### Pipeline Stages

| Stage            | Trigger                    | Description                                          |
| ---------------- | -------------------------- | ---------------------------------------------------- |
| Preflight        | All                        | Validate inputs, set environment matrix              |
| Validate         | All                        | Format check, init, validate                         |
| TFLint           | All                        | Terraform linting                                    |
| Terraform Tests  | All                        | Run native Terraform tests                           |
| Security Scans   | All                        | tfsec, Checkov, Trivy scans                          |
| Cost Estimation  | PR, Plan                   | Infracost breakdown per environment                  |
| Plan             | All                        | Generate and upload plan artifacts                   |
| Apply            | Manual, Push to main       | Deploy infrastructure                                |
| Destroy          | Manual with confirmation   | Destroy infrastructure (requires typing "DESTROY")   |
| Drift Detection  | Manual                     | Check for configuration drift                        |

---

## Prerequisites

### 1. GCP Project Setup

#### Enable Required APIs

```bash
# Enable required Google Cloud APIs
gcloud services enable compute.googleapis.com \
  --project=${{ values.gcpProject }}

gcloud services enable servicenetworking.googleapis.com \
  --project=${{ values.gcpProject }}

gcloud services enable iam.googleapis.com \
  --project=${{ values.gcpProject }}

gcloud services enable iamcredentials.googleapis.com \
  --project=${{ values.gcpProject }}

gcloud services enable cloudresourcemanager.googleapis.com \
  --project=${{ values.gcpProject }}
```

#### Create Workload Identity Pool

GitHub Actions uses Workload Identity Federation (OIDC) for secure, keyless authentication with GCP.

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

#### Create Service Account

```bash
# Create service account for Terraform
gcloud iam service-accounts create terraform-github-actions \
  --project="${{ values.gcpProject }}" \
  --display-name="Terraform GitHub Actions"

# Get the Workload Identity Pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe "github-pool" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --format="value(name)")

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  "terraform-github-actions@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --project="${{ values.gcpProject }}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/YOUR_ORG/YOUR_REPO"
```

#### Required IAM Permissions

Grant the service account the following roles:

```bash
# VPC and Networking permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-github-actions@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

# Firewall permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-github-actions@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/compute.securityAdmin"

# Service Networking (for Private Service Access)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-github-actions@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/servicenetworking.networksAdmin"

# Storage Admin (for Terraform state)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:terraform-github-actions@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

Or create a custom role with specific permissions:

```bash
gcloud iam roles create terraformVpcAdmin \
  --project="${{ values.gcpProject }}" \
  --title="Terraform VPC Admin" \
  --description="Custom role for Terraform VPC management" \
  --permissions="\
compute.networks.create,\
compute.networks.delete,\
compute.networks.get,\
compute.networks.list,\
compute.networks.update,\
compute.networks.updatePolicy,\
compute.subnetworks.create,\
compute.subnetworks.delete,\
compute.subnetworks.get,\
compute.subnetworks.list,\
compute.subnetworks.update,\
compute.routers.create,\
compute.routers.delete,\
compute.routers.get,\
compute.routers.list,\
compute.routers.update,\
compute.firewalls.create,\
compute.firewalls.delete,\
compute.firewalls.get,\
compute.firewalls.list,\
compute.firewalls.update,\
compute.addresses.create,\
compute.addresses.delete,\
compute.addresses.get,\
compute.addresses.list,\
compute.globalAddresses.create,\
compute.globalAddresses.delete,\
compute.globalAddresses.get,\
compute.globalAddresses.list,\
servicenetworking.services.addPeering,\
servicenetworking.services.get"
```

#### Create Terraform State Backend

```bash
# Create GCS bucket for Terraform state
gsutil mb -p ${{ values.gcpProject }} \
  -l ${{ values.region }} \
  -b on \
  gs://your-terraform-state-bucket

# Enable versioning
gsutil versioning set on gs://your-terraform-state-bucket

# Set lifecycle policy (optional - keep last 10 versions)
cat > lifecycle.json << 'EOF'
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {
        "numNewerVersions": 10,
        "isLive": false
      }
    }
  ]
}
EOF
gsutil lifecycle set lifecycle.json gs://your-terraform-state-bucket
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                             | Description                                          | Example                                                                    |
| ---------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER`   | Full path to Workload Identity Provider              | `projects/123456/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT`              | Service account email for Terraform                  | `terraform-github-actions@project.iam.gserviceaccount.com`                |
| `GCP_PROJECT_ID`                   | GCP Project ID                                       | `${{ values.gcpProject }}`                                                |
| `GCP_TERRAFORM_STATE_BUCKET`       | GCS bucket name for Terraform state                  | `my-terraform-state-bucket`                                                |
| `INFRACOST_API_KEY`                | API key for cost estimation (optional)               | `ico-xxxxxxxx`                                                             |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default                   |
| ------------ | ------------------ | ------------------------- |
| `GCP_REGION` | Default GCP region | `${{ values.region }}`    |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `dev-plan`  | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `staging-plan` | None                                              | -                        |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |
| `prod-plan` | None                                                 | -                        |
| `*-destroy` | Required reviewers                                   | Infrastructure team      |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Authenticate with GCP
gcloud auth application-default login

# Set the project
gcloud config set project ${{ values.gcpProject }}

# Initialize Terraform
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="prefix=${{ values.name }}/dev"

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate GCP credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Running the Pipeline

#### Automatic Triggers

| Trigger         | Actions                                          |
| --------------- | ------------------------------------------------ |
| Pull Request    | Validate, Security Scan, Plan, Cost Estimate     |
| Push to main    | Validate, Security Scan, Plan, Apply (all envs)  |
| Push to develop | Validate, Security Scan, Plan (dev only)         |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **Terraform CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

### Reference in Other Terraform

```hcl
# Reference the VPC network
data "google_compute_network" "main" {
  name    = "vpc-${{ values.name }}-${{ values.environment }}"
  project = "${{ values.gcpProject }}"
}

# Reference a specific subnet
data "google_compute_subnetwork" "private" {
  name    = "subnet-${{ values.name }}-private-${{ values.environment }}"
  region  = "${{ values.region }}"
  project = "${{ values.gcpProject }}"
}

# Reference GKE subnet with secondary ranges
data "google_compute_subnetwork" "gke" {
  name    = "subnet-${{ values.name }}-gke-${{ values.environment }}"
  region  = "${{ values.region }}"
  project = "${{ values.gcpProject }}"
}
```

### VPC Peering

```hcl
# Create VPC peering to another network
resource "google_compute_network_peering" "peer_to_other" {
  name         = "peer-to-other-vpc"
  network      = data.google_compute_network.main.self_link
  peer_network = google_compute_network.other.self_link

  export_custom_routes = true
  import_custom_routes = true
}
```

### Shared VPC (Optional)

```hcl
# Make this VPC a Shared VPC host
resource "google_compute_shared_vpc_host_project" "host" {
  project = "${{ values.gcpProject }}"
}

# Attach service project
resource "google_compute_shared_vpc_service_project" "service" {
  host_project    = "${{ values.gcpProject }}"
  service_project = "service-project-id"
}
```

---

## Security Features

### Firewall Rules

| Rule                   | Direction | Priority | Ports       | Source                    | Target              |
| ---------------------- | --------- | -------- | ----------- | ------------------------- | ------------------- |
| `allow-internal`       | Ingress   | 1000     | All         | VPC CIDR                  | All instances       |
| `allow-iap-ssh`        | Ingress   | 1000     | 22 (TCP)    | 35.235.240.0/20 (IAP)     | All instances       |
| `allow-http-https`     | Ingress   | 1000     | 80, 443     | 0.0.0.0/0                 | Tagged instances    |
| `allow-health-checks`  | Ingress   | 1000     | All TCP     | GCP LB ranges             | All instances       |
| `deny-all-ingress`     | Ingress   | 65534    | All         | 0.0.0.0/0                 | All (catch-all)     |

### Network Tags

Use these network tags to apply firewall rules:

| Tag            | Purpose                           |
| -------------- | --------------------------------- |
| `http-server`  | Allow HTTP (port 80) from internet|
| `https-server` | Allow HTTPS (port 443) from internet|

### Private Google Access

All subnets have Private Google Access enabled, allowing instances without external IPs to:

- Access Google Cloud APIs and services
- Pull container images from Container Registry/Artifact Registry
- Access Cloud Storage buckets
- Use other Google Cloud services

### Identity-Aware Proxy (IAP)

SSH access is allowed from IAP (35.235.240.0/20), enabling:

- Bastion-less SSH access to VMs
- Zero-trust security model
- Centralized access control via IAM
- Audit logging of all SSH sessions

```bash
# SSH to an instance via IAP
gcloud compute ssh INSTANCE_NAME \
  --zone=ZONE \
  --tunnel-through-iap \
  --project=${{ values.gcpProject }}
```

### VPC Flow Logs

Flow logs are enabled on all subnets with the following configuration:

| Setting              | Value                  |
| -------------------- | ---------------------- |
| Aggregation Interval | 5 seconds              |
| Sampling Rate        | 50%                    |
| Metadata             | Include all metadata   |

View flow logs in Cloud Logging:

```bash
gcloud logging read 'resource.type="gce_subnetwork"' \
  --project=${{ values.gcpProject }} \
  --limit=50
```

---

## Security Scanning

The pipeline includes three security scanning tools:

| Tool        | Purpose                                                   | Documentation                        |
| ----------- | --------------------------------------------------------- | ------------------------------------ |
| **tfsec**   | Static analysis for Terraform security misconfigurations  | [tfsec.dev](https://tfsec.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance | [checkov.io](https://www.checkov.io) |
| **Trivy**   | Comprehensive vulnerability scanner for IaC               | [trivy.dev](https://trivy.dev)       |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

### Common Security Findings

| Finding                           | Resolution                                      |
| --------------------------------- | ----------------------------------------------- |
| VPC Flow Logs not enabled         | Already configured in this template             |
| Firewall rule allows all traffic  | Internal traffic only - expected behavior       |
| Missing customer-managed encryption | GCP uses Google-managed keys by default       |
| Public access to resources        | Only applies to tagged instances (intentional)  |

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource              | Monthly Cost (USD) | Notes                          |
| --------------------- | ------------------ | ------------------------------ |
| VPC Network           | $0                 | No charge for VPC              |
| Subnets (4x)          | $0                 | No charge for subnets          |
| Cloud NAT             | ~$32 + data        | $0.044/hour + $0.045/GB        |
| Cloud Router          | $0                 | No charge for router           |
| VPC Flow Logs         | Variable           | Based on log volume ingested   |
| Firewall Rules        | $0                 | No charge for rules            |
| **Total Base Cost**   | ~$32-50/month      | Varies with NAT data transfer  |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                           | Description                              |
| -------------------------------- | ---------------------------------------- |
| `vpc_id`                         | VPC Network ID                           |
| `vpc_name`                       | VPC Network name                         |
| `vpc_self_link`                  | VPC Network self link                    |
| `public_subnet_id`               | Public subnet ID                         |
| `public_subnet_name`             | Public subnet name                       |
| `private_subnet_id`              | Private subnet ID                        |
| `private_subnet_name`            | Private subnet name                      |
| `database_subnet_id`             | Database subnet ID                       |
| `database_subnet_name`           | Database subnet name                     |
| `gke_subnet_id`                  | GKE subnet ID                            |
| `gke_subnet_name`                | GKE subnet name                          |
| `gke_pods_range_name`            | GKE pods secondary range name            |
| `gke_services_range_name`        | GKE services secondary range name        |
| `subnet_ids`                     | Map of subnet names to IDs               |
| `subnet_names`                   | Map of subnet types to names             |
| `subnet_self_links`              | Map of subnet types to self links        |
| `router_id`                      | Cloud Router ID                          |
| `router_name`                    | Cloud Router name                        |
| `nat_id`                         | Cloud NAT ID                             |
| `nat_name`                       | Cloud NAT name                           |
| `private_service_access_address` | Private Service Access address           |
| `vpc_info`                       | Summary of VPC configuration             |

Access outputs via:

```bash
terraform output vpc_id
terraform output vpc_name
terraform output -json subnet_ids
terraform output -json vpc_info
```

---

## Troubleshooting

### Authentication Issues

**Error: Unable to authenticate to Google Cloud**

```
Error: google: could not find default credentials
```

**Resolution:**

1. Verify Workload Identity Provider is configured correctly
2. Check `GCP_WORKLOAD_IDENTITY_PROVIDER` secret format:
   ```
   projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
   ```
3. Ensure service account has Workload Identity User role
4. Verify repository attribute mapping matches your repo: `attribute.repository/YOUR_ORG/YOUR_REPO`

### State Backend Issues

**Error: Failed to get existing workspaces**

```
Error: Failed to get existing workspaces: querying Cloud Storage failed
```

**Resolution:**

1. Verify GCS bucket exists and is accessible
2. Check service account has `roles/storage.admin` on the bucket
3. Ensure bucket name in `GCP_TERRAFORM_STATE_BUCKET` is correct
4. Verify the bucket is in the same project or accessible cross-project

### Permission Issues

**Error: Required 'compute.networks.create' permission**

```
Error: Error creating Network: googleapi: Error 403: Required 'compute.networks.create' permission for 'projects/...'
```

**Resolution:**

1. Verify service account has `roles/compute.networkAdmin` role
2. Check for organization policies that may restrict network creation
3. Ensure the Compute Engine API is enabled
4. Verify you're targeting the correct project

### Quota Issues

**Error: Quota exceeded**

```
Error: Error creating Subnetwork: googleapi: Error 403: Quota 'SUBNETWORKS' exceeded
```

**Resolution:**

1. Check current quota usage in Cloud Console
2. Request quota increase if needed:
   ```bash
   gcloud compute regions describe ${{ values.region }} \
     --project=${{ values.gcpProject }} \
     --format="table(quotas[].metric,quotas[].limit,quotas[].usage)"
   ```

### Pipeline Failures

**Security scan failing**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

**Terraform test failures**

Check the test output in artifacts and fix validation issues:

```bash
# Run tests locally
terraform init -backend=false
terraform test
```

### NAT Connectivity Issues

**VMs cannot reach the internet**

1. Verify Cloud NAT is enabled and healthy:
   ```bash
   gcloud compute routers nats describe nat-${{ values.name }}-${{ values.environment }} \
     --router=router-${{ values.name }}-${{ values.environment }} \
     --region=${{ values.region }} \
     --project=${{ values.gcpProject }}
   ```
2. Check that VMs are in subnets covered by NAT configuration
3. Verify no firewall rules are blocking egress traffic

---

## Related Templates

| Template                                        | Description                              |
| ----------------------------------------------- | ---------------------------------------- |
| [gcp-gke](/docs/default/template/gcp-gke)       | Google Kubernetes Engine cluster         |
| [gcp-cloudsql](/docs/default/template/gcp-cloudsql) | Cloud SQL database instance          |
| [gcp-memorystore](/docs/default/template/gcp-memorystore) | Memorystore Redis/Memcached    |
| [gcp-cloud-run](/docs/default/template/gcp-cloud-run) | Cloud Run serverless service       |
| [aws-vpc](/docs/default/template/aws-vpc)       | AWS VPC (equivalent)                     |
| [azure-vnet](/docs/default/template/azure-vnet) | Azure Virtual Network (equivalent)       |

---

## References

- [GCP VPC Documentation](https://cloud.google.com/vpc/docs)
- [Cloud NAT Overview](https://cloud.google.com/nat/docs/overview)
- [Cloud Router Documentation](https://cloud.google.com/network-connectivity/docs/router)
- [VPC Firewall Rules](https://cloud.google.com/vpc/docs/firewalls)
- [VPC Flow Logs](https://cloud.google.com/vpc/docs/flow-logs)
- [Private Google Access](https://cloud.google.com/vpc/docs/private-google-access)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.

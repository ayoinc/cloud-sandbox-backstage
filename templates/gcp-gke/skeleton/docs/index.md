# ${{ values.name }}

${{ values.description }}

## Overview

This GKE cluster provides a production-ready Kubernetes environment on Google Cloud Platform for the **${{ values.environment }}** environment. The cluster is managed entirely through Terraform with:

- **${{ values.clusterMode }}** mode for optimized resource management
- Workload Identity for secure pod-level IAM authentication
- Private cluster configuration with optional private endpoints
- Artifact Registry for container image storage
- Shielded GKE nodes with secure boot and integrity monitoring
- Network policies with Calico for pod-level security
- Automatic Kubernetes version upgrades via release channels

```d2
direction: right

title: {
  label: GKE Cluster Architecture
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
  style.stroke: "#4285F4"

  vpc: VPC Network {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    subnet: Subnet {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"

      gke: GKE Cluster (${{ values.name }}-${{ values.environment }}) {
        style.fill: "#FFF8E1"
        style.stroke: "#FFA000"

        control: Control Plane {
          shape: hexagon
          style.fill: "#FCE4EC"
          style.stroke: "#C2185B"
          label: "Managed by\nGoogle"
        }

        nodes: Node Pools {
          style.fill: "#E8F5E9"
          style.stroke: "#388E3C"

          primary: Primary Pool {
            label: "${{ values.machineType }}\n${{ values.nodeCount }} nodes"
          }
          additional: Additional Pools {
            label: "Optional\nWorkload-specific"
          }
        }

        workload: Workload Identity {
          shape: diamond
          style.fill: "#E1F5FE"
          style.stroke: "#0288D1"
        }

        control -> nodes: manages
        nodes -> workload: authenticates via
      }

      pods: Pods Range {
        shape: cylinder
        style.fill: "#F3E5F5"
        style.stroke: "#7B1FA2"
      }

      services: Services Range {
        shape: cylinder
        style.fill: "#F3E5F5"
        style.stroke: "#7B1FA2"
      }
    }
  }

  registry: Artifact Registry {
    shape: cylinder
    style.fill: "#FFEBEE"
    style.stroke: "#D32F2F"
    label: "Container\nImages"
  }

  iam: Cloud IAM {
    shape: diamond
    style.fill: "#E8EAF6"
    style.stroke: "#3F51B5"
  }

  logging: Cloud Logging {
    shape: document
    style.fill: "#FBE9E7"
    style.stroke: "#E64A19"
  }
}

internet -> gcp.vpc: "Cloud NAT"
gcp.vpc.subnet.gke.nodes -> gcp.registry: pulls images
gcp.vpc.subnet.gke.workload -> gcp.iam: authenticates
gcp.vpc.subnet.gke.nodes -> gcp.logging: sends logs
gcp.vpc.subnet -> gcp.vpc.subnet.pods: secondary range
gcp.vpc.subnet -> gcp.vpc.subnet.services: secondary range
```

## Configuration Summary

| Setting                  | Value                                                         |
| ------------------------ | ------------------------------------------------------------- |
| Cluster Name             | `${{ values.name }}-${{ values.environment }}`                |
| Cluster Mode             | `${{ values.clusterMode }}`                                   |
| Region                   | `${{ values.region }}`                                        |
| GCP Project              | `${{ values.gcpProject }}`                                    |
| Environment              | `${{ values.environment }}`                                   |
| Machine Type             | `${{ values.machineType }}` (Standard mode only)              |
| Initial Node Count       | `${{ values.nodeCount }}` (Standard mode only)                |
| Release Channel          | `REGULAR` (automatic Kubernetes upgrades)                     |
| Private Cluster          | Enabled (nodes on private network)                            |
| Workload Identity        | `${{ values.gcpProject }}.svc.id.goog`                        |
| Network Policy           | Enabled (Calico)                                              |

## Cluster Modes

### Autopilot Mode

GKE Autopilot is a fully managed Kubernetes experience where Google manages the cluster infrastructure:

- **Node management**: Automatic provisioning, scaling, and upgrades
- **Resource optimization**: Pay only for requested pod resources
- **Security hardening**: Built-in security best practices
- **Simplified operations**: No node pool management required

### Standard Mode

GKE Standard provides full control over cluster infrastructure:

- **Node pools**: Custom machine types and configurations
- **Scaling control**: Manual or autoscaling node pools
- **Specialized workloads**: Support for GPUs, preemptible/spot VMs
- **Fine-grained tuning**: Custom node configurations and taints

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Terraform Tests**: Native Terraform test framework
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: On-demand checks for configuration drift

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
  label: "Format Check\nTFLint\nValidate"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

test: Test {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Terraform\nTests"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nCost Estimate"
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
  label: "Deploy\nCluster"
}

pr -> validate -> security
security -> test
test -> plan -> review -> apply
```

### Pipeline Triggers

| Trigger      | Actions                                          |
| ------------ | ------------------------------------------------ |
| Pull Request | Validate, Security Scan, Test, Plan              |
| Push to main | Validate, Security Scan, Plan (all environments) |
| Manual       | Plan, Apply, Destroy, or Drift Detection         |

---

## Prerequisites

### 1. GCP Project Setup

#### Enable Required APIs

```bash
# Enable required GCP APIs
gcloud services enable container.googleapis.com --project=${{ values.gcpProject }}
gcloud services enable artifactregistry.googleapis.com --project=${{ values.gcpProject }}
gcloud services enable iam.googleapis.com --project=${{ values.gcpProject }}
gcloud services enable iamcredentials.googleapis.com --project=${{ values.gcpProject }}
gcloud services enable cloudresourcemanager.googleapis.com --project=${{ values.gcpProject }}
gcloud services enable compute.googleapis.com --project=${{ values.gcpProject }}
```

#### Create Workload Identity Federation Pool

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with GCP.

```bash
# Create the Workload Identity Pool (one-time setup per project)
gcloud iam workload-identity-pools create "github-actions" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create the OIDC provider
gcloud iam workload-identity-pools providers create-oidc "github" \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --display-name="GitHub OIDC Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

#### Create Service Account for GitHub Actions

```bash
# Create service account
gcloud iam service-accounts create github-actions-gke \
  --project="${{ values.gcpProject }}" \
  --display-name="GitHub Actions GKE Service Account"

# Get the Workload Identity Pool ID
export POOL_ID=$(gcloud iam workload-identity-pools describe github-actions \
  --project="${{ values.gcpProject }}" \
  --location="global" \
  --format="value(name)")

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  "github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --project="${{ values.gcpProject }}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/YOUR_ORG/YOUR_REPO"
```

#### Required IAM Permissions

Grant the service account these roles:

```bash
# GKE permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/container.admin"

# Compute permissions (for network resources)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/compute.networkAdmin"

# IAM permissions (for service accounts)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Artifact Registry permissions
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

# Storage permissions (for Terraform state)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

#### Detailed IAM Policy (for custom roles)

```json
{
  "Version": "1",
  "Statement": [
    {
      "Sid": "GKEManagement",
      "Effect": "Allow",
      "Action": [
        "container.clusters.create",
        "container.clusters.delete",
        "container.clusters.get",
        "container.clusters.getCredentials",
        "container.clusters.list",
        "container.clusters.update",
        "container.nodePools.create",
        "container.nodePools.delete",
        "container.nodePools.get",
        "container.nodePools.list",
        "container.nodePools.update",
        "container.operations.get",
        "container.operations.list"
      ],
      "Resource": "*"
    },
    {
      "Sid": "NetworkManagement",
      "Effect": "Allow",
      "Action": [
        "compute.networks.get",
        "compute.networks.use",
        "compute.subnetworks.get",
        "compute.subnetworks.use",
        "compute.subnetworks.useExternalIp"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ServiceAccountManagement",
      "Effect": "Allow",
      "Action": [
        "iam.serviceAccounts.actAs",
        "iam.serviceAccounts.create",
        "iam.serviceAccounts.delete",
        "iam.serviceAccounts.get",
        "iam.serviceAccounts.list",
        "iam.serviceAccounts.update"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ArtifactRegistry",
      "Effect": "Allow",
      "Action": [
        "artifactregistry.repositories.create",
        "artifactregistry.repositories.delete",
        "artifactregistry.repositories.get",
        "artifactregistry.repositories.list",
        "artifactregistry.repositories.update"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "storage.objects.create",
        "storage.objects.delete",
        "storage.objects.get",
        "storage.objects.list",
        "storage.objects.update"
      ],
      "Resource": "projects/_/buckets/YOUR_STATE_BUCKET/*"
    }
  ]
}
```

#### Create Terraform State Backend

```bash
# Create GCS bucket for Terraform state
gcloud storage buckets create gs://your-terraform-state-bucket \
  --project=${{ values.gcpProject }} \
  --location=${{ values.region }} \
  --uniform-bucket-level-access

# Enable versioning
gcloud storage buckets update gs://your-terraform-state-bucket \
  --versioning

# Set lifecycle policy (optional - clean up old versions)
cat > /tmp/lifecycle.json << 'EOF'
{
  "lifecycle": {
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
}
EOF

gcloud storage buckets update gs://your-terraform-state-bucket \
  --lifecycle-file=/tmp/lifecycle.json
```

### 2. VPC Network Setup

GKE requires a VPC network with secondary IP ranges for pods and services:

```bash
# Create VPC (if not exists)
gcloud compute networks create gke-network \
  --project=${{ values.gcpProject }} \
  --subnet-mode=custom

# Create subnet with secondary ranges
gcloud compute networks subnets create gke-subnet \
  --project=${{ values.gcpProject }} \
  --network=gke-network \
  --region=${{ values.region }} \
  --range=10.0.0.0/20 \
  --secondary-range=pods=10.4.0.0/14,services=10.8.0.0/20
```

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                            | Description                                      | Example                                                                                            |
| --------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `GCP_WORKLOAD_IDENTITY_PROVIDER`  | Full resource name of the Workload Identity pool | `projects/123456/locations/global/workloadIdentityPools/github-actions/providers/github`           |
| `GCP_SERVICE_ACCOUNT`             | Service account email                            | `github-actions-gke@${{ values.gcpProject }}.iam.gserviceaccount.com`                              |
| `GCP_PROJECT_ID`                  | GCP Project ID                                   | `${{ values.gcpProject }}`                                                                         |
| `GCP_TERRAFORM_STATE_BUCKET`      | GCS bucket for Terraform state                   | `your-terraform-state-bucket`                                                                      |
| `INFRACOST_API_KEY`               | API key for cost estimation (optional)           | `ico-xxxxxxxx`                                                                                     |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment  | Protection Rules                                     | Reviewers                |
| ------------ | ---------------------------------------------------- | ------------------------ |
| `dev`        | None                                                 | -                        |
| `dev-plan`   | None                                                 | -                        |
| `staging`    | Required reviewers                                   | Team leads               |
| `prod`       | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |
| `production` | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Initialize Terraform
terraform init

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

### Get Cluster Credentials

After deployment, connect to the cluster:

```bash
# Get kubectl credentials
gcloud container clusters get-credentials ${{ values.name }}-${{ values.environment }} \
  --region ${{ values.region }} \
  --project ${{ values.gcpProject }}

# Verify connection
kubectl get nodes
kubectl get namespaces
kubectl cluster-info
```

### Push Images to Artifact Registry

```bash
# Configure Docker authentication
gcloud auth configure-docker ${{ values.region }}-docker.pkg.dev

# Tag your image
docker tag myapp:latest \
  ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/myapp:latest

# Push to registry
docker push \
  ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/myapp:latest
```

### Deploy a Workload

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: myapp-sa
      containers:
        - name: myapp
          image: ${{ values.region }}-docker.pkg.dev/${{ values.gcpProject }}/${{ values.name }}-${{ values.environment }}/myapp:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

### Running the Pipeline

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **Terraform CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy action)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## Workload Identity

Workload Identity is the recommended way for workloads in GKE to access Google Cloud services. It binds Kubernetes service accounts to Google service accounts.

### Setup Workload Identity for an Application

#### 1. Create a Google Service Account

```bash
# Create the service account
gcloud iam service-accounts create my-app-sa \
  --project=${{ values.gcpProject }} \
  --display-name="My App Service Account"

# Grant required permissions (example: Cloud Storage access)
gcloud projects add-iam-policy-binding ${{ values.gcpProject }} \
  --member="serviceAccount:my-app-sa@${{ values.gcpProject }}.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

#### 2. Bind Kubernetes SA to Google SA

```bash
# Allow the Kubernetes service account to impersonate the Google service account
gcloud iam service-accounts add-iam-policy-binding \
  my-app-sa@${{ values.gcpProject }}.iam.gserviceaccount.com \
  --project=${{ values.gcpProject }} \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${{ values.gcpProject }}.svc.id.goog[default/my-app-sa]"
```

#### 3. Create Kubernetes Service Account

```yaml
# k8s-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: default
  annotations:
    iam.gke.io/gcp-service-account: my-app-sa@${{ values.gcpProject }}.iam.gserviceaccount.com
```

#### 4. Use in Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app-sa
      containers:
        - name: my-app
          image: my-app:latest
```

### Terraform Example

```hcl
# Create Google service account
resource "google_service_account" "app" {
  account_id   = "my-app"
  display_name = "My App Service Account"
}

# Grant permissions
resource "google_project_iam_member" "app_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Bind to Kubernetes service account
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/my-app-sa]"
}
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

| Finding                          | Resolution                                           |
| -------------------------------- | ---------------------------------------------------- |
| Private cluster not enabled      | Already configured in this template                  |
| Binary authorization disabled    | Enabled automatically for production                 |
| Network policy not enabled       | Already configured with Calico                       |
| Shielded nodes not enabled       | Already configured for Standard mode                 |
| Workload Identity not configured | Already configured in this template                  |
| Master authorized networks empty | Add authorized networks for production               |

### Configuring Security Exceptions

If you need to skip specific security checks, add comments in your Terraform:

```hcl
# tfsec:ignore:google-gke-enforce-pod-security-policy
resource "google_container_cluster" "example" {
  # ...
}
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

### Estimated Costs

**Autopilot Mode:**

| Resource                | Monthly Cost (USD)                |
| ----------------------- | --------------------------------- |
| GKE Autopilot (compute) | Variable (based on pod resources) |
| Artifact Registry       | ~$0.10/GB stored                  |
| Network Egress          | Variable (based on traffic)       |

**Standard Mode:**

| Resource                                     | Monthly Cost (USD) |
| -------------------------------------------- | ------------------ |
| GKE Cluster Management Fee                   | $0 (free tier)     |
| Node VMs (${{ values.machineType }} x ${{ values.nodeCount }}) | Variable by type   |
| Persistent Disks                             | ~$0.04/GB/month    |
| Artifact Registry                            | ~$0.10/GB stored   |
| Network Egress                               | Variable           |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                      | Description                                    |
| --------------------------- | ---------------------------------------------- |
| `cluster_id`                | GKE cluster ID                                 |
| `cluster_name`              | GKE cluster name                               |
| `cluster_endpoint`          | Kubernetes API endpoint (sensitive)            |
| `cluster_ca_certificate`    | Cluster CA certificate (sensitive)             |
| `cluster_location`          | Cluster region                                 |
| `cluster_mode`              | Cluster mode (autopilot or standard)           |
| `service_account_email`     | Node service account email                     |
| `artifact_registry_id`      | Artifact Registry repository ID                |
| `artifact_registry_url`     | Docker registry URL for push/pull              |
| `primary_node_pool_name`    | Primary node pool name (Standard mode)         |
| `workload_identity_pool`    | Workload Identity pool for the cluster         |
| `get_credentials_command`   | gcloud command to configure kubectl            |
| `gke_info`                  | Summary of cluster configuration               |

Access outputs via:

```bash
# Get all outputs
terraform output

# Get specific output
terraform output cluster_name
terraform output -raw get_credentials_command

# Get sensitive outputs
terraform output -json cluster_endpoint
```

---

## Troubleshooting

### Authentication Issues

**Error: Could not determine project from credentials**

```
Error: google: could not find default credentials
```

**Resolution:**

1. Verify Workload Identity Provider is configured correctly
2. Check `GCP_WORKLOAD_IDENTITY_PROVIDER` secret format:
   ```
   projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
   ```
3. Ensure the repository is allowed in the attribute mapping
4. Verify the service account has required permissions

### Cluster Creation Issues

**Error: Master authorized networks not configured**

```
Error: Private cluster has no master authorized networks
```

**Resolution:**
Add authorized networks to access the cluster:

```hcl
master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal VPC"
  }
]
```

**Error: Secondary IP range not found**

```
Error: Secondary IP range 'pods' not found in subnet
```

**Resolution:**
Ensure the VPC subnet has secondary ranges for pods and services:

```bash
gcloud compute networks subnets update gke-subnet \
  --add-secondary-ranges=pods=10.4.0.0/14,services=10.8.0.0/20 \
  --region=${{ values.region }}
```

### Node Pool Issues

**Error: Insufficient quota**

```
Error: Quota 'CPUS' exceeded. Limit: 24.0 in region us-central1.
```

**Resolution:**

1. Request a quota increase in the GCP Console
2. Use smaller machine types
3. Reduce node count

**Error: Preemptible VMs terminated**

Preemptible and Spot VMs can be terminated at any time. For production workloads:

1. Use regular VMs for critical workloads
2. Configure pod disruption budgets
3. Use node auto-provisioning for resilience

### Workload Identity Issues

**Error: Error getting service account**

```
Error: Error reading Service Account: googleapi: Error 403: Permission denied
```

**Resolution:**

1. Verify the Kubernetes service account has the annotation:
   ```yaml
   iam.gke.io/gcp-service-account: sa@project.iam.gserviceaccount.com
   ```
2. Verify the IAM binding exists:
   ```bash
   gcloud iam service-accounts get-iam-policy sa@project.iam.gserviceaccount.com
   ```
3. Wait a few minutes for IAM propagation

### State Backend Issues

**Error: Error locking state**

```
Error: Error locking state: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually unlock:
   ```bash
   terraform force-unlock LOCK_ID
   ```

### Pipeline Failures

**Security scan failing:**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

---

## Maintenance

### Kubernetes Version Upgrades

The cluster is configured with the `REGULAR` release channel, which provides:

- Automatic minor version upgrades
- Automatic patch version upgrades
- Maintenance windows respected

To check current version:

```bash
gcloud container clusters describe ${{ values.name }}-${{ values.environment }} \
  --region=${{ values.region }} \
  --format="value(currentMasterVersion)"
```

### Node Image Upgrades

Nodes are automatically upgraded when:

- New node images are available
- Within the maintenance window

To manually upgrade:

```bash
gcloud container clusters upgrade ${{ values.name }}-${{ values.environment }} \
  --region=${{ values.region }} \
  --node-pool=primary
```

---

## Related Templates

| Template                                          | Description                          |
| ------------------------------------------------- | ------------------------------------ |
| [gcp-vpc](/docs/default/template/gcp-vpc)         | Google Cloud VPC network             |
| [gcp-cloud-sql](/docs/default/template/gcp-cloud-sql) | Cloud SQL database                   |
| [gcp-cloud-run](/docs/default/template/gcp-cloud-run) | Cloud Run serverless containers      |
| [aws-eks](/docs/default/template/aws-eks)         | Amazon EKS Kubernetes (equivalent)   |
| [azure-aks](/docs/default/template/azure-aks)     | Azure AKS Kubernetes (equivalent)    |

---

## References

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [GKE Autopilot Overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)
- [Private Clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/private-cluster-concept)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions OIDC with GCP](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)

---

## Owner

This resource is owned by **${{ values.owner }}**.

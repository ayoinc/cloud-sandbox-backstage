# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Kubernetes Service (AKS) cluster provides a production-ready Kubernetes platform for the **${{ values.envName }}** environment in **${{ values.location }}**. The infrastructure is managed by Terraform with:

- Azure AD integration with RBAC for secure access control
- Multiple node pools (system, user, optional spot) for workload isolation
- Private Azure Container Registry with AcrPull permissions
- Log Analytics workspace with comprehensive diagnostics
- Cluster autoscaler for dynamic scaling
- Calico network policy for pod-level security
- Workload identity for secure Azure service access
- Optional Microsoft Defender for container security

```d2
direction: right

title: {
  label: Azure AKS Cluster Architecture
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

azure: Azure (${{ values.location }}) {
  style.fill: "#E3F2FD"
  style.stroke: "#0078D4"

  rg: Resource Group {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "rg-${{ values.name }}-${{ values.envName }}"
  }

  aad: Azure AD {
    shape: hexagon
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "Authentication\n& RBAC"
  }

  aks: AKS Cluster {
    style.fill: "#E3F2FD"
    style.stroke: "#0078D4"

    control: Control Plane {
      style.fill: "#FFF3E0"
      style.stroke: "#FF9800"
      label: "Managed Control Plane\nK8s ${{ values.kubernetesVersion }}"
    }

    system: System Node Pool {
      style.fill: "#E8F5E9"
      style.stroke: "#388E3C"
      label: "System Pool\n${{ values.nodeVmSize }}\nCritical Addons Only"
    }

    user: User Node Pool {
      style.fill: "#E3F2FD"
      style.stroke: "#1976D2"
      label: "User Pool\n${{ values.nodeVmSize }}\nApplication Workloads"
    }

    control -> system: schedules
    control -> user: schedules
  }

  acr: Container Registry {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "ACR\nPrivate Images"
  }

  law: Log Analytics {
    shape: cylinder
    style.fill: "#E8EAF6"
    style.stroke: "#3F51B5"
    label: "Monitoring\n& Diagnostics"
  }

  identity: Managed Identity {
    shape: hexagon
    style.fill: "#FFF8E1"
    style.stroke: "#FFA000"
    label: "User Assigned\nIdentity"
  }

  aad -> aks.control: RBAC
  aks -> acr: AcrPull
  aks -> law: diagnostics
  identity -> acr: pull images
  identity -> aks: manages
}

internet -> azure.aks.control: kubectl/API
```

---

## Configuration Summary

| Setting | Value |
| --- | --- |
| Cluster Name | `aks-${{ values.name }}-${{ values.envName }}` |
| Resource Group | `rg-${{ values.name }}-${{ values.envName }}` |
| Kubernetes Version | `${{ values.kubernetesVersion }}` |
| Location | `${{ values.location }}` |
| Environment | `${{ values.envName }}` |
| Network Plugin | `azure` (Azure CNI) |
| Network Policy | `calico` |
| Azure RBAC | Enabled |

### Node Pool Configuration

| Node Pool | VM Size | Initial Count | Min | Max | Purpose |
| --- | --- | --- | --- | --- | --- |
| System | Set per environment | Set per environment | - | - | Critical system workloads (CoreDNS, etc.) |
| User | `${{ values.nodeVmSize }}` | ${{ values.nodeCount }} | - | ${{ values.maxNodeCount }} | Application workloads |

The User pool values above apply to the `${{ values.envName }}` environment. Every pool of every environment is defined in `environments/*.tfvars`.

### Security Features

| Feature | Status | Description |
| --- | --- | --- |
| Azure AD Integration | Enabled | Managed Azure AD with RBAC |
| Local Accounts | Disabled | No shared admin certificate; every user signs in with Entra ID |
| Azure Policy Add-on | Enabled | Gatekeeper policies from Azure Policy |
| Workload Identity | Enabled | Pod-level Azure identity access |
| Network Policy | Calico | Pod-to-pod traffic control |
| Private ACR | Enabled | No admin credentials required |
| Diagnostic Logs | Enabled | Full audit and control plane logging |

---

## CI/CD Pipeline

`.github/workflows/terraform.yaml` runs on every push and pull request to `main`, and on demand from the **Actions** tab.

### Checks

These jobs need no cloud account and run from the first commit:

| Job             | What it does                                                                  |
| --------------- | ----------------------------------------------------------------------------- |
| Validate        | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` |
| TFLint          | Lints the root module and `modules/` with the AzureRM ruleset                 |
| Terraform Tests | Runs `tests/*.tftest.hcl` against a mocked provider                           |
| Security Scan   | Trivy and Checkov; any finding fails the job                                  |

### Deployment

These jobs sign in to Azure with OIDC. They are skipped until the repository secrets listed under [GitHub Repository Setup](#3-github-repository-setup) exist:

| Job             | Runs on                                              | What it does                                                       |
| --------------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Cost Estimate   | Pull requests, once `INFRACOST_API_KEY` is set       | Posts an Infracost breakdown on the pull request                   |
| Plan            | Pull requests, pushes to `main`, manual plan/apply   | Plans the target environment and adds the plan to the run summary  |
| Apply           | Pushes to `main`, manual apply                       | Applies the saved plan in the GitHub environment of the same name  |
| Destroy         | Manual destroy with `DESTROY` typed as confirmation  | Destroys the target environment                                    |
| Drift Detection | Manual drift-detection                               | Opens an issue when the deployed infrastructure has drifted        |

Pushes and pull requests target the `${{ values.envName }}` environment (`DEFAULT_ENVIRONMENT` in the workflow). The other environments are deployed from **Actions > Terraform > Run workflow**.

### Pipeline Workflow

```d2
direction: right

push: Push or pull request {
  shape: oval
}

checks: Checks {
  validate: Validate
  lint: TFLint
  test: Terraform Tests
  security: Security Scan
}

plan: Plan
apply: Apply {
  label: "Apply\n(main only)"
}

push -> checks -> plan -> apply
```

---

## Prerequisites

### 1. Azure Account Setup

#### Create Azure AD App Registration for OIDC

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with Azure.

```bash
# Set variables
GITHUB_ORG="your-github-org"
GITHUB_REPO="your-repo-name"
APP_NAME="github-actions-${{ values.name }}"

# Create Azure AD Application
az ad app create --display-name "$APP_NAME"

# Get the Application (client) ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get the Service Principal Object ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# Create federated credential for GitHub Actions
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create federated credential for pull requests (the Plan job)
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-actions-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create credentials for the environments the Apply and Destroy jobs run in
for env in dev staging prod; do
  az ad app federated-credential create --id $APP_ID --parameters '{
    "name": "github-actions-'$env'",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:'$env'",
    "audiences": ["api://AzureADTokenExchange"]
  }'
done
```

#### Assign Required Azure Permissions

The Service Principal needs these role assignments:

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Contributor on subscription (for resource creation)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# User Access Administrator (for RBAC assignments)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

#### Required IAM Permissions (Granular)

For least-privilege access, create a custom role with these permissions:

```json
{
  "Name": "AKS Terraform Deployer",
  "Description": "Custom role for deploying AKS via Terraform",
  "Actions": [
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.ContainerService/managedClusters/*",
    "Microsoft.ContainerRegistry/registries/*",
    "Microsoft.OperationalInsights/workspaces/*",
    "Microsoft.ManagedIdentity/userAssignedIdentities/*",
    "Microsoft.Authorization/roleAssignments/*",
    "Microsoft.Insights/diagnosticSettings/*",
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/read"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/YOUR_SUBSCRIPTION_ID"
  ]
}
```

#### Create Terraform State Backend

```bash
# Variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="${{ values.location }}"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

# Enable versioning for state recovery
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --enable-versioning true

# Assign Storage Blob Data Contributor to Service Principal
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
```

### 2. Azure AD Admin Group (Optional)

Create an Azure AD group for cluster administrators:

```bash
# Create admin group
az ad group create \
  --display-name "aks-${{ values.name }}-admins" \
  --mail-nickname "aks-${{ values.name }}-admins"

# Get the group Object ID
ADMIN_GROUP_ID=$(az ad group show --group "aks-${{ values.name }}-admins" --query id -o tsv)

# Add users to the group
az ad group member add \
  --group "aks-${{ values.name }}-admins" \
  --member-id USER_OBJECT_ID
```

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**. Until the four `AZURE_*` secrets exist the pipeline runs its checks and skips every job that talks to Azure:

| Secret                  | Description                                 | Example                                |
| ----------------------- | ------------------------------------------- | -------------------------------------- |
| `AZURE_CLIENT_ID`       | Application (client) ID of the app registration | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID`       | Directory (tenant) ID                       | `12345678-1234-1234-1234-123456789012` |
| `AZURE_SUBSCRIPTION_ID` | Subscription to deploy into                 | `12345678-1234-1234-1234-123456789012` |
| `AZURE_STORAGE_ACCOUNT` | Storage account that holds the Terraform state | `stterraformstate1234`              |
| `INFRACOST_API_KEY`     | Enables cost estimates on pull requests (optional) | `ico-xxxxxxxx`                  |

The state lives in resource group `rg-terraform-state`, container `tfstate`. Set the repository variables `TF_STATE_RESOURCE_GROUP` and `TF_STATE_CONTAINER` to use other names.

#### GitHub Environments

The Apply and Destroy jobs run in the GitHub environment named after their target: `dev`, `staging` or `prod`. GitHub creates an environment the first time a job uses it; add protection rules in **Settings > Environments** to require approval:

| Environment | Suggested protection rules                          |
| ----------- | --------------------------------------------------- |
| `dev`       | None                                                |
| `staging`   | Required reviewers                                  |
| `prod`      | Required reviewers, deployment branches: `main` only |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Initialize Terraform
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=YOUR_STORAGE_ACCOUNT" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=${{ values.name }}/dev/terraform.tfstate"

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate Azure permissions)
terraform apply -var-file=environments/dev.tfvars
```

### kubectl Access

Local accounts are disabled, so every user signs in with Entra ID and needs a Kubernetes role in Azure. Grant it once per user or group (or list admin groups in `admin_group_object_ids`):

```bash
az role assignment create \
  --role "Azure Kubernetes Service RBAC Cluster Admin" \
  --assignee <user-or-group-object-id> \
  --scope $(az aks show --resource-group rg-${{ values.name }}-${{ values.envName }} --name aks-${{ values.name }}-${{ values.envName }} --query id -o tsv)
```

Then configure kubectl (it uses [kubelogin](https://azure.github.io/kubelogin/) to sign in):

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group rg-${{ values.name }}-${{ values.envName }} \
  --name aks-${{ values.name }}-${{ values.envName }}

# Verify connection
kubectl get nodes

# Check namespaces
kubectl get namespaces

# View cluster info
kubectl cluster-info
```

### Deploy an Application

```bash
# Create a namespace
kubectl create namespace my-app

# Login to ACR
az acr login --name acr${{ values.name | replace("-", "") }}${{ values.envName }}

# Tag and push your image
docker tag myapp:latest acr${{ values.name | replace("-", "") }}${{ values.envName }}.azurecr.io/myapp:v1
docker push acr${{ values.name | replace("-", "") }}${{ values.envName }}.azurecr.io/myapp:v1

# Deploy application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: my-app
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
      containers:
      - name: myapp
        image: acr${{ values.name | replace("-", "") }}${{ values.envName }}.azurecr.io/myapp:v1
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
EOF

# Expose via LoadBalancer
kubectl expose deployment myapp \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080 \
  --namespace=my-app
```

### Running the Pipeline

#### Automatic Triggers

| Trigger        | Jobs                                                             |
| -------------- | ---------------------------------------------------------------- |
| Pull request   | Checks, Cost Estimate, Plan (`${{ values.envName }}`)            |
| Push to `main` | Checks, Plan and Apply (`${{ values.envName }}`)                 |

Plan, Apply and Cost Estimate are skipped while their secrets are missing.

#### Manual Deployment

1. Open the **Actions** tab
2. Select the **Terraform** workflow
3. Click **Run workflow**
4. Choose:
   - **action**: `plan`, `apply`, `destroy`, or `drift-detection`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: type `DESTROY` (destroy only)
5. Click **Run workflow**

A manual run fails straight away, naming the missing secrets, if the Azure credentials are not configured.

---

## Security Scanning

The Security Scan job runs two scanners and fails on any finding:

| Tool        | Scope                                                      | Run locally                                        |
| ----------- | ---------------------------------------------------------- | -------------------------------------------------- |
| **Trivy**   | Misconfigurations of severity MEDIUM and above             | `trivy config --severity CRITICAL,HIGH,MEDIUM .`   |
| **Checkov** | Policy checks for Terraform                                | `checkov --directory . --config-file .checkov.yaml` |

### Accepted Findings

Each exception is declared next to the resource it applies to, with its reason:

| Finding | Where | Reason |
| ------- | ----- | ------ |
| Trivy `AZU-0065`, Checkov `CKV_AZURE_115` | AKS cluster | The API server is public by default so `kubectl` works without a VNet connection; set `private_cluster_enabled` to change it |
| Trivy `AZU-0041`, Checkov `CKV_AZURE_6` | AKS cluster | API access is open by default and protected by Entra ID with Azure RBAC; set `api_server_authorized_ip_ranges` to restrict it |
| Checkov `CKV_AZURE_117` | AKS cluster | Node disks use platform-managed keys; a disk encryption set needs a customer-managed key in Key Vault |
| Checkov `CKV_AZURE_226` | AKS cluster | Ephemeral OS disks need a VM cache larger than the OS disk, which the offered D-series sizes lack |
| Checkov `CKV_AZURE_227` | AKS cluster and node pools | Encryption at host needs the `EncryptionAtHost` feature registered on the subscription; set `enable_host_encryption` once it is |
| Checkov `CKV_AZURE_139` | Container registry | The registry keeps its public endpoint so pipelines can push images; pulls need the `AcrPull` role and the admin user is disabled |
| Checkov `CKV_AZURE_233`, `CKV_AZURE_237`, `CKV_AZURE_164`, `CKV_AZURE_165`, `CKV_AZURE_166` | Container registry | Premium SKU features; zone redundancy and untagged-manifest cleanup switch on automatically with `acr_sku = "Premium"` |

### Suppressing a Finding

Fix the configuration where you can. To accept a finding, add a comment on the resource and state why:

```hcl
resource "azurerm_example" "this" {
  #checkov:skip=CKV_AZURE_123:Reason the check does not apply
  #trivy:ignore:AZU-0001 Reason the check does not apply
}
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource | Quantity | Monthly Cost (USD) |
| --- | --- | --- |
| AKS Cluster (Standard tier) | 1 | ~$73 (prod) / Free (dev) |
| System Node Pool VMs | ${{ values.nodeCount }}x ${{ values.nodeVmSize }} | Variable by VM size |
| User Node Pool VMs | ${{ values.nodeCount }}x ${{ values.nodeVmSize }} | Variable by VM size |
| Log Analytics Workspace | Per GB ingested | ~$2.30/GB |
| Container Registry (Standard) | 1 | ~$5/month |
| Load Balancer (Standard) | 1 | ~$18/month + data |
| **Estimated Base Cost** | - | ~$200-500/month |

**VM Pricing Examples (Pay-as-you-go, US East):**

| VM Size | vCPUs | Memory | Price/month |
| --- | --- | --- | --- |
| Standard_D2s_v3 | 2 | 8 GB | ~$70 |
| Standard_D4s_v3 | 4 | 16 GB | ~$140 |
| Standard_D8s_v3 | 8 | 32 GB | ~$280 |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output | Description |
| --- | --- |
| `resource_group_name` | Name of the resource group |
| `resource_group_id` | Resource group ID |
| `cluster_id` | AKS cluster resource ID |
| `cluster_name` | AKS cluster name |
| `cluster_fqdn` | AKS cluster FQDN |
| `kubernetes_version` | Kubernetes version |
| `node_resource_group` | Node resource group (MC_*) |
| `oidc_issuer_url` | OIDC issuer URL for workload identity |
| `kubelet_identity` | Kubelet managed identity |
| `identity_principal_id` | Cluster identity principal ID |
| `identity_client_id` | Cluster identity client ID |
| `acr_id` | Container Registry ID |
| `acr_name` | Container Registry name |
| `acr_login_server` | ACR login server URL |
| `log_analytics_workspace_id` | Log Analytics Workspace ID |
| `get_credentials_command` | Command to configure kubectl |
| `portal_url` | Azure Portal URL for the cluster |

Access outputs via:

```bash
# Get specific output
terraform output cluster_name
terraform output acr_login_server

# Get all outputs as JSON
terraform output -json

# Get kubectl credentials command
terraform output get_credentials_command
```

---

## Monitoring

### Azure Portal

Access cluster monitoring via Azure Portal:

```bash
# Get portal URL
terraform output portal_url
```

### Log Analytics Queries

Query cluster logs using Kusto Query Language (KQL):

```kusto
// Container errors in the last hour
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error" or LogEntry contains "Error"
| project TimeGenerated, LogEntry, ContainerID, Computer
| order by TimeGenerated desc
| take 100

// Pod restart events
KubePodInventory
| where TimeGenerated > ago(24h)
| where ContainerRestartCount > 0
| summarize RestartCount = sum(ContainerRestartCount) by Name, Namespace
| order by RestartCount desc

// Node CPU utilization
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "K8SNode" and CounterName == "cpuUsageNanoCores"
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

// Cluster autoscaler events
AzureDiagnostics
| where Category == "cluster-autoscaler"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Message = properties_s
| order by TimeGenerated desc
```

### Azure Monitor Alerts

Recommended alert rules:

| Alert | Condition | Severity |
| --- | --- | --- |
| Node CPU > 80% | Perf Counter cpuUsageNanoCores > 80% | Warning |
| Node Memory > 85% | Perf Counter memoryRssBytes > 85% | Warning |
| Pod Restart Count | ContainerRestartCount > 5 in 1h | Warning |
| Failed Pods | KubePodInventory where PodStatus == "Failed" | Error |
| API Server Errors | kube-apiserver log errors > 10/min | Critical |

---

## Troubleshooting

### Authentication Issues

**Error: AADSTS700024 - Client assertion is not within its valid time range**

```
Error: building AzureRM Client: obtain subscription() from Azure CLI: parsing json result from the Azure CLI: waiting for the Azure CLI: exit status 1
```

**Resolution:**

1. Verify the federated credential subject matches your GitHub context
2. Check that the environment name in GitHub matches the credential
3. Ensure system clocks are synchronized

```bash
# Verify federated credentials
az ad app federated-credential list --id $APP_ID
```

### Cluster Access Issues

**Error: Unable to connect to the server: dial tcp: lookup aks-xxx.hcp.region.azmk8s.io: no such host**

**Resolution:**

1. Verify cluster is running: `az aks show --resource-group RG_NAME --name CLUSTER_NAME --query provisioningState`
2. Refresh credentials: `az aks get-credentials --resource-group RG_NAME --name CLUSTER_NAME --overwrite-existing`
3. Check network connectivity to Azure

**Error: Unauthorized**

**Resolution:**

1. Verify you're in the admin Azure AD group
2. Check Azure RBAC role assignments on the cluster
3. Clear cached kubeconfig: `kubectl config delete-context CLUSTER_NAME`

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      .../terraform.tfstate
  Operation: OperationTypeApply
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually break the lock:

```bash
terraform force-unlock LOCK_ID
```

### Node Pool Issues

**Error: InsufficientSubnetSize**

**Resolution:**

1. Check subnet has enough IP addresses for nodes + pods
2. Azure CNI requires: (max_pods_per_node * node_count) + node_count IPs
3. Consider using a larger subnet CIDR

**Error: VMExtensionProvisioningError**

**Resolution:**

1. Check node pool VM size is available in the region
2. Verify quota limits: `az vm list-usage --location LOCATION`
3. Try a different VM size

### Pipeline Failures

**Security scan failing**

The job log lists each finding with its file and line. Fix the configuration, or accept the finding as described under [Security Scanning](#security-scanning).

**Terraform plan timeout**

Increase timeout for large clusters:

```yaml
- name: Plan
  run: terraform plan ...
  timeout-minutes: 30
```

---

## Node Pools

### System Pool

The system node pool runs critical Kubernetes components:

| Component | Description |
| --- | --- |
| CoreDNS | Cluster DNS resolution |
| kube-proxy | Network proxy |
| Azure CNI | Container networking |
| Metrics Server | Resource metrics |

System pool has `CriticalAddonsOnly=true:NoSchedule` taint to prevent user workloads.

### User Pool

The user pool is for application workloads:

- No taints by default (accepts all workloads)
- Autoscaling enabled
- Labeled with `nodepool-type=user`

### Spot Pool (Optional)

For cost savings on interruptible workloads:

```bash
# Enable spot pool via tfvars
create_spot_node_pool = true
spot_node_vm_size     = "Standard_D4s_v3"
spot_max_count        = 10
spot_max_price        = -1  # Pay up to on-demand price
```

Workloads must tolerate the spot taint:

```yaml
tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
nodeSelector:
  kubernetes.azure.com/scalesetpriority: spot
```

---

## Workload Identity

This cluster has workload identity enabled for secure Azure service access from pods.

### Setup for a Pod

```bash
# Create a managed identity for your app
az identity create \
  --name "id-myapp" \
  --resource-group "rg-${{ values.name }}-${{ values.envName }}"

# Get the client ID
CLIENT_ID=$(az identity show \
  --name "id-myapp" \
  --resource-group "rg-${{ values.name }}-${{ values.envName }}" \
  --query clientId -o tsv)

# Create federated credential
OIDC_ISSUER=$(terraform output -raw oidc_issuer_url)

az identity federated-credential create \
  --name "fc-myapp" \
  --identity-name "id-myapp" \
  --resource-group "rg-${{ values.name }}-${{ values.envName }}" \
  --issuer "$OIDC_ISSUER" \
  --subject "system:serviceaccount:my-namespace:my-service-account" \
  --audiences "api://AzureADTokenExchange"
```

### Configure Kubernetes ServiceAccount

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: my-namespace
  annotations:
    azure.workload.identity/client-id: "CLIENT_ID_HERE"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: my-namespace
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: my-service-account
      containers:
        - name: myapp
          image: myimage
```

---

## Related Templates

| Template | Description |
| --- | --- |
| [azure-vnet](/docs/default/template/azure-vnet) | Azure Virtual Network for AKS |
| [azure-acr](/docs/default/template/azure-acr) | Standalone Azure Container Registry |
| [azure-key-vault](/docs/default/template/azure-key-vault) | Azure Key Vault for secrets |
| [azure-sql](/docs/default/template/azure-sql) | Azure SQL Database |
| [azure-cosmos](/docs/default/template/azure-cosmos) | Azure Cosmos DB |
| [aws-eks](/docs/default/template/aws-eks) | Amazon EKS (equivalent) |
| [gcp-gke](/docs/default/template/gcp-gke) | Google GKE (equivalent) |

---

## References

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider - AKS](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)
- [Azure AD Workload Identity](https://azure.github.io/azure-workload-identity/docs/)
- [Calico Network Policies](https://docs.projectcalico.org/security/kubernetes-network-policy)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## Owner

This resource is owned by **${{ values.owner }}**.

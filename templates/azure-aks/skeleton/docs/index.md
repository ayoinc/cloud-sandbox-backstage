# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Kubernetes Service (AKS) cluster provides a production-ready Kubernetes platform for the **${{ values.environment }}** environment in **${{ values.location }}**. The infrastructure is managed by Terraform with:

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
    label: "rg-${{ values.name }}-${{ values.environment }}"
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
| Cluster Name | `aks-${{ values.name }}-${{ values.environment }}` |
| Resource Group | `rg-${{ values.name }}-${{ values.environment }}` |
| Kubernetes Version | `${{ values.kubernetesVersion }}` |
| Location | `${{ values.location }}` |
| Environment | `${{ values.environment }}` |
| Network Plugin | `azure` (Azure CNI) |
| Network Policy | `calico` |
| Azure RBAC | Enabled |

### Node Pool Configuration

| Node Pool | VM Size | Initial Count | Min | Max | Purpose |
| --- | --- | --- | --- | --- | --- |
| System | `${{ values.nodeVmSize }}` | ${{ values.nodeCount }} | 1 | ${{ values.maxNodeCount }} | Critical system workloads (CoreDNS, etc.) |
| User | `${{ values.nodeVmSize }}` | ${{ values.nodeCount }} | 1 | ${{ values.maxNodeCount }} | Application workloads |

### Security Features

| Feature | Status | Description |
| --- | --- | --- |
| Azure AD Integration | Enabled | Managed Azure AD with RBAC |
| Workload Identity | Enabled | Pod-level Azure identity access |
| Network Policy | Calico | Pod-to-pod traffic control |
| Private ACR | Enabled | No admin credentials required |
| Diagnostic Logs | Enabled | Full audit and control plane logging |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Terraform Tests**: Native Terraform testing framework
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: On-demand configuration drift checks

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#0078D4"
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
  style.fill: "#E8EAF6"
  style.stroke: "#3F51B5"
  label: "Terraform\nNative Tests"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#0078D4"
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
  label: "Deploy\nInfrastructure"
}

pr -> validate -> security -> test -> plan -> review -> apply
```

### Pipeline Triggers

| Trigger | Actions |
| --- | --- |
| Pull Request | Validate, Security Scan, Test, Plan, Cost Estimate |
| Push to main | Validate, Security Scan, Plan (all environments) |
| Manual (workflow_dispatch) | Plan, Apply, Destroy, or Drift Detection |

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

# Create additional credentials for environments
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

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description | Example |
| --- | --- | --- |
| `AZURE_CLIENT_ID` | Azure AD Application (client) ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_STORAGE_ACCOUNT` | Terraform state storage account name | `stterraformstatexxxx` |
| `INFRACOST_API_KEY` | API key for cost estimation (optional) | `ico-xxxxxxxx` |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules | Reviewers |
| --- | --- | --- |
| `dev` | None | - |
| `dev-plan` | None | - |
| `staging` | Required reviewers | Team leads |
| `staging-plan` | None | - |
| `prod` | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |
| `prod-plan` | None | - |
| `*-destroy` | Required reviewers | Infrastructure admins |

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

After the cluster is deployed, configure kubectl access:

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --name aks-${{ values.name }}-${{ values.environment }}

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
az acr login --name acr${{ values.name | replace("-", "") }}${{ values.environment }}

# Tag and push your image
docker tag myapp:latest acr${{ values.name | replace("-", "") }}${{ values.environment }}.azurecr.io/myapp:v1
docker push acr${{ values.name | replace("-", "") }}${{ values.environment }}.azurecr.io/myapp:v1

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
        image: acr${{ values.name | replace("-", "") }}${{ values.environment }}.azurecr.io/myapp:v1
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

---

## Security Scanning

The pipeline includes three security scanning tools:

| Tool | Purpose | Documentation |
| --- | --- | --- |
| **tfsec** | Static analysis for Terraform security misconfigurations | [tfsec.dev](https://tfsec.dev) |
| **Checkov** | Policy-as-code for infrastructure security and compliance | [checkov.io](https://www.checkov.io) |
| **Trivy** | Comprehensive vulnerability scanner for IaC | [trivy.dev](https://trivy.dev) |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

### Common Security Findings

| Finding | Severity | Resolution |
| --- | --- | --- |
| API server authorized IP ranges not configured | Medium | Configure `api_server_authorized_ip_ranges` for production |
| Azure Policy addon not enabled | Low | Enable Azure Policy addon if required by compliance |
| Network policy not enabled | Medium | Already configured with Calico in this template |
| Cluster has no resource quota | Low | Apply ResourceQuota objects to namespaces |
| Container images from untrusted registries | High | Use ACR and enable image scanning |

### Suppressing False Positives

Create a `.tfsec.yaml` file to suppress known false positives:

```yaml
# .tfsec.yaml
severity_overrides:
  azure-container-limit-authorized-ips: LOW

exclude:
  - azure-container-configured-network-policy  # Already using Calico
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

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

**Terraform plan timeout**

Increase timeout for large clusters:

```yaml
- name: Terraform Plan
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
  --resource-group "rg-${{ values.name }}-${{ values.environment }}"

# Get the client ID
CLIENT_ID=$(az identity show \
  --name "id-myapp" \
  --resource-group "rg-${{ values.name }}-${{ values.environment }}" \
  --query clientId -o tsv)

# Create federated credential
OIDC_ISSUER=$(terraform output -raw oidc_issuer_url)

az identity federated-credential create \
  --name "fc-myapp" \
  --identity-name "id-myapp" \
  --resource-group "rg-${{ values.name }}-${{ values.environment }}" \
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

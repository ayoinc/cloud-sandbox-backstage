# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Functions project provides serverless compute capabilities for event-driven applications in the **${{ values.environment }}** environment deployed to **${{ values.location }}**.

Key features include:

- Multiple trigger support (HTTP, Timer, Queue, Blob, Event Grid, Service Bus)
- Consumption, Premium, or Dedicated hosting plans
- Application Insights integration for monitoring and diagnostics
- Managed Identity for secure access to Azure resources
- Automatic scaling based on demand
- CI/CD pipeline with security scanning and cost estimation

```d2
direction: right

title: {
  label: Azure Functions Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

triggers: Event Sources {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  http: HTTP Trigger {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  timer: Timer Trigger {
    shape: hexagon
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  queue: Queue Trigger {
    shape: hexagon
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  blob: Blob Trigger {
    shape: hexagon
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
  }
}

function_app: Function App {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  plan: Service Plan (${{ values.skuTier }}) {
    style.fill: "#C8E6C9"
    style.stroke: "#2E7D32"
  }

  functions: Function Code {
    style.fill: "#A5D6A7"
    style.stroke: "#1B5E20"
    label: "${{ values.runtimeStack }} ${{ values.runtimeVersion }}"
  }

  identity: Managed Identity {
    shape: diamond
    style.fill: "#DCEDC8"
    style.stroke: "#558B2F"
  }

  plan -> functions
  functions -> identity
}

storage: Storage Account {
  shape: cylinder
  style.fill: "#E3F2FD"
  style.stroke: "#1565C0"
}

app_insights: Application Insights {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

key_vault: Key Vault {
  shape: cylinder
  style.fill: "#FFF8E1"
  style.stroke: "#F9A825"
}

outputs: Downstream Services {
  style.fill: "#ECEFF1"
  style.stroke: "#607D8B"

  cosmos: Cosmos DB
  servicebus: Service Bus
  api: External APIs
}

triggers.http -> function_app.functions
triggers.timer -> function_app.functions
triggers.queue -> function_app.functions
triggers.blob -> function_app.functions

function_app.functions -> storage: reads/writes
function_app.functions -> app_insights: telemetry
function_app.identity -> key_vault: secrets
function_app.functions -> outputs.cosmos
function_app.functions -> outputs.servicebus
function_app.functions -> outputs.api
```

## Configuration Summary

| Setting             | Value                             |
| ------------------- | --------------------------------- |
| Function App Name   | `func-${{ values.name }}-${{ values.environment }}` |
| Resource Group      | `rg-${{ values.name }}-${{ values.environment }}`   |
| Region              | `${{ values.location }}`          |
| Runtime Stack       | `${{ values.runtimeStack }}`      |
| Runtime Version     | `${{ values.runtimeVersion }}`    |
| SKU Tier            | `${{ values.skuTier }}`           |
| Environment         | `${{ values.environment }}`       |
| App Insights        | Enabled                           |
| Managed Identity    | System Assigned                   |

## Hosting Plans

| Plan        | Use Case                                    | Scaling                          | Cost Model            |
| ----------- | ------------------------------------------- | -------------------------------- | --------------------- |
| Consumption | Variable workloads, cost-sensitive          | Auto-scale (0 to many instances) | Pay-per-execution     |
| Premium     | Production workloads, VNet integration      | Pre-warmed instances             | Per-second billing    |
| Dedicated   | Existing App Service plan, consistent load  | Manual/auto-scale                | Fixed monthly cost    |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, linting, Terraform validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Terraform Tests**: Native Terraform test framework execution
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
  label: "Format Check\nTerraform Validate\nTFLint"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

test: Test {
  style.fill: "#E1BEE7"
  style.stroke: "#7B1FA2"
  label: "Terraform Test\nUnit Tests"
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
  label: "Deploy to\nAzure"
}

pr -> validate -> security
security -> test -> plan -> review -> apply
```

---

## Prerequisites

### 1. Azure Account Setup

#### Create Azure AD App Registration for OIDC

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with Azure.

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
APP_NAME="github-actions-${{ values.name }}"
GITHUB_ORG="your-github-org"
GITHUB_REPO="${{ values.name }}"

# Create Azure AD application
az ad app create --display-name "$APP_NAME" --query appId -o tsv

# Get the App ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Get the Object ID of the service principal
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

# Create federated credentials for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for environments
for ENV in dev staging prod; do
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters '{
      "name": "github-actions-'$ENV'",
      "issuer": "https://token.actions.githubusercontent.com",
      "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:'$ENV'",
      "audiences": ["api://AzureADTokenExchange"]
    }'
done
```

#### Required Azure Permissions

Assign the following roles to the service principal:

```bash
# Assign Contributor role at subscription level
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Assign User Access Administrator for managed identity operations (optional)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

**Minimum Required Permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ResourceGroupManagement",
      "Effect": "Allow",
      "Action": [
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Resources/subscriptions/resourceGroups/write",
        "Microsoft.Resources/subscriptions/resourceGroups/delete"
      ],
      "Resource": "*"
    },
    {
      "Sid": "FunctionAppManagement",
      "Effect": "Allow",
      "Action": [
        "Microsoft.Web/sites/*",
        "Microsoft.Web/serverfarms/*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "StorageManagement",
      "Effect": "Allow",
      "Action": [
        "Microsoft.Storage/storageAccounts/*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ApplicationInsights",
      "Effect": "Allow",
      "Action": [
        "Microsoft.Insights/components/*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "Microsoft.Storage/storageAccounts/blobServices/containers/read",
        "Microsoft.Storage/storageAccounts/blobServices/containers/write"
      ],
      "Resource": "arn:azure:storage:::rg-terraform-state/*"
    }
  ]
}
```

#### Create Terraform State Backend

```bash
# Create resource group for state
az group create \
  --name rg-terraform-state \
  --location ${{ values.location }}

# Create storage account for state (must be globally unique)
STORAGE_ACCOUNT_NAME="stterraformstate$(openssl rand -hex 4)"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group rg-terraform-state \
  --location ${{ values.location }} \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME

# Enable versioning for state recovery
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group rg-terraform-state \
  --enable-versioning true
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                   | Description                                | Example                              |
| ------------------------ | ------------------------------------------ | ------------------------------------ |
| `AZURE_CLIENT_ID`        | Azure AD application (client) ID           | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID`        | Azure AD tenant ID                         | `12345678-1234-1234-1234-123456789012` |
| `AZURE_SUBSCRIPTION_ID`  | Azure subscription ID                      | `12345678-1234-1234-1234-123456789012` |
| `AZURE_STORAGE_ACCOUNT`  | Storage account name for Terraform state   | `stterraformstateabc123`             |
| `INFRACOST_API_KEY`      | API key for cost estimation (optional)     | `ico-xxxxxxxx`                       |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable          | Description             | Default         |
| ----------------- | ----------------------- | --------------- |
| `AZURE_LOCATION`  | Default Azure region    | `eastus`        |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

---

## Usage

### Local Development

#### Prerequisites

Install the following tools:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) >= 4.x
- [Terraform](https://www.terraform.io/downloads) >= 1.9
- Runtime-specific SDK (${{ values.runtimeStack }} ${{ values.runtimeVersion }})

#### Function Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install Azure Functions Core Tools (if not installed)
# macOS
brew tap azure/functions
brew install azure-functions-core-tools@4

# Login to Azure
az login

# Create a new function (HTTP trigger example)
func new --name HttpTrigger --template "HTTP trigger" --authlevel anonymous

# Run functions locally
func start

# Test the function locally
curl http://localhost:7071/api/HttpTrigger?name=World
```

#### Infrastructure Development

```bash
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

# Apply changes (requires appropriate Azure credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Running the Pipeline

#### Automatic Triggers

| Trigger          | Actions                                          |
| ---------------- | ------------------------------------------------ |
| Pull Request     | Validate, Security Scan, Test, Plan, Cost Estimate |
| Push to main     | Validate, Security Scan, Test, Plan, Apply (dev)  |
| Push to develop  | Validate, Security Scan, Test, Plan              |

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

### Deploying Function Code

After infrastructure is deployed, deploy your function code:

```bash
# Using Azure Functions Core Tools
func azure functionapp publish func-${{ values.name }}-${{ values.environment }}

# Using Azure CLI
az functionapp deployment source config-zip \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --name func-${{ values.name }}-${{ values.environment }} \
  --src function-app.zip
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

| Finding                              | Resolution                                            |
| ------------------------------------ | ----------------------------------------------------- |
| Storage account allows public access | Set `public_network_access_enabled = false`           |
| HTTPS not enforced                   | Already configured (`https_only = true`)              |
| Missing encryption                   | Storage encryption enabled by default                 |
| Managed identity not enabled         | Already configured with System Assigned identity      |
| TLS version too low                  | Already configured (`min_tls_version = "1.2"`)        |

### Suppressing False Positives

Create a `.tfsec.yml` file in the root directory:

```yaml
# .tfsec.yml
minimum_severity: MEDIUM
exclude:
  - azure-storage-queue-services-logging-enabled
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource                    | Monthly Cost (USD)                    |
| --------------------------- | ------------------------------------- |
| Function App (Consumption)  | Pay-per-use (~$0.20 per million exec) |
| Function App (Premium EP1)  | ~$150/month                           |
| Storage Account (Standard)  | ~$2-5/month                           |
| Application Insights        | ~$2.30/GB ingested                    |
| **Total Base Cost (Consumption)** | ~$5-20/month (varies by usage)  |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                                  | Description                                    |
| --------------------------------------- | ---------------------------------------------- |
| `resource_group_name`                   | Name of the resource group                     |
| `function_app_id`                       | Function App resource ID                       |
| `function_app_name`                     | Function App name                              |
| `default_hostname`                      | Default hostname (without https://)            |
| `url`                                   | Full URL of the Function App                   |
| `storage_account_name`                  | Name of the storage account                    |
| `storage_account_primary_connection_string` | Primary connection string (sensitive)      |
| `app_insights_connection_string`        | Application Insights connection string         |
| `app_insights_instrumentation_key`      | Application Insights instrumentation key       |
| `principal_id`                          | Managed identity principal ID                  |
| `function_app_info`                     | Summary object with all configuration details  |

Access outputs via:

```bash
# Get specific output
terraform output url

# Get all outputs as JSON
terraform output -json

# Get sensitive values
terraform output -raw storage_account_primary_connection_string
```

---

## Monitoring

### Application Insights

Access monitoring data in the Azure Portal:

1. Navigate to **Resource Groups** > `rg-${{ values.name }}-${{ values.environment }}`
2. Select the **Application Insights** resource (`appi-${{ values.name }}-${{ values.environment }}`)
3. View:
   - **Live Metrics**: Real-time performance data
   - **Failures**: Exception tracking and analysis
   - **Performance**: Request duration and dependencies
   - **Logs**: Query telemetry with KQL

### Useful KQL Queries

```kusto
// Function execution failures in last 24 hours
requests
| where timestamp > ago(24h)
| where success == false
| summarize count() by name, resultCode
| order by count_ desc

// Average duration by function
requests
| where timestamp > ago(1h)
| summarize avg(duration), percentile(duration, 95) by name
| order by avg_duration desc

// Cold start analysis
customMetrics
| where name == "FunctionExecutionTimeMs"
| where timestamp > ago(1h)
| summarize avg(value), max(value), min(value) by bin(timestamp, 5m)
```

### Alerting

Configure alerts in Application Insights for:

- Function failures exceeding threshold
- Response time degradation
- Exception rate spikes
- Resource utilization limits

---

## Troubleshooting

### Authentication Issues

**Error: AADSTS700016: Application not found**

```
Error: AADSTS700016: Application with identifier 'xxx' was not found in the directory
```

**Resolution:**

1. Verify `AZURE_CLIENT_ID` secret is configured correctly
2. Check the Azure AD app registration exists
3. Ensure federated credentials are configured for your repository
4. Verify the correct tenant ID is used

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually break the lease:
   ```bash
   az storage blob lease break \
     --account-name $STORAGE_ACCOUNT_NAME \
     --container-name tfstate \
     --blob-name "${{ values.name }}/${{ values.environment }}/terraform.tfstate"
   ```

### Function App Issues

**Error: Function host is not running**

```
The function host is not running.
```

**Resolution:**

1. Check Application Insights for errors
2. Verify storage account connectivity
3. Review function app configuration settings
4. Check runtime version compatibility

### Deployment Issues

**Error: Deployment failed with status code 409**

```
Deployment failed with status code 409 (Conflict)
```

**Resolution:**

1. Check if another deployment is in progress
2. Wait for the current deployment to complete
3. Retry the deployment

### Pipeline Failures

**Security scan failing**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

---

## Related Templates

| Template                                                      | Description                         |
| ------------------------------------------------------------- | ----------------------------------- |
| [azure-container-apps](/docs/default/template/azure-container-apps) | Azure Container Apps for containers |
| [azure-aks](/docs/default/template/azure-aks)                 | Azure Kubernetes Service cluster    |
| [azure-cosmos-db](/docs/default/template/azure-cosmos-db)     | Azure Cosmos DB database            |
| [azure-service-bus](/docs/default/template/azure-service-bus) | Azure Service Bus messaging         |
| [azure-key-vault](/docs/default/template/azure-key-vault)     | Azure Key Vault for secrets         |
| [aws-lambda](/docs/default/template/aws-lambda)               | AWS Lambda (equivalent)             |
| [gcp-cloud-functions](/docs/default/template/gcp-cloud-functions) | GCP Cloud Functions (equivalent) |

---

## References

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure Functions Best Practices](https://docs.microsoft.com/en-us/azure/azure-functions/functions-best-practices)
- [Azure Functions Triggers and Bindings](https://docs.microsoft.com/en-us/azure/azure-functions/functions-triggers-bindings)
- [Application Insights for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-monitoring)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

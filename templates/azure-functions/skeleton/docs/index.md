# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Functions project provides serverless compute capabilities for event-driven applications in the **${{ values.envName }}** environment deployed to **${{ values.location }}**.

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
| Function App Name   | `func-${{ values.name }}-${{ values.envName }}` |
| Resource Group      | `rg-${{ values.name }}-${{ values.envName }}`   |
| Region              | `${{ values.location }}`          |
| Runtime Stack       | `${{ values.runtimeStack }}`      |
| Runtime Version     | `${{ values.runtimeVersion }}`    |
| SKU Tier            | `${{ values.skuTier }}`           |
| Storage Tier        | `${{ values.storageAccountTier }}` |
| Environment         | `${{ values.envName }}`       |
| App Insights        | {% if values.enableAppInsights %}Enabled (workspace-based){% else %}Disabled{% endif %} |
| Managed Identity    | System Assigned                   |

## Hosting Plans

| Plan        | Use Case                                    | Scaling                          | Cost Model            |
| ----------- | ------------------------------------------- | -------------------------------- | --------------------- |
| Consumption | Variable workloads, cost-sensitive          | Auto-scale (0 to many instances) | Pay-per-execution     |
| Premium     | Production workloads, VNet integration      | Pre-warmed instances             | Per-second billing    |
| Dedicated   | Existing App Service plan, consistent load  | Manual/auto-scale                | Fixed monthly cost    |

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

These jobs sign in to Azure with OIDC. They are skipped until the repository secrets listed under [GitHub Repository Setup](#2-github-repository-setup) exist:

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

# Let the pipeline read and write the state with its Entra ID identity
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group rg-terraform-state --query id -o tsv)

# Store this name in the AZURE_STORAGE_ACCOUNT repository secret
echo $STORAGE_ACCOUNT_NAME
```

### 2. GitHub Repository Setup

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

#### Prerequisites

Install the following tools:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) >= 4.x
- [Terraform](https://www.terraform.io/downloads) >= 1.7
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
# Initialize Terraform without the state backend
terraform init -backend=false

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test
```

To plan or apply from your machine, sign in with `az login`, initialize against the state backend as shown in the README, then:

```bash
terraform plan -var-file=environments/${{ values.envName }}.tfvars
terraform apply -var-file=environments/${{ values.envName }}.tfvars
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

### Deploying Function Code

This repository provisions the Function App; it holds no function code. After the infrastructure is deployed, publish your functions from the project that contains them:

```bash
# Using Azure Functions Core Tools
func azure functionapp publish func-${{ values.name }}-${{ values.envName }}

# Using Azure CLI
az functionapp deployment source config-zip \
  --resource-group rg-${{ values.name }}-${{ values.envName }} \
  --name func-${{ values.name }}-${{ values.envName }} \
  --src function-app.zip
```

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
| Trivy `AZU-0012`, Checkov `CKV_AZURE_59`, `CKV2_AZURE_33` | Storage account | The Functions host reaches its storage over the public endpoint; Consumption plans have no VNet integration |
| Checkov `CKV2_AZURE_40` | Storage account | The Functions host connects to its storage with the account key |
| Checkov `CKV2_AZURE_1` | Storage account | Data is encrypted with platform-managed keys; a customer-managed key needs a Key Vault |
| Checkov `CKV_AZURE_206` | Storage account | Locally redundant outside production to save cost; production is geo-redundant |
| Checkov `CKV_AZURE_225`, `CKV_AZURE_212` | Service plan | Zone redundancy and a minimum instance count do not apply to the Consumption and Basic SKUs |
| Checkov `CKV_AZURE_221` | Function App | HTTP-triggered functions are served from the public endpoint |

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

1. Navigate to **Resource Groups** > `rg-${{ values.name }}-${{ values.envName }}`
2. Select the **Application Insights** resource (`appi-${{ values.name }}-${{ values.envName }}`)
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
     --blob-name "${{ values.name }}/${{ values.envName }}/terraform.tfstate"
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

The job log lists each finding with its file and line. Fix the configuration, or accept the finding as described under [Security Scanning](#security-scanning).

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

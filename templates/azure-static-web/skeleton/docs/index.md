# ${{ values.name }}

${{ values.description }}

## Overview

This Azure Static Web App provides a production-ready hosting platform for your **${{ values.framework }}** application in the **${{ values.environment }}** environment. It includes:

- Global CDN with edge locations worldwide for fast content delivery
- Automatic HTTPS with free SSL certificates
- Staging/preview environments for pull request validation
- Optional Azure Functions API backend integration
- Built-in authentication providers (Azure AD, GitHub, Twitter)
- GitHub Actions CI/CD with OIDC authentication

```d2
direction: right

title: {
  label: Azure Static Web App Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Users {
  shape: person
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

cdn: Azure CDN {
  shape: cloud
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  edge1: Edge Location 1
  edge2: Edge Location 2
  edge3: Edge Location 3
}

swa: Static Web App {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  frontend: Frontend {
    style.fill: "#BBDEFB"
    style.stroke: "#1976D2"
    label: "${{ values.framework }}\nApplication"
  }

  auth: Authentication {
    shape: hexagon
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
    label: "Azure AD\nGitHub\nTwitter"
  }

  config: Configuration {
    shape: document
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
    label: "staticwebapp\n.config.json"
  }

  preview: Preview Envs {
    shape: cylinder
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
    label: "PR Previews"
  }
}

functions: Azure Functions {
  shape: hexagon
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "API Backend\n(Optional)"
}

storage: Azure Storage {
  shape: cylinder
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "Static Assets"
}

github: GitHub Actions {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "CI/CD Pipeline"
}

users -> cdn: HTTPS
cdn -> swa.frontend
swa.frontend -> swa.auth: validates
swa.frontend -> functions: /api/*
swa.frontend -> storage: assets
github -> swa: deploy
```

---

## Configuration Summary

| Setting                  | Value                                 |
| ------------------------ | ------------------------------------- |
| Name                     | `${{ values.name }}`                  |
| Framework                | `${{ values.framework }}`             |
| SKU Tier                 | `${{ values.skuTier }}`               |
| Location                 | `${{ values.location }}`              |
| Environment              | `${{ values.environment }}`           |
| Preview Environments     | Enabled                               |
| Owner                    | `${{ values.owner }}`                 |

### Framework Build Configuration

| Framework | App Location | Output Location | API Location |
| --------- | ------------ | --------------- | ------------ |
| React     | `/`          | `build`         | `api`        |
| Vue       | `/`          | `dist`          | `api`        |
| Angular   | `/`          | `dist/app`      | `api`        |
| Next.js   | `/`          | (SSR)           | -            |
| Gatsby    | `/`          | `public`        | `api`        |
| Hugo      | `/`          | `public`        | `api`        |
| Static    | `/`          | `/`             | -            |

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
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
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
  label: "Deploy\nInfrastructure"
}

pr -> validate -> security
security -> test
test -> plan -> review -> apply
```

### Pipeline Triggers

| Trigger               | Actions                                          |
| --------------------- | ------------------------------------------------ |
| Pull Request          | Validate, Security Scan, Test, Plan, Cost Estimate |
| Push to main          | Validate, Security Scan, Plan (all environments) |
| Manual (workflow_dispatch) | Plan, Apply, Destroy, or Drift Detection    |

---

## Prerequisites

### 1. Azure Account Setup

#### Create App Registration for OIDC

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with Azure.

```bash
# Set variables
SUBSCRIPTION_ID="your-subscription-id"
APP_NAME="github-actions-${{ values.name }}"
REPO="your-org/${{ values.name }}"

# Create App Registration
az ad app create --display-name "$APP_NAME"

# Get Application ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

# Create Service Principal
az ad sp create --id $APP_ID

# Get Service Principal Object ID
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)

# Create Federated Credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$REPO"':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create Federated Credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$REPO"':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create Federated Credential for environments
for ENV in dev staging prod; do
  az ad app federated-credential create \
    --id $APP_ID \
    --parameters '{
      "name": "github-env-'"$ENV"'",
      "issuer": "https://token.actions.githubusercontent.com",
      "subject": "repo:'"$REPO"':environment:'"$ENV"'",
      "audiences": ["api://AzureADTokenExchange"]
    }'
done
```

#### Assign Required Permissions

```bash
# Assign Contributor role at subscription level
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# For more restrictive access, use a resource group scope
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-${{ values.name }}-${{ values.environment }}"
```

#### Create Terraform State Backend

```bash
# Variables
RG_NAME="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="${{ values.location }}"

# Create Resource Group
az group create --name $RG_NAME --location $LOCATION

# Create Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Create Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT

# Enable soft delete for blobs
az storage blob service-properties delete-policy update \
  --account-name $STORAGE_ACCOUNT \
  --enable true \
  --days-retained 30

# Grant Storage Blob Data Contributor to Service Principal
STORAGE_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RG_NAME --query id -o tsv)
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope $STORAGE_ID
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                   | Description                              | Example                              |
| ------------------------ | ---------------------------------------- | ------------------------------------ |
| `AZURE_CLIENT_ID`        | App Registration Client ID               | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID`        | Azure AD Tenant ID                       | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID`  | Azure Subscription ID                    | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_STORAGE_ACCOUNT`  | Storage Account for Terraform state      | `stterraformstate1234`               |
| `INFRACOST_API_KEY`      | API key for cost estimation (optional)   | `ico-xxxxxxxx`                       |

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

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build locally
npm run preview
```

### Using SWA CLI

The Azure Static Web Apps CLI provides local emulation of the SWA environment:

```bash
# Install SWA CLI globally
npm install -g @azure/static-web-apps-cli

# Start local development with API
swa start ./build --api-location ./api

# Emulate authentication
swa start ./build --api-location ./api --run "npm run dev"

# Login to Azure (for deployment)
swa login

# Deploy to Azure
swa deploy ./build --deployment-token <token>
```

### Running Terraform Locally

```bash
# Initialize Terraform
terraform init

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires Azure credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                              |
| ------------ | ---------------------------------------------------- |
| Pull Request | Validate, Security Scan, Test, Plan, Cost Estimate   |
| Push to main | Validate, Security Scan, Plan (all environments)     |

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

## Custom Domain Configuration

Custom domains require the **Standard** SKU tier.

### Step 1: Configure DNS

Add a CNAME record pointing to your Static Web App's default hostname:

| Type  | Name                | Value                                     |
| ----- | ------------------- | ----------------------------------------- |
| CNAME | `www`               | `<app-name>.azurestaticapps.net`          |
| CNAME | `app`               | `<app-name>.azurestaticapps.net`          |

For apex domains (e.g., `example.com`), use an ALIAS record if your DNS provider supports it, or consider using Azure DNS.

### Step 2: Update Terraform Variables

```hcl
# In your .tfvars file
custom_domain = "www.example.com"
```

### Step 3: Apply Changes

```bash
terraform apply -var-file=environments/${{ values.environment }}.tfvars
```

### Domain Validation

Azure will automatically validate and issue an SSL certificate for your custom domain using CNAME delegation.

---

## Authentication Configuration

Azure Static Web Apps includes built-in authentication with multiple providers.

### Supported Providers

| Provider   | Route           | Configuration                   |
| ---------- | --------------- | ------------------------------- |
| Azure AD   | `/.auth/login/aad`    | App registration required  |
| GitHub     | `/.auth/login/github` | OAuth app required         |
| Twitter    | `/.auth/login/twitter`| Twitter app required       |
| Custom     | `/.auth/login/custom` | OpenID Connect provider    |

### Configuration File (staticwebapp.config.json)

Create a `staticwebapp.config.json` in your app's root directory:

```json
{
  "routes": [
    {
      "route": "/admin/*",
      "allowedRoles": ["admin"]
    },
    {
      "route": "/api/*",
      "allowedRoles": ["authenticated"]
    }
  ],
  "responseOverrides": {
    "401": {
      "statusCode": 302,
      "redirect": "/.auth/login/aad"
    }
  },
  "auth": {
    "identityProviders": {
      "azureActiveDirectory": {
        "registration": {
          "openIdIssuer": "https://login.microsoftonline.com/<tenant-id>/v2.0",
          "clientIdSettingName": "AAD_CLIENT_ID",
          "clientSecretSettingName": "AAD_CLIENT_SECRET"
        }
      }
    }
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Content-Security-Policy": "default-src 'self'"
  }
}
```

### Role-Based Access Control

Define custom roles in the Azure Portal or via API:

```bash
# Assign a role to a user
az staticwebapp users update \
  --name ${{ values.name }} \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --user-details user@example.com \
  --role admin
```

---

## Environment Variables

Configure application settings via Terraform or Azure Portal.

### Via Terraform

```hcl
resource "azurerm_static_web_app" "main" {
  # ... existing config

  app_settings = {
    "API_URL"           = "https://api.example.com"
    "FEATURE_FLAG"      = "true"
    "AAD_CLIENT_ID"     = var.aad_client_id
  }
}
```

### Via Azure CLI

```bash
az staticwebapp appsettings set \
  --name ${{ values.name }} \
  --resource-group rg-${{ values.name }}-${{ values.environment }} \
  --setting-names \
    "API_URL=https://api.example.com" \
    "FEATURE_FLAG=true"
```

---

## Outputs

After deployment, these outputs are available:

| Output                  | Description                               |
| ----------------------- | ----------------------------------------- |
| `resource_group_name`   | Name of the resource group                |
| `static_web_app_id`     | Static Web App resource ID                |
| `static_web_app_name`   | Static Web App name                       |
| `default_hostname`      | Default hostname (*.azurestaticapps.net)  |
| `url`                   | Full HTTPS URL of the application         |
| `api_key`               | Deployment token (sensitive)              |
| `build_config`          | Framework-specific build configuration    |
| `static_web_app_info`   | Summary of configuration                  |

Access outputs via:

```bash
# Get single output
terraform output default_hostname

# Get all outputs as JSON
terraform output -json

# Get sensitive output
terraform output -raw api_key
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

| Finding                        | Resolution                                        |
| ------------------------------ | ------------------------------------------------- |
| Missing HTTPS enforcement      | SWA enforces HTTPS by default                     |
| No WAF configured              | Consider Azure Front Door for WAF                 |
| Public access enabled          | Configure authentication if needed                |

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides cost estimates.

**Estimated monthly costs:**

| SKU Tier  | Included           | Overage                    | Monthly Base |
| --------- | ------------------ | -------------------------- | ------------ |
| Free      | 100GB bandwidth    | Not available              | $0           |
| Standard  | 100GB bandwidth    | $0.20/GB                   | ~$9          |

| Feature                 | Free Tier          | Standard Tier              |
| ----------------------- | ------------------ | -------------------------- |
| Custom domains          | 2                  | 5                          |
| SSL certificates        | Free (auto)        | Free (auto)                |
| Staging environments    | 3                  | 10                         |
| Max app size            | 250MB              | 500MB                      |
| Azure Functions         | Managed only       | Managed + Bring your own   |
| SLA                     | None               | 99.95%                     |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Troubleshooting

### Authentication Issues

**Error: AADSTS700016: Application not found**

```
AADSTS700016: Application with identifier 'xxx' was not found in the directory 'xxx'.
```

**Resolution:**

1. Verify the `AZURE_CLIENT_ID` secret is correct
2. Ensure the App Registration exists in the correct tenant
3. Check federated credentials are configured for your repository

---

**Error: OIDC token exchange failed**

```
Error: OIDC token exchange failed. Unable to get ACTIONS_ID_TOKEN_REQUEST_TOKEN
```

**Resolution:**

1. Verify workflow has `id-token: write` permission
2. Ensure federated credential subject matches (branch, PR, or environment)
3. Check the audience is `api://AzureADTokenExchange`

---

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. Check for stale lease on the blob:
   ```bash
   az storage blob lease break \
     --blob-name "${{ values.name }}/${{ values.environment }}/terraform.tfstate" \
     --container-name tfstate \
     --account-name $STORAGE_ACCOUNT
   ```

---

### Deployment Issues

**Error: Failed to deploy static site**

```
Error: Failed to deploy static site. Invalid build output.
```

**Resolution:**

1. Verify build output location matches framework configuration
2. Check that `npm run build` produces expected output directory
3. Ensure `staticwebapp.config.json` is valid JSON

---

**Error: Custom domain validation failed**

```
Error: Domain validation failed for 'www.example.com'
```

**Resolution:**

1. Verify CNAME record points to correct hostname
2. Wait for DNS propagation (can take up to 48 hours)
3. Check for conflicting DNS records

---

### Build Issues

**Error: API build failed**

```
Error: Failed to build API. Package.json not found.
```

**Resolution:**

1. Ensure `/api` directory contains a `package.json`
2. Check that API function files are valid
3. Verify `host.json` exists in the API directory

---

### Pipeline Failures

**Security scan failing on false positives**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

---

## Related Templates

| Template                                                    | Description                           |
| ----------------------------------------------------------- | ------------------------------------- |
| [azure-function](/docs/default/template/azure-function)     | Azure Functions serverless backend    |
| [azure-container-app](/docs/default/template/azure-container-app) | Azure Container Apps deployment |
| [azure-cdn](/docs/default/template/azure-cdn)               | Azure CDN for additional caching      |
| [azure-front-door](/docs/default/template/azure-front-door) | Azure Front Door with WAF             |
| [azure-cosmos-db](/docs/default/template/azure-cosmos-db)   | Azure Cosmos DB for data storage      |
| [aws-amplify](/docs/default/template/aws-amplify)           | AWS Amplify (alternative)             |
| [aws-cloudfront-s3](/docs/default/template/aws-cloudfront-s3) | AWS CloudFront + S3 (alternative)   |

---

## References

- [Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Static Web Apps CLI](https://azure.github.io/static-web-apps-cli/)
- [Terraform AzureRM Provider - Static Web App](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/static_web_app)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [SWA Authentication](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-authorization)
- [Custom Domains](https://learn.microsoft.com/en-us/azure/static-web-apps/custom-domain)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.

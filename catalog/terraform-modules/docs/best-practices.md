# Terraform Best Practices Guide

This guide provides comprehensive best practices for managing Terraform modules and infrastructure-as-code at scale.

## 1. Version Pinning & Locking

### Module Version Pinning

Always pin module and provider versions to ensure reproducible builds and prevent unexpected changes.

```hcl
terraform {
  required_version = ">= 1.5.0, < 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.15.0"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}
```

### .terraform.lock.hcl Importance

The lock file ensures provider checksums remain consistent across environments. Always commit it to version control.

```bash
# Initialize and generate lock file
terraform init

# Update lock file for specific provider
terraform providers lock -platform=linux_amd64 -platform=darwin_amd64 hashicorp/aws
```

### Upgrade Process

```bash
# Check for updates
terraform providers lock -verify

# Update specific provider
terraform providers lock hashicorp/aws

# Review changes before committing
git diff .terraform.lock.hcl
```

## 2. State Management

### Remote Backends

#### AWS S3 Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "environments/production/vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"

    # Enable versioning for state files
    versioning     = true

    # Use MFA for state access
    use_mfa        = true

    # Assume role for cross-account access
    role_arn       = "arn:aws:iam::123456789012:role/TerraformAdmin"
  }
}
```

#### Azure Blob Storage Backend

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestore"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"

    # Enable encryption and soft delete
    encryption_key = "${azurerm_key_vault_key.tfstate.id}"
  }
}
```

#### Google Cloud Storage Backend

```hcl
terraform {
  backend "gcs" {
    bucket  = "company-terraform-state"
    prefix  = "environments/production"

    # Enable encryption and versioning
    encryption_key = "${google_kms_crypto_key.terraform_state.id}"
    versioned      = true
  }
}
```

### State Locking

Enable state locking to prevent concurrent modifications and state corruption.

```bash
# AWS DynamoDB for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### State Encryption

Always encrypt state files at rest:

```hcl
# S3 server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
  }
}

# Azure customer-managed keys
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstatestore"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.tfstate.id
  }
}
```

### State Migration

```bash
# Migrate from local to remote state
terraform init -migrate-state

# Force migration without prompts
terraform init -migrate-state -force-copy

# Backup state before migration
terraform state pull > backup.terraform.tfstate
```

## 3. Secrets Management

### AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "database_password" {
  secret_id = "prod/database/password"
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  password = data.aws_secretsmanager_secret_version.database_password.secret_string
}

# Create secret with rotation
data "aws_secretsmanager_secret" "database_password" {
  name = "prod/database/password"

  rotation_rules {
    automatically_after_days = 30
  }
}
```

### Azure Key Vault

```hcl
data "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_function_app" "main" {
  app_settings = {
    "API_KEY" = "@Microsoft.KeyVault(SecretUri=${data.azurerm_key_vault_secret.api_key.id})"
  }
}
```

### GCP Secret Manager

```hcl
data "google_secret_manager_secret_version" "database_password" {
  secret = "database-password-prod"
  version = "1"
}

resource "google_sql_database_instance" "main" {
  root_password = data.google_secret_manager_secret_version.database_password.secret_data
}
```

### HashiCorp Vault

```hcl
data "vault_kv_secret_v2" "database" {
  mount = "secret"
  name  = "prod/database"
}

provider "aws" {
  access_key = data.vault_kv_secret_v2.database.data["aws_access_key"]
  secret_key = data.vault_kv_secret_v2.database.data["aws_secret_key"]
  region     = "us-east-1"
}
```

## 4. Security

### IAM Best Practices

```hcl
# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsTerraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:company/infrastructure:*"
          }
        }
      }
    ]
  })
}
```

### Security Scanning

```bash
# Install tfsec
brew install tfsec

# Run security scan
tfsec --format json --out tfsec-report.json

# Install Checkov
pip install checkov

# Run compliance scan
checkov -d . --framework terraform --output json
```

```hcl
# tfsec ignore example
resource "aws_security_group_rule" "example" {
  # tfsec:ignore:aws-vpc-no-excessive-port-access
  cidr_blocks = ["0.0.0.0/0"]
  type        = "ingress"
}

# Checkov skip example
resource "aws_s3_bucket" "public" {
  # checkov:skip=CKV_AWS_21:Public access required for static website
  bucket = "public-website-bucket"
}
```

## 5. Code Organization

### Mono-repo Structure

```
infrastructure/
├── modules/
│   ├── networking/
│   │   ├── vpc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── security-groups/
│   ├── compute/
│   │   ├── eks/
│   │   └── ec2/
│   └── storage/
│       └── rds/
├── environments/
│   ├── global/
│   │   └── iam/
│   │       ├── main.tf
│   │       └── terraform.tfvars
│   ├── production/
│   │   ├── us-east-1/
│   │   │   ├── vpc/
│   │   │   ├── eks/
│   │   │   └── data/
│   │   └── us-west-2/
│   │       └── vpc/
│   └── staging/
│       └── us-east-1/
│           └── vpc/
├── policies/
│   ├── sentinel/
│   └── rego/
└── scripts/
    └── setup-backend.sh
```

### Multi-repo Structure

```
terraform-modules/
├── terraform-aws-vpc/
├── terraform-aws-eks/
└── terraform-aws-rds/

terraform-environments/
├── production/
│   ├── vpc/
│   ├── eks/
│   └── rds/
└── staging/
    └── vpc/
```

### Workspaces Strategy

```bash
# Create workspaces per environment
terraform workspace new production
terraform workspace new staging
terraform workspace new development

# Use in code
data "aws_caller_identity" "current" {}

locals {
  environment = terraform.workspace
  state_key   = "environments/${local.environment}/terraform.tfstate"
}
```

## 6. Naming Conventions

### Resource Naming

```hcl
# Bad
resource "aws_instance" "foo" {
  tags = {
    Name = "test server"
  }
}

# Good
resource "aws_instance" "production_web_server" {
  tags = {
    Name        = "prod-web-01"
    Environment = "production"
    Application = "web-app"
    ManagedBy   = "terraform"
  }
}
```

### Variable Naming

```hcl
# Variables
variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable NAT gateway for private subnets"
  default     = true
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of allowed CIDR blocks"
  default     = []
}
```

### Output Naming

```hcl
# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}
```

### Tagging Strategy

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Terraform   = "true"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project-name}-logs-${var.environment}"

  tags = merge(local.common_tags, {
    Type = "logs"
  })
}
```

## 7. Testing

### Unit Testing

```bash
# Format validation
terraform fmt -check -recursive

# Configuration validation
terraform validate

# Linting with tflint
tflint --init
tflint --format compact
```

### Integration Testing

```go
// terratest example
package test

import (
  "testing"
  "github.com/gruntwork-io/terratest/modules/terraform"
  "github.com/stretchr/testify/assert"
)

func TestTerraformAwsVpc(t *testing.T) {
  terraformOptions := &terraform.Options{
    TerraformDir: "./modules/vpc",
    VarFiles:     []string{"../environments/production/terraform.tfvars"},
  }

  defer terraform.Destroy(t, terraformOptions)
  terraform.InitAndApply(t, terraformOptions)

  vpcID := terraform.Output(t, terraformOptions, "vpc_id")
  assert.NotNil(t, vpcID)
}
```

### Policy Testing

```hcl
# Sentinel policy
# policies/sentinel/enforce-tagging.sentinel

import "tfconfig"
import "tfplan"

# Rule: All resources must have required tags
required_tags = ["Environment", "Project", "CostCenter"]

# Check all AWS resources
aws_resources = plan.find_resources("aws_*")

main = rule {
  all aws_resources as _, instances {
    all instances as _, resource {
      all required_tags as tag {
        resource.applied.tags contains tag
      }
    }
  }
}

# OPA policy
# policies/rego/enforce_tagging.rego

package terraform.policy

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  not resource.change.after.tags.Environment
  msg = sprintf("Resource %s missing Environment tag", [resource.address])
}
```

## 8. Documentation

### Module Documentation Standards

````hcl
# modules/vpc/main.tf
/**
 * # VPC Module
 *
 * Creates a VPC with public and private subnets across multiple AZs.
 *
 * ## Features
 * - Multi-AZ deployment
 * - NAT Gateways for private subnets
 * - VPC Flow Logs
 * - Network ACLs
 *
 * ## Usage
 *
 * ```hcl
 * module "vpc" {
 *   source = "terraform-aws-modules/vpc/aws"
 *
 *   vpc_cidr_block = "10.0.0.0/16"
 *   enable_nat_gateway = true
 * }
 * ```
 *
 * ## Requirements
 *
 * - Terraform >= 1.0
 * - AWS Provider >= 5.0
 */

# modules/vpc/variables.tf
variable "vpc_cidr_block" {
  type        = string
  description = <<EOF
    CIDR block for the VPC. Must be a valid IPv4 CIDR block.
    Example: "10.0.0.0/16"
  EOF

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}
````

### Automated Documentation

```bash
# Generate README with terraform-docs
terraform-docs markdown table --output-file README.md --output-mode inject ./modules/vpc

# Pre-commit hook for terraform-docs
cat > .pre-commit-config.yaml <<EOF
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: v0.17.0
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./modules/vpc"]
EOF
```

## 9. CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraform
          aws-region: us-east-1

      - name: Terraform Format
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Security Scan
        run: |
          tfsec .
          checkov -d . --framework terraform

      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Format and Style  
            ❌  \`\`\`terraform fmt -check -recursive\`\`\`  

            #### Terraform Initialization ⚙️\`success\`  

            #### Terraform Validation  \`success\`  

            #### Terraform Plan  \`${{ steps.plan.outcome }}\`  

            <details><summary>Show Plan</summary>\n\n            \`\`\`terraform\n            ${process.env.PLAN}\n            \`\`\`
            </details>`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
```

### GitLab CI

```yaml
# .gitlab-ci.yml
image: hashicorp/terraform:1.6.0

stages:
  - validate
  - test
  - security
  - plan
  - apply

variables:
  TF_ROOT: '${CI_PROJECT_DIR}/environments/${ENVIRONMENT}'

.terraform: &terraform
  before_script:
    - cd ${TF_ROOT}
    - terraform --version
    - terraform init

validate:
  <<: *terraform
  stage: validate
  script:
    - terraform fmt -check -recursive
    - terraform validate

test:
  stage: test
  script:
    - go test ./test/... -v

security:
  <<: *terraform
  stage: security
  script:
    - tfsec .
    - checkov -d . --framework terraform

plan:
  <<: *terraform
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 1 week

apply:
  <<: *terraform
  stage: apply
  script:
    - terraform apply -auto-approve tfplan
  when: manual
  only:
    - main
```

### Atlantis Integration

```yaml
# atlantis.yaml
version: 3
automerge: true
parallel_apply: true
delete_source_branch_on_merge: true

projects:
  - name: production
    dir: environments/production
    workspace: production
    autoplan:
      enabled: true
      when_modified: ['*.tf*', '../modules/**/*.tf*']
    workflow: production

  - name: staging
    dir: environments/staging
    workspace: staging
    autoplan:
      enabled: true
    workflow: staging

workflows:
  production:
    plan:
      steps:
        - run: terraform fmt -check -recursive
        - run: terraform validate
        - run: tfsec .
        - run: checkov -d . --framework terraform
        - plan
    apply:
      steps:
        - apply

  staging:
    plan:
      steps:
        - plan
    apply:
      steps:
        - apply
```

## 10. Performance

### Refresh Strategies

```bash
# Skip refresh for faster plans
terraform plan -refresh=false

# Target specific resources
terraform plan -target=aws_instance.web

# Parallelism control
export TF_CLI_ARGS_plan="-parallelism=20"
terraform plan
```

### Plan Files

```bash
# Generate plan file
terraform plan -out=tfplan -detailed-exitcode

# Show plan in JSON format
terraform show -json tfplan > plan.json

# Apply saved plan
terraform apply tfplan
```

### Resource Targeting

```bash
# Target specific resources for faster operations
terraform plan -target=module.vpc -target=module.eks

# Exclude resources
terraform plan -target='!module.legacy_app'
```

## 11. Team Collaboration

### Code Review Process

1. **Pre-commit checks**: Format, validate, lint
2. **Plan validation**: Review `terraform plan` output
3. **Security scanning**: Ensure no vulnerabilities
4. **Cost estimation**: Review resource costs
5. **Peer review**: Require 2+ approvals

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.6
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_docs
      - id: terraform_tfsec
      - id: checkov
```

### CODEOWNERS

```
# .github/CODEOWNERS
*                       @infrastructure-team
/environments/production/*    @infrastructure-leads
/modules/networking/*   @networking-team
/modules/security/*     @security-team
```

## 12. Disaster Recovery

### State Backup

```bash
# Automated daily backup
#!/bin/bash
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="company-terraform-state-backups"

# Backup all state files
aws s3 cp s3://company-terraform-state/ s3://${S3_BUCKET}/${BACKUP_DATE}/ \
  --recursive \
  --sse aws:kms

# Keep last 30 days
aws s3 ls s3://${S3_BUCKET}/ | head -n -30 | awk '{print $2}' | while read -r date; do
  aws s3 rm s3://${S3_BUCKET}/${date} --recursive
done
```

### Recovery Procedures

```bash
# Restore from backup
aws s3 cp s3://terraform-state-backups/20231215_090000/ s3://company-terraform-state/ \
  --recursive

# Import resources if state is lost
terraform import aws_vpc.main vpc-0abcd1234efgh5678
terraform import aws_subnet.private_subnet_a subnet-0abcd1234efgh5678

# Rebuild state with targeted apply
terraform apply -target=module.vpc -refresh-only
```

## 13. Cost Management

### Infracost Integration

```yaml
# .github/workflows/infracost.yml
name: Infracost
on: [pull_request]

jobs:
  infracost:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Infracost
        uses: infracost/actions/setup@v2
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Generate cost estimate
        run: |
          infracost breakdown --path=. \
            --format=json \
            --out-file=/tmp/infracost.json

      - name: Post PR comment
        run: |
          infracost comment github --path=/tmp/infracost.json \
            --repo=$GITHUB_REPOSITORY \
            --pull-request=${{ github.event.pull_request.number }} \
            --github-token=${{ github.token }} \
            --behavior=update
```

### Cost Allocation Tags

```hcl
# Enable AWS cost allocation tags
resource "aws_ce_cost_allocation_tag" "project" {
  tag_key = "Project"

  type = "UserDefined"
  status = "Active"
}

resource "aws_ce_cost_allocation_tag" "cost_center" {
  tag_key = "CostCenter"

  type = "UserDefined"
  status = "Active"
}

# Apply tags to all resources
provider "aws" {
  default_tags {
    tags = {
      Project     = var.project_name
      CostCenter  = var.cost_center
      Environment = var.environment
    }
  }
}
```

## 14. Monitoring

### Drift Detection

```hcl
# Using driftctl
resource "null_resource" "drift_detection" {
  provisioner "local-exec" {
    command = <<EOF
      driftctl scan \
        --from tfstate://terraform.tfstate \
        --output json://drift.json \
        --deep
    EOF
  }
}

# CloudWatch alarm for state changes
resource "aws_cloudwatch_metric_alarm" "state_changes" {
  alarm_name          = "terraform-state-changes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    BucketName = "company-terraform-state"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Compliance Monitoring

```python
# AWS Config Rule for Terraform compliance
import json

def lambda_handler(event, context):
    configuration_item = event['configurationItem']

    # Check if resource has Terraform tags
    tags = configuration_item.get('tags', {})

    if not tags.get('ManagedBy') == 'terraform':
        return {
            'complianceType': 'NON_COMPLIANT',
            'annotation': 'Resource not managed by Terraform'
        }

    return {
        'complianceType': 'COMPLIANT',
        'annotation': 'Resource managed by Terraform'
    }
```

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices Blog](https://www.hashicorp.com/blog/terraform-best-practices)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Infracost Documentation](https://www.infracost.io/docs/)

For questions or contributions to this guide, please contact the Infrastructure Team.

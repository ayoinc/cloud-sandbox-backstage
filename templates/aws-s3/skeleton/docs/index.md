# ${{ values.name }}

${{ values.description }}

AWS S3 bucket infrastructure for the **${{ values.environment }}** environment in **${{ values.aws_region }}**.

## Overview

This S3 bucket provides enterprise-grade object storage with comprehensive security and lifecycle management:

- **Server-side encryption** using ${{ values.encryption }} for data at rest
- **Versioning** ${{ values.versioning | ternary("enabled for object recovery and protection", "disabled for this bucket") }}
- **Lifecycle policies** for automated storage class transitions and cost optimization
- **Public access blocking** enabled by default for security compliance
- **Access logging** for audit trails and security monitoring
- **CORS support** for web application integration

```d2
direction: right

title: {
  label: AWS S3 Bucket Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

clients: Clients {
  shape: cloud
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  apps: Applications
  cli: AWS CLI
  sdk: AWS SDKs
}

bucket: S3 Bucket (${{ values.name }}) {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  storage: Storage Classes {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"

    standard: STANDARD
    ia: STANDARD_IA
    glacier: GLACIER
  }

  features: Features {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    versioning: Versioning
    encryption: Encryption
    lifecycle: Lifecycle Rules
  }

  access: Access Control {
    style.fill: "#FFF8E1"
    style.stroke: "#FFA000"

    block: Public Access Block
    policy: Bucket Policy
    ownership: Object Ownership
  }
}

logging: Access Logs {
  shape: cylinder
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
}

kms: KMS Key {
  shape: hexagon
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
}

clients -> bucket: "HTTPS"
bucket -> logging: "logs"
bucket.features.encryption -> kms: "encrypts with"
bucket.storage.standard -> bucket.storage.ia: "90 days"
bucket.storage.ia -> bucket.storage.glacier: "180 days"
```

## Configuration Summary

| Setting                 | Value                                  |
| ----------------------- | -------------------------------------- |
| Bucket Name             | `${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}` |
| Region                  | `${{ values.aws_region }}`             |
| Environment             | `${{ values.environment }}`            |
| Versioning              | `${{ values.versioning }}`             |
| Encryption              | `${{ values.encryption }}`             |
| Lifecycle Rules         | `${{ values.lifecycleEnabled }}`       |
| Public Access Blocked   | `true`                                 |
| Object Ownership        | `BucketOwnerEnforced`                  |

## Lifecycle Policy Configuration

| Transition Stage            | Days | Storage Class      | Purpose                           |
| --------------------------- | ---- | ------------------ | --------------------------------- |
| Initial                     | 0    | STANDARD           | Frequently accessed data          |
| Infrequent Access           | 90   | STANDARD_IA        | Lower cost for less accessed data |
| Archive                     | 180  | GLACIER            | Long-term archival storage        |
| Non-current Version Archive | 30   | STANDARD_IA        | Version history cost optimization |
| Non-current Version Expiry  | 365  | (Deleted)          | Clean up old versions             |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, linting, Terraform validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations
- **Drift Detection**: Scheduled checks for configuration drift

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
  label: "Deploy\nS3 Bucket"
}

pr -> validate -> security -> plan -> review -> apply
```

---

## Prerequisites

### 1. AWS Account Setup

#### Create OIDC Identity Provider

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with AWS.

```bash
# Create the OIDC provider (one-time setup per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions

Create a role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions for S3

Attach a policy with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketManagement",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketEncryption",
        "s3:PutBucketEncryption",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:GetBucketLogging",
        "s3:PutBucketLogging",
        "s3:GetLifecycleConfiguration",
        "s3:PutLifecycleConfiguration",
        "s3:GetBucketCORS",
        "s3:PutBucketCORS",
        "s3:DeleteBucketCORS",
        "s3:GetBucketOwnershipControls",
        "s3:PutBucketOwnershipControls",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging"
      ],
      "Resource": [
        "arn:aws:s3:::${{ values.org_prefix }}-${{ values.name }}-*"
      ]
    },
    {
      "Sid": "S3ObjectManagement",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion"
      ],
      "Resource": [
        "arn:aws:s3:::${{ values.org_prefix }}-${{ values.name }}-*/*"
      ]
    },
    {
      "Sid": "KMSAccess",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.${{ values.aws_region }}.amazonaws.com"
        }
      }
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR_STATE_BUCKET",
        "arn:aws:s3:::YOUR_STATE_BUCKET/*"
      ]
    },
    {
      "Sid": "StateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

#### Create Terraform State Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region ${{ values.aws_region }}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking (optional but recommended)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                | Description                                 | Example                                              |
| --------------------- | ------------------------------------------- | ---------------------------------------------------- |
| `AWS_ROLE_ARN`        | IAM role ARN for OIDC authentication        | `arn:aws:iam::123456789012:role/github-actions-role` |
| `TF_STATE_BUCKET`     | S3 bucket name for Terraform state          | `my-terraform-state-bucket`                          |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking (optional) | `terraform-state-lock`                               |
| `INFRACOST_API_KEY`   | API key for cost estimation (optional)      | `ico-xxxxxxxx`                                       |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default                    |
| ------------ | ------------------ | -------------------------- |
| `AWS_REGION` | Default AWS region | `${{ values.aws_region }}` |

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

# Initialize Terraform
terraform init

# Format code (fix formatting issues)
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dev environment)
terraform plan -var-file="environments/dev.tfvars"

# Apply changes (requires appropriate AWS credentials)
terraform apply -var-file="environments/dev.tfvars"
```

### Accessing the Bucket

#### AWS CLI

```bash
# List objects
aws s3 ls s3://${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}/

# Upload a file
aws s3 cp myfile.txt s3://${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}/

# Download a file
aws s3 cp s3://${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}/myfile.txt ./

# Sync a directory
aws s3 sync ./local-dir s3://${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}/remote-dir/

# List object versions (if versioning is enabled)
aws s3api list-object-versions \
  --bucket ${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}

# Restore a previous version
aws s3api get-object \
  --bucket ${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }} \
  --key myfile.txt \
  --version-id <version-id> \
  restored-file.txt
```

#### Terraform Reference

To reference this bucket in other Terraform configurations:

```hcl
data "aws_s3_bucket" "this" {
  bucket = "${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}"
}

# Use the bucket ARN
resource "aws_iam_policy" "s3_access" {
  name = "s3-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${data.aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}
```

#### AWS SDK (Python/Boto3)

```python
import boto3

s3 = boto3.client('s3')
bucket_name = '${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}'

# Upload file
s3.upload_file('local-file.txt', bucket_name, 'remote-file.txt')

# Download file
s3.download_file(bucket_name, 'remote-file.txt', 'local-file.txt')

# List objects
response = s3.list_objects_v2(Bucket=bucket_name)
for obj in response.get('Contents', []):
    print(obj['Key'])
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                          |
| ------------ | ------------------------------------------------ |
| Pull Request | Validate, Security Scan, Plan, Cost Estimate     |
| Push to main | Validate, Security Scan, Plan (all environments) |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **AWS S3 Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## Security Features

### Encryption

This bucket uses server-side encryption to protect data at rest:

| Encryption Type | Description                           | Use Case                          |
| --------------- | ------------------------------------- | --------------------------------- |
| `AES256`        | AWS-managed keys (SSE-S3)             | General purpose, cost-effective   |
| `aws:kms`       | Customer-managed KMS keys (SSE-KMS)   | Compliance, audit requirements    |

```hcl
# Current configuration
encryption_type = "${{ values.encryption }}"
```

### Public Access Block

All public access is blocked by default:

| Setting                   | Value  | Description                              |
| ------------------------- | ------ | ---------------------------------------- |
| `block_public_acls`       | `true` | Blocks new public ACLs                   |
| `block_public_policy`     | `true` | Blocks new public bucket policies        |
| `ignore_public_acls`      | `true` | Ignores existing public ACLs             |
| `restrict_public_buckets` | `true` | Restricts access to bucket owner only    |

### Bucket Policy

Apply custom bucket policies for fine-grained access control:

```hcl
# Example: Restrict access to specific VPC endpoint
bucket_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid       = "VPCEndpointAccess"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        "arn:aws:s3:::${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}",
        "arn:aws:s3:::${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}/*"
      ]
      Condition = {
        StringNotEquals = {
          "aws:SourceVpce" = "vpce-1234567890abcdef0"
        }
      }
    }
  ]
})
```

### Object Ownership

Configured with `BucketOwnerEnforced` to:
- Disable ACLs on the bucket
- Ensure bucket owner automatically owns all objects
- Simplify access management with bucket policies only

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
| S3 bucket without versioning   | Enable versioning for data protection             |
| S3 bucket without logging      | Enable access logging for audit trails            |
| S3 bucket without encryption   | Already configured in this template               |
| Public access not blocked      | Already blocked by default in this template       |
| No lifecycle policy            | Enable lifecycle rules to manage storage costs    |

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource                | Monthly Cost (USD) | Notes                              |
| ----------------------- | ------------------ | ---------------------------------- |
| S3 Storage (STANDARD)   | $0.023/GB          | First 50 TB/month                  |
| S3 Storage (STANDARD_IA)| $0.0125/GB         | Lower cost, retrieval fees apply   |
| S3 Storage (GLACIER)    | $0.004/GB          | Archival, higher retrieval fees    |
| PUT/COPY/POST Requests  | $0.005/1000        | Write operations                   |
| GET/SELECT Requests     | $0.0004/1000       | Read operations                    |
| Data Transfer Out       | $0.09/GB           | First 10 TB/month                  |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                        | Description                              |
| ----------------------------- | ---------------------------------------- |
| `bucket_id`                   | The name of the bucket                   |
| `bucket_arn`                  | The ARN of the bucket                    |
| `bucket_domain_name`          | The bucket domain name                   |
| `bucket_regional_domain_name` | The bucket region-specific domain name   |
| `bucket_region`               | The AWS region this bucket resides in    |
| `bucket_hosted_zone_id`       | Route 53 Hosted Zone ID for this region  |
| `versioning_enabled`          | Whether versioning is enabled            |
| `encryption_type`             | The encryption type used                 |
| `lifecycle_enabled`           | Whether lifecycle rules are enabled      |
| `public_access_block`         | Public access block configuration        |
| `bucket_info`                 | Summary of bucket configuration          |

Access outputs via:

```bash
# Get specific output
terraform output bucket_id
terraform output bucket_arn

# Get all outputs as JSON
terraform output -json

# Get bucket info summary
terraform output -json bucket_info
```

---

## Troubleshooting

### Authentication Issues

**Error: No valid credential sources found**

```
Error: configuring Terraform AWS Provider: no valid credential sources for S3 Backend found.
```

**Resolution:**

1. Verify `AWS_ROLE_ARN` secret is configured correctly
2. Check OIDC provider is set up in AWS IAM
3. Ensure trust policy includes your repository: `repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*`
4. Verify the IAM role has the required S3 permissions

### State Backend Issues

**Error: Error acquiring the state lock**

```
Error: Error acquiring the state lock
```

**Resolution:**

1. Wait for any running pipelines to complete
2. If stuck, manually remove the lock from DynamoDB:
   ```bash
   aws dynamodb delete-item \
     --table-name terraform-state-lock \
     --key '{"LockID":{"S":"your-bucket/path/terraform.tfstate"}}'
   ```

### Bucket Creation Issues

**Error: BucketAlreadyExists**

```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Resolution:**

1. S3 bucket names are globally unique across all AWS accounts
2. Choose a different bucket name or organization prefix
3. Verify the bucket doesn't already exist: `aws s3 ls | grep ${{ values.name }}`

**Error: BucketAlreadyOwnedByYou**

```
Error: creating S3 Bucket: BucketAlreadyOwnedByYou
```

**Resolution:**

1. Import the existing bucket into Terraform state:
   ```bash
   terraform import module.s3.aws_s3_bucket.this ${{ values.org_prefix }}-${{ values.name }}-${{ values.environment }}
   ```

### Permission Issues

**Error: Access Denied**

```
Error: error creating S3 Bucket: AccessDenied
```

**Resolution:**

1. Review IAM role permissions
2. Ensure all required S3 policies are attached
3. Check for Service Control Policies (SCPs) that may restrict S3 actions
4. Verify KMS key permissions if using SSE-KMS encryption

### Lifecycle Configuration Issues

**Error: InvalidRequest - Lifecycle configuration not found**

```
Error: error reading S3 Lifecycle Configuration: InvalidRequest
```

**Resolution:**

1. This may occur when lifecycle is disabled after being enabled
2. Check that `lifecycle_enabled` variable matches intended state
3. Verify bucket versioning status if using non-current version rules

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

| Template                                              | Description                           |
| ----------------------------------------------------- | ------------------------------------- |
| [aws-vpc](/docs/default/template/aws-vpc)             | Amazon VPC network infrastructure     |
| [aws-cloudfront](/docs/default/template/aws-cloudfront) | CloudFront CDN for S3 static hosting |
| [aws-lambda](/docs/default/template/aws-lambda)       | AWS Lambda with S3 trigger            |
| [aws-rds](/docs/default/template/aws-rds)             | Amazon RDS with S3 backup integration |
| [aws-ecs](/docs/default/template/aws-ecs)             | Amazon ECS with S3 artifact storage   |

---

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/index.html)
- [S3 Bucket Naming Rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [S3 Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/lifecycle-transition-general-considerations.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [Terraform AWS S3 Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.

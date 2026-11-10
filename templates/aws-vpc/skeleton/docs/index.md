# ${{ values.name }}

AWS Virtual Private Cloud (VPC) infrastructure for the **${{ values.environment }}** environment in **${{ values.aws_region }}**.

## Overview

This VPC provides a production-ready network foundation with:

- Public and private subnets across multiple availability zones
- NAT Gateways for private subnet internet access
- VPC Flow Logs for network monitoring and security auditing
- Kubernetes-ready subnet tagging for EKS integration
- Internet Gateway for public internet access

```d2
direction: right

title: {
  label: AWS VPC Architecture
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

vpc: VPC (${{ values.vpc_cidr }}) {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  igw: Internet Gateway {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  public: Public Subnets {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    az1: AZ-1 Public
    az2: AZ-2 Public
  }

  nat: NAT Gateways {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    nat1: NAT-1
    nat2: NAT-2
  }

  private: Private Subnets {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    az1: AZ-1 Private
    az2: AZ-2 Private
  }

  logs: Flow Logs {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }

  igw -> public
  public -> nat
  nat -> private
  vpc -> logs: captures
}

internet -> vpc.igw
```

## Configuration Summary

| Setting            | Value                       |
| ------------------ | --------------------------- |
| VPC Name           | `${{ values.name }}-<environment>` |
| CIDR Block         | `${{ values.vpc_cidr }}`    |
| Region             | `${{ values.aws_region }}`  |
| Availability Zones | ${{ values.azs }}           |
| Environment        | `${{ values.environment }}` |

## Network Layout

| Subnet Type | CIDR Range                         | Purpose                                             |
| ----------- | ---------------------------------- | --------------------------------------------------- |
| Public      | First ${{ values.azs }} /20 blocks | Load balancers, bastion hosts, NAT Gateways         |
| Private     | Next ${{ values.azs }} /20 blocks  | Application workloads, databases, internal services |

---

## CI/CD Pipeline

The workflow in `.github/workflows/terraform.yaml` runs on every push and pull
request to `main`, once a week for drift detection, and on demand from the
Actions tab.

| Job           | Runs when                                   | What it does                                                         |
| ------------- | ------------------------------------------- | -------------------------------------------------------------------- |
| Settings      | Always                                      | Detects which secrets are configured and which environments to target |
| Validate      | Always                                      | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, TFLint |
| Test          | After Validate                              | `terraform test` against a mocked AWS provider                        |
| Security scan | After Validate                              | Trivy and Checkov; findings of medium severity or higher fail the job |
| Cost estimate | Pull requests, `INFRACOST_API_KEY` set      | Posts an Infracost estimate on the pull request                       |
| Plan          | `AWS_ROLE_ARN` and `TF_STATE_BUCKET` set    | Plans dev, staging and prod and stores each plan as an artifact       |
| Apply         | Manual run with action `apply`              | Applies the plan of the chosen environment                            |
| Destroy       | Manual run with action `destroy`            | Destroys the chosen environment after typing `DESTROY`                |
| Drift         | Weekly schedule, AWS secrets set            | Warns when the deployed resources differ from the configuration       |
| Summary       | Always                                      | Lists every job result and fails when a job failed                    |

A new repository has no secrets, so only the jobs that need no cloud account
run: Validate, Test and Security scan. Plan, Apply, Destroy and Drift start
working once the secrets described under [Prerequisites](#prerequisites) exist.

Apply and Destroy run in the GitHub environments `dev`, `staging` and `prod`.
Add required reviewers to an environment to make its deployments wait for
approval.

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions

Attach a policy with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateFlowLogs",
        "ec2:DeleteFlowLogs",
        "ec2:DescribeFlowLogs",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSecurityGroupRules",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:ModifySubnetAttribute"
      ],
      "Resource": "*"
    },
    {
      "Sid": "FlowLogsIAM",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "arn:aws:iam::*:role/*-flow-logs-role"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "logs:ListTagsLogGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSKeyManagement",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:ListAliases",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListResourceTags",
        "kms:EnableKeyRotation",
        "kms:PutKeyPolicy",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CreateGrant"
      ],
      "Resource": "*"
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
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"],
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

| Variable     | Description        | Default     |
| ------------ | ------------------ | ----------- |
| `AWS_REGION` | Default AWS region | `us-east-1` |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

### 3. Alternative: Azure or GCP

If deploying network infrastructure to other cloud providers, see:

- **Azure VNet**: Use the `azure-vnet` template
- **GCP VPC**: Use the `gcp-vpc` template

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
terraform plan -var="environment=dev"

# Apply changes (requires appropriate AWS credentials)
terraform apply -var="environment=dev"
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                          |
| ------------ | ------------------------------------------------ |
| Pull Request | Validate, Security Scan, Plan, Cost Estimate     |
| Push to main | Validate, Security Scan, Plan (all environments) |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **AWS VPC Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## Security Scanning

The pipeline runs two scanners on every push and pull request:

| Tool        | Purpose                                                   | Documentation                        |
| ----------- | --------------------------------------------------------- | ------------------------------------ |
| **Trivy**   | Misconfiguration scanner for infrastructure as code       | [trivy.dev](https://trivy.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance | [checkov.io](https://www.checkov.io) |

A finding fails the Security scan job. Fix the configuration, or, where the
finding is an accepted design choice, add an inline exception next to the
resource with the reason:

```hcl
resource "aws_s3_bucket" "example" {
  # checkov:skip=CKV_AWS_144: Replication is not required for this data
  # trivy:ignore:AVD-AWS-0089
}
```

### Common Security Findings

| Finding                      | Resolution                            |
| ---------------------------- | ------------------------------------- |
| VPC Flow Logs not enabled    | Already configured in this template   |
| Public subnet auto-assign IP | Required for NAT Gateway placement    |
| Missing encryption           | Add encryption for any data resources |

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides:

- Monthly cost breakdown on pull requests
- Cost comparison between current and proposed changes
- Resource-level cost analysis

**Estimated costs for this configuration:**

| Resource                         | Monthly Cost (USD)          |
| -------------------------------- | --------------------------- |
| NAT Gateway (${{ values.azs }}x) | ~$32 each                   |
| Elastic IPs (${{ values.azs }}x) | ~$3.60 each                 |
| VPC Flow Logs                    | Variable (based on traffic) |
| **Total Base Cost**              | ~$70-100/month              |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Outputs

After deployment, these outputs are available:

| Output                | Description                |
| --------------------- | -------------------------- |
| `vpc_id`              | VPC identifier             |
| `vpc_cidr`            | VPC CIDR block             |
| `public_subnet_ids`   | List of public subnet IDs  |
| `private_subnet_ids`  | List of private subnet IDs |
| `nat_gateway_ids`     | List of NAT Gateway IDs    |
| `internet_gateway_id` | Internet Gateway ID        |
| `flow_log_id`         | VPC Flow Log ID            |

Access outputs via:

```bash
terraform output vpc_id
terraform output -json public_subnet_ids
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
3. Ensure trust policy includes your repository: `repo:YOUR_ORG/YOUR_REPO:*`
4. Verify the IAM role has the required permissions

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

### Permission Issues

**Error: Access Denied**

```
Error: error creating VPC: UnauthorizedOperation: You are not authorized to perform this operation.
```

**Resolution:**

1. Review IAM role permissions
2. Ensure all required policies are attached
3. Check for Service Control Policies (SCPs) that may restrict actions

### Pipeline Failures

**Security scan failing**

Read the finding in the job log; it names the check and the resource. Fix the
resource, or add an inline `checkov:skip` or `trivy:ignore` comment with the
reason as described under [Security Scanning](#security-scanning).

---

## Related Templates

| Template                                        | Description                        |
| ----------------------------------------------- | ---------------------------------- |
| [aws-eks](/docs/default/template/aws-eks)       | Amazon EKS Kubernetes cluster      |
| [aws-rds](/docs/default/template/aws-rds)       | Amazon RDS database                |
| [aws-lambda](/docs/default/template/aws-lambda) | AWS Lambda serverless function     |
| [azure-vnet](/docs/default/template/azure-vnet) | Azure Virtual Network (equivalent) |
| [gcp-vpc](/docs/default/template/gcp-vpc)       | Google Cloud VPC (equivalent)      |

---

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

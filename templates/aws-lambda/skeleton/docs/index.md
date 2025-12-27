# ${{ values.name }}

AWS Lambda serverless function for the **${{ values.environment }}** environment in **${{ values.aws_region }}**.

## Overview

This Lambda function provides a production-ready serverless compute solution with:

- Automated packaging and deployment via Terraform
- Function versioning with alias-based traffic routing
- CloudWatch logging with configurable retention
- X-Ray tracing for distributed debugging
- CloudWatch alarms for errors, duration, and throttling
- Optional VPC integration for private resource access
- Dead letter queue support for failed invocations
- Function URL for HTTP(S) access (optional)

```d2
direction: right

title: {
  label: AWS Lambda Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

triggers: Event Sources {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  api: API Gateway {
    shape: hexagon
  }
  s3: S3 Events {
    shape: cylinder
  }
  sqs: SQS Queue {
    shape: queue
  }
  schedule: EventBridge {
    shape: oval
  }
  url: Function URL {
    shape: hexagon
  }
}

lambda: Lambda Function {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  function: ${{ values.name }} {
    style.fill: "#BBDEFB"
    style.stroke: "#1976D2"
    label: "${{ values.runtime }}\n${{ values.memory_size }}MB\n${{ values.timeout }}s timeout"
  }

  alias: live Alias {
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"
  }

  versions: Versions {
    style.fill: "#E0E0E0"
    style.stroke: "#616161"
    v1: v1
    v2: v2
    vN: vN...
  }

  function -> alias
  alias -> versions
}

monitoring: Monitoring {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  logs: CloudWatch Logs {
    shape: cylinder
  }
  xray: X-Ray Traces {
    shape: page
  }
  alarms: CloudWatch Alarms {
    shape: diamond
  }
}

dlq: Dead Letter Queue {
  shape: queue
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
}

vpc: VPC (Optional) {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  style.stroke-dash: 3

  rds: RDS Database {
    shape: cylinder
  }
  elasticache: ElastiCache {
    shape: cylinder
  }
}

triggers -> lambda.function
lambda.function -> monitoring.logs: logs
lambda.function -> monitoring.xray: traces
lambda.function -> dlq: on failure
lambda.function -> vpc: private access
monitoring.alarms -> lambda.function: monitors
```

## Configuration Summary

| Setting                | Value                                   |
| ---------------------- | --------------------------------------- |
| Function Name          | `${{ values.name }}`                    |
| Runtime                | `${{ values.runtime }}`                 |
| Handler                | `${{ values.handler }}`                 |
| Memory Size            | `${{ values.memory_size }}` MB          |
| Timeout                | `${{ values.timeout }}` seconds         |
| Region                 | `${{ values.aws_region }}`              |
| Environment            | `${{ values.environment }}`             |
| Architecture           | `x86_64`                                |
| Log Retention          | 14 days                                 |

## Function Features

| Feature                | Status    | Description                                      |
| ---------------------- | --------- | ------------------------------------------------ |
| Version Publishing     | Enabled   | New version created on each deployment           |
| Live Alias             | Enabled   | `live` alias for stable endpoint                 |
| Function URL           | Optional  | HTTP(S) endpoint for direct invocation           |
| VPC Integration        | Optional  | Access private resources (RDS, ElastiCache)      |
| X-Ray Tracing          | Optional  | Distributed tracing for debugging                |
| Dead Letter Queue      | Optional  | Capture failed async invocations                 |
| CloudWatch Alarms      | Optional  | Alerts for errors, duration, throttling          |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Runtime Detection**: Automatic Python/Node.js detection for appropriate tooling
- **Code Quality**: Linting with Ruff/Black (Python) or Biome (Node.js)
- **Unit Testing**: pytest (Python) or Jest (Node.js) with coverage reporting
- **Terraform Testing**: Native `terraform test` validation
- **Security Scanning**: Trivy, tfsec, Checkov, Bandit for vulnerability detection
- **Multi-Environment**: Progressive deployments through dev, staging, production
- **Traffic Shifting**: Gradual rollout in production (10% -> 50% -> 100%)
- **Rollback Support**: One-click rollback to any previous version

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

lint: Lint & Test {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Ruff/Biome\npytest/Jest\nTerraform Test"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Trivy\ntfsec\nCheckov\nBandit"
}

build: Build {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Package\nDependencies\nCreate ZIP"
}

dev: Dev Deploy {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
  label: "Deploy\nSmoke Test"
}

staging: Staging {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Deploy\nSmoke Test"
}

approval: Approval {
  shape: diamond
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Manual\nReview"
}

prod: Production {
  style.fill: "#C8E6C9"
  style.stroke: "#388E3C"
  label: "Traffic Shift\n10%->50%->100%"
}

pr -> lint -> security -> build -> dev -> staging -> approval -> prod
```

### Deployment Stages

| Stage      | Trigger                  | Approval Required | Traffic Strategy     |
| ---------- | ------------------------ | ----------------- | -------------------- |
| Dev        | Push to `develop`        | No                | Immediate 100%       |
| Staging    | Push to `main`           | Optional          | Immediate 100%       |
| Production | After staging success    | Yes               | Gradual (10/50/100%) |

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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/${{ values.name }}:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions

Attach a policy with these permissions for Lambda management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:GetFunctionConfiguration",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:ListVersionsByFunction",
        "lambda:PublishVersion",
        "lambda:CreateAlias",
        "lambda:DeleteAlias",
        "lambda:GetAlias",
        "lambda:UpdateAlias",
        "lambda:ListAliases",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:GetPolicy",
        "lambda:InvokeFunction",
        "lambda:CreateFunctionUrlConfig",
        "lambda:DeleteFunctionUrlConfig",
        "lambda:GetFunctionUrlConfig",
        "lambda:UpdateFunctionUrlConfig",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:ListTags",
        "lambda:PutFunctionConcurrency",
        "lambda:DeleteFunctionConcurrency"
      ],
      "Resource": [
        "arn:aws:lambda:${{ values.aws_region }}:*:function:${{ values.name }}-*"
      ]
    },
    {
      "Sid": "LambdaLayers",
      "Effect": "Allow",
      "Action": [
        "lambda:GetLayerVersion",
        "lambda:ListLayerVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleManagement",
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
        "iam:ListAttachedRolePolicies",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "arn:aws:iam::*:role/${{ values.name }}-*"
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
        "logs:UntagLogGroup",
        "logs:ListTagsLogGroup",
        "logs:TagResource",
        "logs:UntagResource"
      ],
      "Resource": [
        "arn:aws:logs:${{ values.aws_region }}:*:log-group:/aws/lambda/${{ values.name }}-*"
      ]
    },
    {
      "Sid": "CloudWatchAlarms",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:TagResource",
        "cloudwatch:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "XRayTracing",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "VPCAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses"
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

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret              | Description                                 | Example                                              |
| ------------------- | ------------------------------------------- | ---------------------------------------------------- |
| `AWS_ROLE_ARN`      | IAM role ARN for OIDC authentication        | `arn:aws:iam::123456789012:role/github-actions-role` |
| `TF_STATE_BUCKET`   | S3 bucket name for Terraform state          | `my-terraform-state-bucket`                          |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking (optional) | `terraform-state-lock`                             |
| `SNYK_TOKEN`        | Snyk API token for security scanning (optional) | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`           |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default                  |
| ------------ | ------------------ | ------------------------ |
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

# Install development dependencies (Python)
pip install -r requirements-dev.txt

# Install development dependencies (Node.js)
npm install

# Run tests locally
pytest tests/ -v                    # Python
npm test                            # Node.js

# Run linting
ruff check src/ && black --check src/   # Python
npx @biomejs/biome check src/           # Node.js

# Initialize Terraform
terraform init

# Format Terraform code
terraform fmt -recursive

# Validate configuration
terraform validate

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate AWS credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Running the Pipeline

#### Automatic Triggers

| Trigger            | Actions                                      |
| ------------------ | -------------------------------------------- |
| Push to `develop`  | Full pipeline, deploy to dev                 |
| Push to `main`     | Full pipeline, deploy to staging and prod    |
| Pull Request       | Validate, Security Scan, Plan                |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **AWS Lambda CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `deploy`, or `rollback`
   - **environment**: `dev`, `staging`, or `prod`
   - **version**: Version number (for rollback only)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

### Invoking the Function

```bash
# Invoke via AWS CLI
aws lambda invoke \
  --function-name ${{ values.name }}-${{ values.environment }} \
  --payload '{"key": "value"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Invoke via alias (recommended for production)
aws lambda invoke \
  --function-name ${{ values.name }}-${{ values.environment }}:live \
  --payload '{"key": "value"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# View response
cat response.json
```

### Function URL Access

If function URL is enabled:

```bash
# Get the function URL
terraform output function_url

# Invoke via HTTP
curl -X POST https://xxxxxxxxxx.lambda-url.${{ values.aws_region }}.on.aws/ \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## Security Scanning

The pipeline includes comprehensive security scanning:

| Tool        | Purpose                                                     | Documentation                        |
| ----------- | ----------------------------------------------------------- | ------------------------------------ |
| **Trivy**   | Filesystem and IaC vulnerability scanning                   | [trivy.dev](https://trivy.dev)       |
| **tfsec**   | Static analysis for Terraform security misconfigurations    | [tfsec.dev](https://tfsec.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance   | [checkov.io](https://www.checkov.io) |
| **Bandit**  | Python-specific security linting                            | [bandit.readthedocs.io](https://bandit.readthedocs.io) |
| **Snyk**    | Dependency vulnerability scanning (optional)                | [snyk.io](https://snyk.io)           |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

### Common Security Findings

| Finding                           | Resolution                                           |
| --------------------------------- | ---------------------------------------------------- |
| Lambda not in VPC                 | Add VPC configuration if accessing private resources |
| Function URL without IAM auth     | Set `function_url_auth_type = "AWS_IAM"`             |
| Missing dead letter queue         | Configure `dead_letter_target_arn`                   |
| Log group not encrypted           | Set `log_kms_key_id` for encryption                  |
| Overly permissive IAM policy      | Use least-privilege `custom_iam_policy`              |
| Reserved concurrency not set      | Configure `reserved_concurrent_executions`           |

---

## Outputs

After deployment, these outputs are available:

| Output                   | Description                                |
| ------------------------ | ------------------------------------------ |
| `function_name`          | Name of the Lambda function                |
| `function_arn`           | ARN of the Lambda function                 |
| `function_qualified_arn` | Qualified ARN (includes version)           |
| `invoke_arn`             | ARN for API Gateway integration            |
| `function_version`       | Latest published version number            |
| `role_name`              | Name of the Lambda execution role          |
| `role_arn`               | ARN of the Lambda execution role           |
| `log_group_name`         | CloudWatch log group name                  |
| `log_group_arn`          | CloudWatch log group ARN                   |
| `alias_name`             | Name of the live alias                     |
| `alias_arn`              | ARN of the live alias                      |
| `alias_invoke_arn`       | Invoke ARN for the alias                   |
| `function_url`           | Function URL (if enabled)                  |
| `runtime`                | Lambda runtime                             |
| `handler`                | Lambda handler                             |
| `memory_size`            | Configured memory size                     |
| `timeout`                | Configured timeout                         |
| `environment`            | Environment name                           |
| `function_info`          | Summary object with all configuration      |

Access outputs via:

```bash
# Single output
terraform output function_name
terraform output function_arn

# JSON format for programmatic access
terraform output -json function_info

# All outputs
terraform output
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
3. Ensure trust policy includes your repository: `repo:YOUR_ORG/${{ values.name }}:*`
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

### Lambda Deployment Issues

**Error: Function code package exceeds maximum size**

```
InvalidParameterValueException: Unzipped size must be smaller than 262144000 bytes
```

**Resolution:**

1. Review dependencies and remove unused packages
2. Use Lambda Layers for large dependencies
3. Consider using container images instead of ZIP deployments

**Error: Lambda function timeout**

```
Task timed out after X seconds
```

**Resolution:**

1. Increase `timeout` value (max 900 seconds)
2. Optimize function code for performance
3. Consider breaking into smaller functions

### VPC Configuration Issues

**Error: Lambda unable to access internet**

```
Connection timeout when accessing external resources
```

**Resolution:**

1. Ensure Lambda is in private subnets with NAT Gateway access
2. Verify security group allows outbound traffic
3. Check route table configuration for NAT Gateway

### Permission Issues

**Error: Access Denied**

```
Error: error creating Lambda Function: AccessDeniedException: User is not authorized
```

**Resolution:**

1. Review IAM role permissions
2. Ensure all required Lambda and IAM policies are attached
3. Check for Service Control Policies (SCPs) that may restrict actions
4. Verify `iam:PassRole` permission for the execution role

### Rollback Procedure

To rollback to a previous version:

1. **Via GitHub Actions:**
   - Go to Actions > AWS Lambda CI/CD > Run workflow
   - Select `rollback` action
   - Enter target environment and version number

2. **Via AWS CLI:**
   ```bash
   # List available versions
   aws lambda list-versions-by-function \
     --function-name ${{ values.name }}-${{ values.environment }}

   # Update alias to previous version
   aws lambda update-alias \
     --function-name ${{ values.name }}-${{ values.environment }} \
     --name live \
     --function-version <VERSION_NUMBER>
   ```

---

## Related Templates

| Template                                        | Description                         |
| ----------------------------------------------- | ----------------------------------- |
| [aws-api-gateway](/docs/default/template/aws-api-gateway) | API Gateway for Lambda integration |
| [aws-sqs](/docs/default/template/aws-sqs)       | SQS queue for async invocation      |
| [aws-eventbridge](/docs/default/template/aws-eventbridge) | EventBridge for scheduled events  |
| [aws-dynamodb](/docs/default/template/aws-dynamodb) | DynamoDB table for data storage   |
| [aws-s3](/docs/default/template/aws-s3)         | S3 bucket for file storage          |
| [aws-vpc](/docs/default/template/aws-vpc)       | VPC for private Lambda deployment   |
| [aws-rds](/docs/default/template/aws-rds)       | RDS database for Lambda access      |

---

## References

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/latest/dg/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Terraform AWS Provider - Lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Lambda Power Tuning](https://github.com/alexcasalboni/aws-lambda-power-tuning)
- [Serverless Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/welcome.html)
- [Lambda Operator Guide](https://docs.aws.amazon.com/lambda/latest/operatorguide/)

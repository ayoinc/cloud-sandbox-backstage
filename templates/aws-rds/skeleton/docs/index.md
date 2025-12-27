# ${{ values.name }}

${{ values.description }}

## Overview

This RDS instance provides a fully managed **${{ values.engine }}** database for the **${{ values.environment }}** environment in **${{ values.region }}**. The infrastructure is deployed and managed via Terraform with a comprehensive CI/CD pipeline.

Key features include:

- Production-ready ${{ values.engine }} database with configurable engine version
- Automated credential management via AWS Secrets Manager
- Multi-AZ deployment support for high availability
- Automated backups with configurable retention
- Performance Insights and Enhanced Monitoring
- Storage autoscaling with configurable limits
- Private subnet deployment with VPC security groups

```d2
direction: right

title: {
  label: AWS RDS Architecture
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

vpc: VPC {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  public: Public Subnets {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"

    bastion: Bastion Host {
      shape: rectangle
      style.fill: "#C8E6C9"
    }

    app: Application Servers {
      shape: rectangle
      style.fill: "#C8E6C9"
    }
  }

  private: Private Subnets {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    sg: Security Group {
      style.fill: "#FFCDD2"
      style.stroke: "#D32F2F"

      primary: RDS Primary {
        shape: cylinder
        style.fill: "#BBDEFB"
        style.stroke: "#1976D2"
        label: "${{ values.engine }}\n${{ values.instanceClass }}"
      }

      standby: RDS Standby (Multi-AZ) {
        shape: cylinder
        style.fill: "#E1BEE7"
        style.stroke: "#7B1FA2"
        label: "Synchronous\nReplication"
      }
    }

    subnet-group: DB Subnet Group {
      style.fill: "#F3E5F5"
      style.stroke: "#7B1FA2"

      az1: AZ-1 Subnet
      az2: AZ-2 Subnet
    }
  }

  secrets: Secrets Manager {
    shape: hexagon
    style.fill: "#FFF9C4"
    style.stroke: "#FBC02D"
    label: "DB Credentials"
  }

  cloudwatch: CloudWatch {
    shape: hexagon
    style.fill: "#B2EBF2"
    style.stroke: "#0097A7"
    label: "Logs & Metrics"
  }

  primary -> standby: sync {
    style.stroke-dash: 3
  }
  public.app -> sg.primary: port ${{ values.port || "5432/3306" }}
  public.bastion -> sg.primary: admin access
  sg -> secrets: credentials
  sg -> cloudwatch: monitoring
}

internet -> vpc.public.app: HTTPS
```

---

## Configuration Summary

| Setting                | Value                                                            |
| ---------------------- | ---------------------------------------------------------------- |
| Instance Name          | `${{ values.name }}`                                             |
| Engine                 | `${{ values.engine }}` version `${{ values.engineVersion }}`     |
| Instance Class         | `${{ values.instanceClass }}`                                    |
| Allocated Storage      | `${{ values.allocatedStorage }}` GB (autoscaling to `${{ values.maxAllocatedStorage || 100 }}` GB) |
| Storage Type           | `${{ values.storageType || "gp3" }}`                             |
| Multi-AZ               | `${{ values.multiAz }}`                                          |
| Region                 | `${{ values.region }}`                                           |
| Environment            | `${{ values.environment }}`                                      |
| Backup Retention       | `${{ values.backupRetentionPeriod || 7 }}` days                  |
| Performance Insights   | `${{ values.performanceInsightsEnabled || true }}`               |
| Encryption             | Enabled (at rest)                                                |

### Database Settings

| Setting         | Value                                          |
| --------------- | ---------------------------------------------- |
| Database Name   | `${{ values.databaseName || "app" }}`          |
| Master Username | `${{ values.masterUsername || "dbadmin" }}`    |
| Port            | `${{ values.port || (values.engine == "mysql" ? "3306" : "5432") }}` |
| Parameter Group | `${{ values.engineFamily || "postgres16" }}`   |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Preflight Checks**: AWS connectivity and IAM permission verification
- **Validation**: Format checking, TFLint, Terraform validation
- **Terraform Tests**: Automated testing with `terraform test`
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

preflight: Preflight {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "AWS Auth\nPermissions\nState Backend"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate"
}

test: Test {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Terraform Test\nUnit Tests"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

cost: Cost {
  style.fill: "#FFF9C4"
  style.stroke: "#FBC02D"
  label: "Infracost\nEstimate"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nDev/Staging/Prod"
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
  label: "Deploy\nRDS Instance"
}

pr -> preflight -> validate -> test -> security
security -> cost
security -> plan
cost -> plan
plan -> review -> apply
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/${{ values.name }}:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions

Attach a policy with these permissions for RDS management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RDSManagement",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:RebootDBInstance",
        "rds:StartDBInstance",
        "rds:StopDBInstance",
        "rds:CreateDBSnapshot",
        "rds:DeleteDBSnapshot",
        "rds:DescribeDBSnapshots",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:DescribeDBSubnetGroups",
        "rds:ModifyDBSubnetGroup",
        "rds:CreateDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:ModifyDBParameterGroup",
        "rds:DescribeDBParameters",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "rds:ListTagsForResource",
        "rds:DescribeDBEngineVersions",
        "rds:DescribeOrderableDBInstanceOptions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerAccess",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:PutResourcePolicy",
        "secretsmanager:DeleteResourcePolicy"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:${{ values.name }}-*"
    },
    {
      "Sid": "VPCAndSecurityGroups",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogsAndMonitoring",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "cloudwatch:GetMetricData",
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EnhancedMonitoringIAM",
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
        "iam:DetachRolePolicy"
      ],
      "Resource": "arn:aws:iam::*:role/*-rds-monitoring-role"
    },
    {
      "Sid": "KMSForEncryption",
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "rds.${{ values.region }}.amazonaws.com"
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
aws s3 mb s3://your-terraform-state-bucket --region ${{ values.region }}

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

### 2. VPC Requirements

This RDS instance requires an existing VPC with:

- **VPC ID**: The VPC where RDS will be deployed
- **Private Subnets**: At least 2 subnets in different AZs for the DB subnet group
- **VPC CIDR**: Used to configure security group ingress rules

You can use the [aws-vpc](/docs/default/template/aws-vpc) template to create a compatible VPC.

### 3. GitHub Repository Setup

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

| Variable     | Description        | Default              |
| ------------ | ------------------ | -------------------- |
| `AWS_REGION` | Default AWS region | `${{ values.region }}` |

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

# Run Terraform tests
terraform test

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate AWS credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Connecting to the Database

#### Retrieve Credentials from Secrets Manager

```bash
# Get database credentials
aws secretsmanager get-secret-value \
  --secret-id ${{ values.name }}-${{ values.environment }}-db-credentials \
  --region ${{ values.region }} \
  --query SecretString --output text | jq .

# Example output:
# {
#   "username": "dbadmin",
#   "password": "generated-password",
#   "host": "mydb.xxxxx.us-east-1.rds.amazonaws.com",
#   "port": 5432,
#   "dbname": "app"
# }
```

#### Connection Strings

**PostgreSQL:**

```bash
# Using psql
psql "postgresql://dbadmin:<password>@<endpoint>:5432/app?sslmode=require"

# Using environment variables
export PGHOST=<endpoint>
export PGPORT=5432
export PGDATABASE=app
export PGUSER=dbadmin
export PGPASSWORD=<password>
psql
```

**MySQL:**

```bash
# Using mysql client
mysql -h <endpoint> -P 3306 -u dbadmin -p app

# Connection string
mysql://dbadmin:<password>@<endpoint>:3306/app?ssl=true
```

#### Application Configuration

For application integration, retrieve credentials dynamically:

```python
# Python example using boto3
import boto3
import json

def get_db_credentials(secret_name, region):
    client = boto3.client('secretsmanager', region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

creds = get_db_credentials(
    '${{ values.name }}-${{ values.environment }}-db-credentials',
    '${{ values.region }}'
)
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                          |
| ------------ | ------------------------------------------------ |
| Pull Request | Validate, Test, Security Scan, Plan, Cost Estimate |
| Push to main | Validate, Test, Security Scan, Plan (all environments) |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **AWS RDS Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy action)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

---

## Security Scanning

The pipeline includes three security scanning tools:

| Tool        | Purpose                                                   | Documentation                        |
| ----------- | --------------------------------------------------------- | ------------------------------------ |
| **tfsec**   | Static analysis for Terraform security misconfigurations  | [tfsec.dev](https://tfsec.dev)       |
| **Checkov** | Policy-as-code for infrastructure security and compliance | [checkov.io](https://www.checkov.io) |
| **Trivy**   | Comprehensive vulnerability scanner for IaC               | [trivy.dev](https://trivy.dev)       |

Results are uploaded to the GitHub **Security** tab as SARIF reports.

### RDS-Specific Security Checks

| Check                           | Status      | Description                                  |
| ------------------------------- | ----------- | -------------------------------------------- |
| Storage Encryption              | Enabled     | Data encrypted at rest using KMS             |
| In-Transit Encryption           | Enforced    | SSL/TLS required for connections             |
| Public Accessibility            | Disabled    | Instance not accessible from public internet |
| Secrets Manager Integration     | Enabled     | Credentials stored securely                  |
| Security Group Restrictions     | VPC-only    | Access limited to VPC CIDR                   |
| Deletion Protection             | Configurable| Prevents accidental deletion                 |

### Skipped Checks

The following checks are skipped by default (configurable in workflow):

| Check ID      | Reason                                         |
| ------------- | ---------------------------------------------- |
| `CKV_TF_1`    | Module source versioning (internal modules)    |
| `CKV_AWS_161` | IAM authentication (using Secrets Manager)     |
| `CKV_AWS_226` | Performance Insights (configurable per env)    |

---

## Backup and Recovery

### Automated Backups

| Setting            | Dev            | Staging        | Production     |
| ------------------ | -------------- | -------------- | -------------- |
| Retention Period   | 7 days         | 14 days        | 30 days        |
| Backup Window      | 03:00-04:00 UTC| 03:00-04:00 UTC| 03:00-04:00 UTC|
| Maintenance Window | Mon 04:00-05:00| Mon 04:00-05:00| Sun 04:00-05:00|

### Manual Snapshots

```bash
# Create a manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier ${{ values.name }}-${{ values.environment }} \
  --db-snapshot-identifier ${{ values.name }}-manual-$(date +%Y%m%d-%H%M%S) \
  --region ${{ values.region }}

# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier ${{ values.name }}-${{ values.environment }} \
  --region ${{ values.region }} \
  --query 'DBSnapshots[].{ID:DBSnapshotIdentifier,Status:Status,Created:SnapshotCreateTime}'
```

### Point-in-Time Recovery

RDS supports point-in-time recovery within the backup retention period:

```bash
# Restore to a specific point in time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ${{ values.name }}-${{ values.environment }} \
  --target-db-instance-identifier ${{ values.name }}-restored \
  --restore-time "2024-01-15T10:30:00Z" \
  --region ${{ values.region }}
```

### Disaster Recovery

For Multi-AZ deployments (`${{ values.multiAz }}`):

- **Automatic Failover**: RDS automatically fails over to standby in another AZ
- **Failover Time**: Typically 60-120 seconds
- **No Data Loss**: Synchronous replication ensures zero data loss

For cross-region disaster recovery, consider:

1. **Read Replicas**: Create cross-region read replicas for DR
2. **Snapshot Copy**: Automate cross-region snapshot copies
3. **Aurora Global Database**: For Aurora, use Global Database for <1s RPO

---

## Outputs

After deployment, these outputs are available:

| Output                | Description                                         |
| --------------------- | --------------------------------------------------- |
| `instance_id`         | RDS instance ID                                     |
| `instance_arn`        | ARN of the RDS instance                             |
| `instance_identifier` | RDS instance identifier                             |
| `endpoint`            | Connection endpoint (address:port)                  |
| `address`             | Hostname of the RDS instance                        |
| `port`                | Database port                                       |
| `database_name`       | Name of the default database                        |
| `secret_arn`          | ARN of the Secrets Manager secret                   |
| `secret_name`         | Name of the Secrets Manager secret                  |
| `security_group_id`   | ID of the RDS security group                        |
| `db_subnet_group_name`| Name of the DB subnet group                         |
| `parameter_group_name`| Name of the DB parameter group                      |
| `engine`              | Database engine type                                |
| `engine_version`      | Database engine version                             |
| `instance_class`      | RDS instance class                                  |
| `multi_az`            | Whether Multi-AZ is enabled                         |
| `availability_zone`   | Primary availability zone                           |
| `connection_info`     | Object with all connection details                  |

Access outputs via:

```bash
# Get specific output
terraform output endpoint
terraform output -json connection_info

# Get all outputs
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
4. Verify the IAM role has the required RDS permissions

### Connection Issues

**Error: Connection timed out**

```
psql: error: connection to server at "mydb.xxx.rds.amazonaws.com" (10.0.1.50), port 5432 failed: Connection timed out
```

**Resolution:**

1. Verify you're connecting from within the VPC or via VPN/bastion
2. Check security group allows inbound traffic from your source
3. Ensure the RDS instance is in the `available` state
4. Verify network ACLs allow the database port

**Error: SSL connection required**

```
FATAL: no pg_hba.conf entry for host "x.x.x.x", user "dbadmin", database "app", SSL off
```

**Resolution:**

```bash
# PostgreSQL - Add sslmode parameter
psql "postgresql://dbadmin:password@endpoint:5432/app?sslmode=require"

# MySQL - Add SSL parameter
mysql -h endpoint -u dbadmin -p --ssl-mode=REQUIRED
```

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
     --key '{"LockID":{"S":"your-bucket/${{ values.name }}/terraform.tfstate"}}'
   ```

### RDS-Specific Issues

**Error: DBSubnetGroupDoesNotCoverEnoughAZs**

```
Error: DBSubnetGroupDoesNotCoverEnoughAZs: DB Subnet Group doesn't meet availability zone coverage requirement.
```

**Resolution:**

Ensure your VPC has at least 2 private subnets in different availability zones.

**Error: InvalidParameterCombination - Multi-AZ**

```
Error: InvalidParameterCombination: Multi-AZ is not supported for db.t2.micro DB instances.
```

**Resolution:**

Use a larger instance class (db.t3.medium or higher) for Multi-AZ deployments.

### Pipeline Failures

**Security scan failing**

Set `soft_fail: true` in the workflow to allow warnings without blocking:

```yaml
- uses: aquasecurity/tfsec-action@v1.0.3
  with:
    soft_fail: true
```

---

## Cost Estimation

When `INFRACOST_API_KEY` is configured, the pipeline provides cost estimates.

**Estimated monthly costs for this configuration:**

| Resource                              | Monthly Cost (USD)                    |
| ------------------------------------- | ------------------------------------- |
| RDS Instance (${{ values.instanceClass }}) | Varies by instance class          |
| Multi-AZ (if enabled)                 | ~2x compute cost                      |
| Storage (${{ values.allocatedStorage }} GB ${{ values.storageType || "gp3" }}) | ~$0.08-0.10/GB |
| Backup Storage                        | Free up to DB size, then $0.095/GB    |
| Secrets Manager                       | ~$0.40/secret/month                   |
| Enhanced Monitoring                   | CloudWatch Logs pricing               |

**Example pricing (us-east-1):**

| Instance Class  | Single-AZ/month | Multi-AZ/month |
| --------------- | --------------- | -------------- |
| db.t3.micro     | ~$12            | ~$24           |
| db.t3.medium    | ~$48            | ~$96           |
| db.r6g.large    | ~$140           | ~$280          |
| db.r6g.xlarge   | ~$280           | ~$560          |

Get a free API key at [infracost.io](https://www.infracost.io/).

---

## Related Templates

| Template                                        | Description                            |
| ----------------------------------------------- | -------------------------------------- |
| [aws-vpc](/docs/default/template/aws-vpc)       | Amazon VPC (required for RDS)          |
| [aws-eks](/docs/default/template/aws-eks)       | Amazon EKS Kubernetes cluster          |
| [aws-lambda](/docs/default/template/aws-lambda) | AWS Lambda serverless function         |
| [aws-elasticache](/docs/default/template/aws-elasticache) | Amazon ElastiCache (Redis/Memcached) |
| [aws-aurora](/docs/default/template/aws-aurora) | Amazon Aurora (MySQL/PostgreSQL compatible) |

---

## References

- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/latest/UserGuide/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Terraform AWS RDS Module](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/)
- [RDS Pricing](https://aws.amazon.com/rds/pricing/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## Owner

This resource is owned by **${{ values.owner }}**.

# ${{ values.componentName }}

${{ values.description or ('AWS infrastructure stack of ' + values.projectName) }}

Terraform configuration of the **${{ values.environment }}** environment of
**${{ values.projectName }}** in **${{ values.region }}**.

## Layout

| File | Contents |
| ---- | -------- |
| `terraform.auto.tfvars.json` | The settings chosen when the repository was created |
| `variables.tf`, `locals.tf`, `outputs.tf` | Inputs, naming and outputs |
| `kms.tf` | Encryption key shared by the stack |
| `networking.tf` | VPC, subnets, gateways, route tables, flow logs |
| `compute.tf` | EC2 Auto Scaling group |
| `containers.tf` | EKS cluster, node group, ECR repository |
| `storage.tf` | S3 bucket, EFS file system |
| `database.tf` | RDS for PostgreSQL, DynamoDB, ElastiCache |
| `security.tf` | GuardDuty, IAM Access Analyzer, EBS encryption by default |
| `monitoring.tf` | Alarm topic, log group, alarms, dashboard |
| `analytics.tf` | Kinesis data stream, Glue catalog database |
| `integration.tf` | SQS, SNS, EventBridge |
| `ai_ml.tf` | SageMaker execution role and model registry |
| `tests/` | Terraform tests that run against mocked providers |

Each category is created only when its `enable_*` variable is `true`.

## Pipeline

`.github/workflows/terraform.yaml` validates, lints, tests and scans every push.
Plan, apply, destroy and drift detection start once the `AWS_ROLE_ARN` and
`TF_STATE_BUCKET` secrets exist. See [docs/index.md](docs/index.md).

## Owner

${{ values.owner }}

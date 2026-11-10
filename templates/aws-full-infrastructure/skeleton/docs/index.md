# ${{ values.componentName }}

${{ values.description or ('AWS infrastructure stack of ' + values.projectName) }}

One Terraform configuration for the **${{ values.environment }}** environment of
**${{ values.projectName }}** in **${{ values.region }}**. Every resource is named
`${{ values.projectName }}-${{ values.environment }}` or starts with that prefix.

## Resource categories

Each category is switched on or off with one variable in
`terraform.auto.tfvars.json`. The values below are the ones chosen when this
repository was created.

| Category    | Variable             | Status | Resources | File |
| ----------- | -------------------- | ------ | --------- | ---- |
| Networking  | `enable_networking`  | {% if values.enable_networking %}Enabled{% else %}Disabled{% endif %} | VPC, subnets, internet and NAT gateway, route tables, flow logs, optional VPN and transit gateway | `networking.tf` |
| Compute     | `enable_compute`     | {% if values.enable_compute %}Enabled{% else %}Disabled{% endif %} | Launch template and Auto Scaling group managed through Systems Manager | `compute.tf` |
| Containers  | `enable_containers`  | {% if values.enable_containers %}Enabled{% else %}Disabled{% endif %} | EKS cluster, managed node group, OIDC provider, ECR repository | `containers.tf` |
| Storage     | `enable_storage`     | {% if values.enable_storage %}Enabled{% else %}Disabled{% endif %} | S3 bucket, optional EFS file system | `storage.tf` |
| Database    | `enable_database`    | {% if values.enable_database %}Enabled{% else %}Disabled{% endif %} | RDS for PostgreSQL, optional DynamoDB table and ElastiCache Redis | `database.tf` |
| Security    | `enable_security`    | {% if values.enable_security %}Enabled{% else %}Disabled{% endif %} | GuardDuty, IAM Access Analyzer, EBS encryption by default | `security.tf` |
| Monitoring  | `enable_monitoring`  | {% if values.enable_monitoring %}Enabled{% else %}Disabled{% endif %} | Alarm topic, application log group, alarms, dashboard | `monitoring.tf` |
| Analytics   | `enable_analytics`   | {% if values.enable_analytics %}Enabled{% else %}Disabled{% endif %} | Kinesis data stream, Glue catalog database | `analytics.tf` |
| Integration | `enable_integration` | {% if values.enable_integration %}Enabled{% else %}Disabled{% endif %} | SQS queue with dead-letter queue, SNS topic, EventBridge bus | `integration.tf` |
| AI/ML       | `enable_ai_ml`       | {% if values.enable_ai_ml %}Enabled{% else %}Disabled{% endif %} | SageMaker execution role and model package group | `ai_ml.tf` |

A KMS key (`kms.tf`) is always created. It encrypts the logs, secrets, storage,
databases, queues and topics of the stack.

## Configuration

| Setting | Value |
| ------- | ----- |
| Environment | `${{ values.environment }}` |
| Region | `${{ values.region }}` |
| VPC CIDR | `${{ values.vpc_cidr }}` |
| NAT gateway | `${{ values.enable_nat_gateway }}` |
| VPN gateway | `${{ values.enable_vpn_gateway }}` |
| Transit gateway | `${{ values.enable_transit_gateway }}` |
| EC2 instance type | `${{ values.instance_type }}` with a ${{ values.ebs_volume_size }} GB root volume |
| EKS version | `${{ values.eks_version }}` |
| EKS nodes | ${{ values.eks_desired_nodes }} desired, ${{ values.eks_min_nodes }} to ${{ values.eks_max_nodes }} (`${{ values.eks_node_group_instance_types | join(', ') }}`) |
| S3 | KMS encryption `${{ values.s3_bucket_encryption }}`, versioning `${{ values.s3_versioning }}` |
| EFS | `${{ values.enable_efs }}` |
| RDS | `${{ values.rds_instance_class }}`, ${{ values.rds_allocated_storage }} GB, backups kept ${{ values.rds_backup_retention }} days |
| DynamoDB | `${{ values.enable_dynamodb }}` |
| ElastiCache | `${{ values.enable_elasticache }}` |

### Subnets

| Name | CIDR | Type |
| ---- | ---- | ---- |
{%- for subnet in values.subnet_configurations %}
| `${{ subnet.name }}` | `${{ subnet.cidr }}` | ${{ subnet.type }} |
{%- endfor %}

Public subnets route to the internet gateway, private subnets to the NAT
gateway, isolated subnets have no route out of the VPC. Subnets of the same
type are spread over the availability zones in name order. Workloads (EC2, EKS,
RDS, ElastiCache, EFS) are placed in the private subnets.

When `enable_networking` is `false`, set `existing_vpc_id` and
`existing_private_subnet_ids` so the other categories have a network to deploy
into.

### Production safeguards

`rds_multi_az` and `deletion_protection` are `true` for the `prod` and `dr`
environments and `false` otherwise. Change them in
`terraform.auto.tfvars.json`.

The Kubernetes API server is private. To reach it from outside the VPC set
`eks_endpoint_public_access` and `eks_public_access_cidrs`.

## CI/CD Pipeline

The workflow in `.github/workflows/terraform.yaml` runs on every push and pull
request to `main`, once a week for drift detection, and on demand from the
Actions tab.

| Job           | Runs when                                | What it does |
| ------------- | ---------------------------------------- | ------------ |
| Settings      | Always                                   | Detects which secrets are configured |
| Validate      | Always                                   | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, TFLint |
| Test          | After Validate                           | `terraform test` against mocked providers, including a plan of this repository's own configuration |
| Security scan | After Validate                           | Trivy and Checkov; findings of medium severity or higher fail the job |
| Cost estimate | Pull requests, `INFRACOST_API_KEY` set   | Posts an Infracost estimate on the pull request |
| Plan          | `AWS_ROLE_ARN` and `TF_STATE_BUCKET` set | Plans the stack and stores the plan as an artifact |
| Apply         | Manual run with action `apply`           | Applies the stored plan |
| Destroy       | Manual run with action `destroy`         | Destroys the stack after typing `DESTROY` |
| Drift         | Weekly schedule, AWS secrets set         | Warns when the deployed resources differ from the configuration |
| Summary       | Always                                   | Lists every job result and fails when a job failed |

A new repository has no secrets, so only the jobs that need no cloud account
run: Validate, Test and Security scan.

### Connecting an AWS account

1. Create an IAM OIDC identity provider for `token.actions.githubusercontent.com`
   in the AWS account and an IAM role that trusts this repository
   (`repo:${{ values.destination.owner }}/${{ values.destination.repo }}:*`). The role needs
   permission to manage the resources of the enabled categories.
2. Create an S3 bucket for the Terraform state and, optionally, a DynamoDB table
   with the hash key `LockID` for state locking.
3. Add the repository secrets under **Settings > Secrets and variables > Actions**:

| Secret                | Purpose |
| --------------------- | ------- |
| `AWS_ROLE_ARN`        | IAM role assumed through GitHub OIDC |
| `TF_STATE_BUCKET`     | S3 bucket holding the Terraform state |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking (optional) |
| `INFRACOST_API_KEY`   | Enables the cost estimate on pull requests (optional) |

Apply and Destroy run in the GitHub environment `${{ values.environment }}`. Add
required reviewers to it to make deployments wait for approval.

## Local use

```bash
terraform init -backend=false   # validation only, no state
terraform fmt -check -recursive
terraform validate
terraform test
```

To plan against an AWS account, initialise the backend first:

```bash
terraform init \
  -backend-config="bucket=<state bucket>" \
  -backend-config="key=${{ values.destination.owner }}/${{ values.destination.repo }}/${{ values.environment }}/terraform.tfstate" \
  -backend-config="region=${{ values.region }}"
terraform plan
```

## Security scanning

A finding fails the Security scan job. Fix the configuration, or, where the
finding is an accepted design choice, add an inline `checkov:skip=<check>: <reason>`
or `trivy:ignore:<check>` comment next to the resource. The exceptions already in
the code each carry their reason.

# AWS Full Infrastructure Stack

Creates a repository with one Terraform configuration for a complete AWS
environment. Each resource category is switched on or off in the form.

| Category    | Resources                                                                                         |
| ----------- | ------------------------------------------------------------------------------------------------- |
| Networking  | VPC, subnets, internet and NAT gateway, route tables, flow logs, optional VPN and transit gateway |
| Compute     | Launch template and Auto Scaling group managed through Systems Manager                            |
| Containers  | EKS cluster, managed node group, OIDC provider, ECR repository                                    |
| Storage     | S3 bucket, optional EFS file system                                                               |
| Database    | RDS for PostgreSQL, optional DynamoDB table and ElastiCache Redis                                 |
| Security    | GuardDuty, IAM Access Analyzer, EBS encryption by default                                         |
| Monitoring  | Alarm topic, application log group, alarms, dashboard                                             |
| Analytics   | Kinesis data stream, Glue catalog database                                                        |
| Integration | SQS queue with dead-letter queue, SNS topic, EventBridge bus                                      |
| AI/ML       | SageMaker execution role and model package group                                                  |

## What the new repository contains

- The Terraform configuration, with the form values in `terraform.auto.tfvars.json`.
- A GitHub Actions workflow that checks formatting, validates, lints (TFLint),
  runs `terraform test` against mocked providers and scans with Trivy and
  Checkov on every push. It needs no configuration.
- Plan, apply, destroy and drift detection jobs that start once the
  `AWS_ROLE_ARN` and `TF_STATE_BUCKET` secrets exist in the repository.
- TechDocs (`docs/index.md`) and a `catalog-info.yaml` that registers the stack
  as a Resource.

## Notes

- Workloads are placed in the subnets of type `private`. Keep at least two
  private subnets in different availability zones when the container or
  database category is enabled.
- Multi-AZ and deletion protection for the database are enabled for the `prod`
  and `dr` environments.

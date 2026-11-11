# ${{ values.projectName }} infrastructure

AWS three-tier web application infrastructure for **${{ values.projectName }}** in the **${{ values.environment }}** environment, region `${{ values.region }}`.

## Architecture

```text
              Internet
                 |
{%- if values.enableCloudfront %}
            CloudFront
                 |
{%- endif %}
{%- if values.enableWaf %}
              AWS WAF
                 |
{%- endif %}
   Application Load Balancer        public subnets
                 |
{%- if values.computeType == 'ecs-fargate' %}
     ECS service on Fargate         private subnets
{%- elif values.computeType == 'ecs-ec2' %}
  ECS service on EC2 instances      private subnets
{%- else %}
    EC2 Auto Scaling group          private subnets
{%- endif %}
                 |
       RDS ${{ values.databaseEngine }}        database subnets
```

## What was chosen

| Setting                 | Value                                |
| ----------------------- | ------------------------------------ |
| VPC CIDR                | `${{ values.vpcCidr }}`              |
| Compute type            | `${{ values.computeType }}`          |
| Instance type           | `${{ values.instanceType }}` (used by `ecs-ec2` and `ec2-asg`) |
| Capacity                | ${{ values.minCapacity }} to ${{ values.maxCapacity }} |
| Database engine         | `${{ values.databaseEngine }}`       |
| Database instance class | `${{ values.databaseInstanceClass }}` |
| Multi-AZ database       | ${{ 'yes' if values.multiAz else 'no' }} |
| AWS WAF                 | ${{ 'yes' if values.enableWaf else 'no' }} |
| CloudFront              | ${{ 'yes' if values.enableCloudfront else 'no' }} |

These are the contents of `terraform.tfvars`. Change a value there and open a pull request to change the infrastructure.

## Components

- **Network**: a VPC with three public, three private and three database subnets. Production uses one NAT gateway per availability zone, other environments share one.
- **Load balancer**: redirects HTTP to HTTPS. Until `certificate_arn` is set it uses a self-signed certificate, so browsers warn about the connection. Request a certificate for your domain in ACM and set `certificate_arn` before going live.
- **Application**: `compute_type` selects ECS on Fargate, ECS on EC2 container instances, or plain EC2 instances. Containers run `container_image` (a public nginx image by default). CPU-based auto scaling keeps the size between `min_capacity` and `max_capacity`. A `max_capacity` below `min_capacity` counts as `min_capacity`.
- **Database**: RDS in the database subnets, reachable only from the application's security group. RDS generates the master password and stores it in Secrets Manager; the secret's ARN is the output `database_master_user_secret_arn`.
- **WAF**: when enabled, a web ACL with the AWS managed rule groups and a per-address rate limit is attached to the load balancer.
- **CloudFront**: when enabled, a distribution uses the load balancer as its origin. CloudFront checks the origin's certificate, so set `certificate_arn` and `origin_domain_name` to a real domain first.

The building blocks are the Terraform modules of [cloud-sandbox-backstage](https://github.com/ayoinc/cloud-sandbox-backstage/tree/main/catalog/terraform-modules/aws/resources).

## Pipeline

The **Terraform** workflow checks every push and pull request without needing an AWS account: formatting, `terraform validate`, `terraform test` against mocked providers (`tests/stack.tftest.hcl`), TFLint and a Trivy scan for high and critical findings.

Plan and apply are skipped until these are set in the repository settings:

| Setting             | Kind     | Purpose                                                 |
| ------------------- | -------- | ------------------------------------------------------- |
| `AWS_ROLE_ARN`      | secret   | IAM role the workflow assumes through GitHub OIDC       |
| `TF_STATE_BUCKET`   | variable | S3 bucket that holds the Terraform state                |
| `INFRACOST_API_KEY` | secret   | Optional. Enables the cost estimate on pushes to `main` |

Every push to `main` then produces a plan. To apply, run the workflow from the Actions tab with **Apply** ticked.

## Outputs

| Output                            | Description                                        |
| --------------------------------- | -------------------------------------------------- |
| `alb_dns_name`                    | DNS name of the load balancer                      |
| `database_endpoint`               | Endpoint of the database                           |
| `database_master_user_secret_arn` | Secret that holds the database master password     |
| `ecs_cluster_name`                | ECS cluster, for the ECS compute types             |
| `autoscaling_group_name`          | Auto Scaling group, for `ecs-ec2` and `ec2-asg`    |
| `waf_web_acl_arn`                 | Web ACL, when WAF is enabled                       |
| `cloudfront_domain_name`          | Distribution domain, when CloudFront is enabled    |

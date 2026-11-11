# ${{ values.projectName }} infrastructure

AWS three-tier web application infrastructure for **${{ values.projectName }}** (${{ values.environment }}), managed with Terraform.

| Tier        | What is created                                                                 |
| ----------- | ------------------------------------------------------------------------------- |
| Network     | VPC `${{ values.vpcCidr }}` in `${{ values.region }}` with public, private and database subnets |
| Web         | Application Load Balancer{% if values.enableWaf %} protected by AWS WAF{% endif %}{% if values.enableCloudfront %}, behind CloudFront{% endif %} |
| Application | {% if values.computeType == 'ecs-fargate' %}ECS service on Fargate{% elif values.computeType == 'ecs-ec2' %}ECS service on `${{ values.instanceType }}` container instances{% else %}`${{ values.instanceType }}` instances in an Auto Scaling group{% endif %}, ${{ values.minCapacity }} to ${{ values.maxCapacity }} in size |
| Data        | RDS ${{ values.databaseEngine }} on `${{ values.databaseInstanceClass }}`{% if values.multiAz %}, Multi-AZ{% endif %} |

The values chosen in the portal are in [`terraform.tfvars`](terraform.tfvars). The full description is in [`docs/index.md`](docs/index.md).

## Pipeline

`.github/workflows/terraform.yml` runs on every push and pull request:

- `terraform fmt -check`, `terraform validate` and TFLint
- `terraform test`, which plans every compute type against mocked providers (`tests/stack.tftest.hcl`)
- a Trivy scan of the configuration for high and critical findings

Plan and apply need access to an AWS account and stay skipped until it is configured:

| Setting             | Kind     | Purpose                                                   |
| ------------------- | -------- | --------------------------------------------------------- |
| `AWS_ROLE_ARN`      | secret   | IAM role the workflow assumes through GitHub OIDC         |
| `TF_STATE_BUCKET`   | variable | S3 bucket that holds the Terraform state                  |
| `INFRACOST_API_KEY` | secret   | Optional. Enables the cost estimate on pushes to `main`   |

With those set, every push to `main` produces a plan. To apply, run the workflow manually from the Actions tab with **Apply** ticked.

## Working locally

```bash
terraform init -backend-config="bucket=<state bucket>"
terraform plan
```

Use `terraform init -backend=false` to validate without access to the state bucket.

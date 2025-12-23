# ${{ values.name }}

AWS VPC for **${{ values.environment }}** in **${{ values.aws_region }}**.

## Configuration

| Setting | Value |
|---------|-------|
| CIDR | ${{ values.vpc_cidr }} |
| AZs | ${{ values.azs }} |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

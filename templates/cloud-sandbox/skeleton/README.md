# ${{ values.name }}

${{ values.description }}

## Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

- Provider: ${{ values.cloud_provider }}
- Region: ${{ values.region }}
- Environment: ${{ values.environment }}
- VPC CIDR: ${{ values.vpc_cidr }}

## Destroy

```bash
terraform destroy
```

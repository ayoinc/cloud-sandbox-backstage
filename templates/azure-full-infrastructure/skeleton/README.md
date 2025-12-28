# ${{ values.name }} - Azure Infrastructure

Terraform infrastructure for ${{ values.name }} on Azure.

## Enabled Resources

| Category | Resource | Enabled |
|----------|----------|---------|
| Networking | VNet, Subnets, NSG | ${{ values.enable_networking }} |
| Compute | Virtual Machines | ${{ values.enable_vms }} |
| Compute | App Service | ${{ values.enable_app_service }} |
| Compute | Functions | ${{ values.enable_functions }} |
| Compute | Container Apps | ${{ values.enable_container_apps }} |
| Containers | AKS | ${{ values.enable_aks }} |
| Containers | ACR | ${{ values.enable_acr }} |
| Storage | Storage Account | ${{ values.enable_storage }} |
| Database | Azure SQL | ${{ values.enable_sql }} |
| Database | Cosmos DB | ${{ values.enable_cosmos }} |
| Database | PostgreSQL | ${{ values.enable_postgresql }} |
| Database | Redis | ${{ values.enable_redis }} |
| Security | Key Vault | ${{ values.enable_keyvault }} |
| Monitoring | Log Analytics | ${{ values.enable_log_analytics }} |
| Integration | Service Bus | ${{ values.enable_service_bus }} |
| Integration | API Management | ${{ values.enable_api_management }} |

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file=terraform.tfvars

# Apply
terraform apply -var-file=terraform.tfvars
```

## Testing

```bash
terraform test
```

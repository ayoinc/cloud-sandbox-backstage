# Operations Guide

## Day-to-Day Operations

### Applying Changes

1. **Development**:
   ```bash
   terraform plan -var-file=environments/dev.tfvars
   terraform apply -var-file=environments/dev.tfvars
   ```

2. **Staging**:
   ```bash
   terraform plan -var-file=environments/staging.tfvars
   terraform apply -var-file=environments/staging.tfvars
   ```

3. **Production** (requires approval):
   ```bash
   terraform plan -var-file=environments/prod.tfvars -out=tfplan
   # Review plan carefully
   terraform apply tfplan
   ```

### Viewing Outputs

```bash
terraform output
terraform output -json
```

### State Management

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.aws_infrastructure[0].aws_s3_bucket.main

# Move resources
terraform state mv <source> <destination>
```

## Monitoring

{% if values.enable_monitoring %}
### Accessing Dashboards

{% if values.monitoring_solution == 'prometheus-grafana' %}
**Grafana**:
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Access at http://localhost:3000
```

**Prometheus**:
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Access at http://localhost:9090
```
{% endif %}

### Key Metrics

- CPU/Memory utilization
- Network throughput
- Database connections
- Request latency
- Error rates
{% endif %}

## Troubleshooting

### Common Issues

#### Terraform State Lock

```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

#### Resource Already Exists

```bash
# Import existing resource
terraform import module.aws_infrastructure[0].aws_s3_bucket.main bucket-name
```

#### Provider Authentication

Ensure credentials are configured:

```bash
# AWS
aws sts get-caller-identity

# Azure
az account show

# GCP
gcloud auth list
```

### Kubernetes Access

{% if values.enable_kubernetes %}
```bash
# Configure kubectl
$(terraform output -raw kubectl_config_command)

# Verify connection
kubectl get nodes
kubectl get pods -A
```
{% endif %}

## Backup and Recovery

### Terraform State

State is stored in remote backend with:
- Encryption enabled
- Versioning enabled
- Locking via DynamoDB

### Database Backups

{% if values.enable_database %}
- Automated daily backups
- Point-in-time recovery enabled
- Retention period: 7-30 days based on environment
{% endif %}

## Scaling

### Horizontal Scaling

{% if values.enable_kubernetes %}
```bash
# Scale node pool
# Update min_nodes/max_nodes in tfvars and apply
```
{% endif %}

### Vertical Scaling

```bash
# Change instance types in tfvars
# terraform apply with new configuration
```

## Security

### Rotating Credentials

```bash
# Regenerate database password
terraform apply -replace="module.common.random_password.database_password"
```

### Updating Security Groups

Modify variables in tfvars and apply:
- `allowed_cidr_blocks`
- `enable_private_endpoints`

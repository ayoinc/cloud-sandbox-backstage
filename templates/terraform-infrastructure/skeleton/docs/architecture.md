# Architecture

## Infrastructure Components

### Networking

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
#### AWS VPC
- VPC with configurable CIDR block
- Public and private subnets across multiple AZs
- NAT Gateway for private subnet internet access
- VPC Flow Logs for network monitoring
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
#### Azure VNet
- Virtual Network with configurable address space
- Public and private subnets
- Network Security Groups (NSGs)
- Azure Bastion for secure access
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
#### GCP VPC
- VPC Network with custom subnets
- Cloud NAT for outbound connectivity
- VPC Service Controls (optional)
{% endif %}

### Compute

{% if values.enable_kubernetes %}
#### Managed Kubernetes

| Cloud | Service | Version |
|-------|---------|---------|
| AWS   | EKS     | ${{ values.kubernetes_version }} |
| Azure | AKS     | ${{ values.kubernetes_version }} |
| GCP   | GKE     | ${{ values.kubernetes_version }} |

**Node Configuration:**
- Instance Type: ${{ values.node_instance_type }}
- Min Nodes: ${{ values.min_nodes }}
- Max Nodes: ${{ values.max_nodes }}
- Autoscaling: ${{ values.enable_autoscaling }}
{% endif %}

### Database

{% if values.enable_database %}
**Database Type**: ${{ values.database_type }}

| Cloud | Service |
|-------|---------|
| AWS   | RDS / DynamoDB |
| Azure | PostgreSQL Flexible Server / CosmosDB |
| GCP   | Cloud SQL / Firestore |
{% endif %}

### Security

- **Encryption**: All data encrypted at rest and in transit
- **Secrets Management**: Cloud-native secrets manager
- **Access Control**: IAM policies and RBAC
{% if values.enable_waf %}
- **WAF**: Web Application Firewall enabled
{% endif %}

## Data Flow

```
                    ┌─────────────┐
                    │   Users     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Load Balancer│
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐     │     ┌──────▼──────┐
       │   Service A │     │     │   Service B │
       └──────┬──────┘     │     └──────┬──────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    ┌──────▼──────┐
                    │  Database   │
                    └─────────────┘
```

## High Availability

### Multi-AZ Deployment

All critical components are deployed across multiple availability zones:

- Load balancers span all available AZs
- Kubernetes nodes distributed across AZs
- Database with automatic failover
- Storage with cross-region replication (production)

### Disaster Recovery

{% if values.enable_disaster_recovery %}
Disaster recovery is enabled with:
- Regular automated backups
- Cross-region replication
- Defined RTO and RPO targets
{% else %}
Basic backup strategy configured.
{% endif %}

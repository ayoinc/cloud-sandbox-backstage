# {{ componentName }} - GCP Infrastructure

{{ description }}

## Architecture Overview

![GCP Infrastructure Architecture](docs/diagrams/architecture.png)

This diagram shows the complete GCP infrastructure stack deployed by this template.

## Resources Included

| Category | Resources | Status |
|----------|-----------|--------|
| Networking | VPC Network, Subnets, Firewall Rules | {% if enable_networking %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Compute | Compute Engine VMs, Instance Groups | {% if enable_compute %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Containers | GKE Cluster, Artifact Registry | {% if enable_containers %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Storage | Cloud Storage, Filestore | {% if enable_storage %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Database | Cloud SQL, Firestore, Memorystore | {% if enable_database %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Security | Secret Manager, KMS, IAM | {% if enable_security %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Monitoring | Cloud Monitoring, Logging | {% if enable_monitoring %}✅ Enabled{% else %}❌ Disabled{% endif %} |

## Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="environment={{ environment }}" -var="region={{ region }}" -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

## Configuration

**Environment:** {{ environment }}
**Region:** {{ region }}
**Network CIDR:** {{ network_cidr }}

{% if enable_containers %}
### Kubernetes Configuration
- **GKE Version:** {{ gke_version }}
- **Node Machine Type:** {{ gke_node_machine_type }}
- **Initial Nodes:** {{ gke_initial_node_count }}
- **Min/Max Nodes:** {{ gke_min_node_count }}/{{ gke_max_node_count }}
{% endif %}

{% if enable_compute %}
### Compute Configuration
- **Machine Type:** {{ machine_type }}
- **Boot Disk Size:** {{ boot_disk_size }} GB
{% endif %}

{% if enable_database %}
### Database Configuration
- **Cloud SQL Version:** {{ cloudsql_database_version }}
- **Cloud SQL Tier:** {{ cloudsql_tier }}
- **Disk Size:** {{ cloudsql_disk_size }} GB
- **Backup Retention:** {{ cloudsql_backup_retention }} days
{% endif %}

## Architecture Layers

### Network Layer
- **VPC Network** with public, private, and data subnets across multiple regions
- **Cloud Load Balancing** (global and regional)
- **Cloud NAT** for private subnet internet access
- **Cloud Router** and **Cloud Interconnect** for hybrid connectivity
- **VPC Service Controls** for security perimeter
- **Cloud Armor** for DDoS and WAF protection

### Security Layer
- **Secret Manager** for secrets management
- **Cloud KMS** for encryption at rest
- **IAM** with workload identity
- **VPC Service Controls** for data exfiltration protection
- **Security Command Center** for threat detection
- **Binary Authorization** for container security

### Container & Compute Layer
- **GKE Cluster** (Standard or Autopilot)
- **Compute Engine** VMs and managed instance groups
- **Artifact Registry** for container images
- **Cloud Build** for CI/CD
- **Cloud Functions** for serverless compute
- **Cloud Run** for containerized applications

### Data Layer
- **Cloud SQL** for managed PostgreSQL, MySQL, or SQL Server
- **Firestore** for document database
- **BigQuery** for data warehousing
- **Memorystore** Redis for caching
- **Cloud Storage** for object storage
- **Filestore** for managed NFS
- **Persistent Disks** for block storage

### Observability Layer
- **Cloud Monitoring** for metrics and dashboards
- **Cloud Logging** for centralized logging
- **Error Reporting** for crash analysis
- **Cloud Trace** for request tracing
- **Cloud Profiler** for performance profiling
- **Cloud Debugger** for production debugging

## Testing

Run the Terraform test suite:

```bash
cd tests
terraform test
```

## Security Best Practices

✅ All resources encrypted at rest and in transit
✅ Customer-managed encryption keys (CMEK)
✅ VPC Service Controls for data exfiltration prevention
✅ Workload Identity for GKE service accounts
✅ Secret Manager for secrets management
✅ Binary Authorization for container security
✅ Cloud Armor for DDoS and WAF protection

## Documentation

See [docs/](docs/) for detailed documentation.

## Support

For issues and questions, contact the platform team or create an issue in the repository.

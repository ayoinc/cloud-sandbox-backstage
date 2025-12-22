# AWX Deployment - ${{ values.name }}

This repository contains the Kubernetes deployment configuration for AWX instance **${{ values.name }}** in the **${{ values.environment }}** environment.

## Overview

This deployment was generated using the AWX Backstage platform and includes:

- AWX Custom Resource Definition
- Kubernetes manifests for deployment
- Security configurations and secrets
- Automated deployment scripts
- Monitoring and maintenance tools

## Configuration

| Parameter | Value |
|-----------|--------|
| **Instance Name** | ${{ values.name }} |
| **Namespace** | ${{ values.namespace }} |
| **Environment** | ${{ values.environment }} |
| **AWX Version** | ${{ values.awx_version }} |
| **Service Type** | ${{ values.service_type }} |
{%- if values.ingress_enabled %}
| **Hostname** | ${{ values.hostname }} |
| **Ingress Enabled** | Yes |
{%- else %}
| **Ingress Enabled** | No |
{%- endif %}
| **SSL/TLS** | ${{ values.ssl_enabled | yesno:"Enabled,Disabled" }} |
| **LDAP** | ${{ values.ldap_enabled | yesno:"Enabled,Disabled" }} |
| **Admin User** | ${{ values.admin_user }} |

## Prerequisites

1. **Kubernetes Cluster:** A running Kubernetes cluster with sufficient resources
2. **kubectl:** Kubernetes command-line tool configured to access your cluster
3. **AWX Operator:** The AWX operator must be installed in the cluster
4. **Storage Class:** A configured storage class named `${{ values.storage_class }}`
{%- if values.ssl_enabled and values.ingress_enabled %}
5. **Cert-manager:** For automatic SSL certificate management
{%- endif %}
{%- if values.ingress_enabled %}
6. **Ingress Controller:** NGINX ingress controller or compatible
{%- endif %}

### Installing AWX Operator

If the AWX operator is not already installed:

```bash
# Install the operator
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml

# Verify installation
kubectl get pods -n awx-operator
```

## Quick Start

### 1. Deploy AWX

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Deploy AWX
./deploy.sh deploy
```

### 2. Check Status

```bash
# Check deployment status
./deploy.sh status

# Watch pods
kubectl get pods -n ${{ values.namespace }} -w
```

### 3. Access AWX

{%- if values.ingress_enabled %}
Once deployed, access AWX at: **https://${{ values.hostname }}**
{%- elif values.service_type == 'NodePort' %}
Access AWX via NodePort (check the deployment output for the exact URL)
{%- else %}
For ClusterIP service, use port forwarding:
```bash
kubectl port-forward -n ${{ values.namespace }} svc/awx-${{ values.name }}-service 8080:80
```
Then access: **http://localhost:8080**
{%- endif %}

Default credentials:
- **Username:** ${{ values.admin_user }}
- **Password:** Check the deployment output or get from secret

## Project Structure

```
${{ values.name }}-awx-deployment/
├── k8s/
│   ├── namespace.yaml          # Kubernetes namespace
│   ├── secrets.yaml           # Secrets for passwords and certificates
│   ├── awx.yaml               # AWX custom resource
│   └── kustomization.yaml     # Kustomize configuration
├── deploy.sh                  # Deployment automation script
├── README.md                  # This file
└── catalog-info.yaml          # Backstage catalog information
```

## Deployment Commands

### Deploy
```bash
./deploy.sh deploy
```

### Check Status
```bash
./deploy.sh status
```

### View Logs
```bash
./deploy.sh logs
```

### Delete (Caution!)
```bash
./deploy.sh delete
```

## Manual Deployment

If you prefer manual deployment:

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy secrets
kubectl apply -f k8s/secrets.yaml

# Deploy AWX
kubectl apply -f k8s/awx.yaml

# Or use Kustomize
kubectl apply -k k8s/
```

## Configuration Details

### Resource Requirements

{%- if values.environment == 'production' %}
**Production Configuration:**
- Web containers: 1-2 CPU, 2-4Gi memory
- Task containers: 0.5-1 CPU, 1-2Gi memory
- Execution environment: 0.5-1 CPU, 1-2Gi memory
- Redis: 0.5-1 CPU, 1-2Gi memory
- High availability: 2 replicas
{%- elif values.environment == 'staging' %}
**Staging Configuration:**
- Web containers: 0.5-1 CPU, 1-2Gi memory
- Task containers: 0.25-0.5 CPU, 0.5-1Gi memory
- Execution environment: 0.25-0.5 CPU, 0.5-1Gi memory
- Redis: 0.25-0.5 CPU, 0.5-1Gi memory
- Single replica for cost efficiency
{%- else %}
**Development Configuration:**
- Web containers: 0.5-1 CPU, 1-2Gi memory
- Task containers: 0.25-0.5 CPU, 0.5-1Gi memory
- Execution environment: 0.25-0.5 CPU, 0.5-1Gi memory
- Redis: 0.25-0.5 CPU, 0.5-1Gi memory
- Single replica with auto-upgrade enabled
{%- endif %}

### Storage

- **PostgreSQL:** ${{ values.postgres_storage_size }} persistent storage
- **Projects:** ${{ values.project_storage_size }} shared storage (ReadWriteMany)
- **Storage Class:** ${{ values.storage_class }}

### Security

{%- if values.ssl_enabled %}
- **SSL/TLS:** Enabled with automatic certificate management
{%- else %}
- **SSL/TLS:** Disabled (not recommended for production)
{%- endif %}
{%- if values.ldap_enabled %}
- **LDAP:** Configured for external authentication
{%- else %}
- **LDAP:** Not configured (using local authentication)
{%- endif %}
- **Admin Password:** Stored in Kubernetes secret
- **Database Password:** Stored in Kubernetes secret

## Troubleshooting

### Common Issues

1. **AWX not starting:**
   ```bash
   # Check AWX resource status
   kubectl describe awx ${{ values.name }} -n ${{ values.namespace }}
   
   # Check operator logs
   kubectl logs -n awx-operator deployment/awx-operator-controller-manager
   ```

2. **Database connection issues:**
   ```bash
   # Check PostgreSQL pod
   kubectl get pods -n ${{ values.namespace }} | grep postgres
   
   # Check database secret
   kubectl get secret awx-${{ values.name }}-postgres-configuration -n ${{ values.namespace }} -o yaml
   ```

3. **Storage issues:**
   ```bash
   # Check persistent volume claims
   kubectl get pvc -n ${{ values.namespace }}
   
   # Check storage class
   kubectl get storageclass ${{ values.storage_class }}
   ```

{%- if values.ingress_enabled %}
4. **Ingress not working:**
   ```bash
   # Check ingress
   kubectl describe ingress -n ${{ values.namespace }}
   
   # Check ingress controller
   kubectl get pods -n ingress-nginx
   ```
{%- endif %}

### Accessing AWX Logs

```bash
# AWX web container logs
kubectl logs -n ${{ values.namespace }} deployment/awx-${{ values.name }}-web

# AWX task container logs
kubectl logs -n ${{ values.namespace }} deployment/awx-${{ values.name }}-task

# PostgreSQL logs
kubectl logs -n ${{ values.namespace }} deployment/awx-${{ values.name }}-postgres-13
```

### Getting AWX Admin Password

```bash
kubectl get secret awx-${{ values.name }}-admin-password -n ${{ values.namespace }} -o jsonpath='{.data.password}' | base64 -d
```

## Maintenance

### Updating AWX

1. Update the AWX version in `k8s/awx.yaml`
2. Apply the changes:
   ```bash
   kubectl apply -f k8s/awx.yaml
   ```

### Scaling

For production environments, you can scale AWX:

```bash
# Edit the AWX resource
kubectl edit awx ${{ values.name }} -n ${{ values.namespace }}

# Add or modify:
spec:
  replicas: 3  # Increase replica count
```

### Backup

Regular backups are essential:

```bash
# Backup AWX configuration
kubectl get awx ${{ values.name }} -n ${{ values.namespace }} -o yaml > awx-backup.yaml

# Backup secrets
kubectl get secrets -n ${{ values.namespace }} -o yaml > secrets-backup.yaml
```

## Security Considerations

{%- if values.environment == 'production' %}
### Production Security Checklist

- [ ] Change default admin password
- [ ] Update database passwords
- [ ] Configure proper SSL certificates
- [ ] Set up network policies
- [ ] Enable audit logging
- [ ] Configure LDAP/SSO authentication
- [ ] Regular security updates
- [ ] Backup encryption
{%- endif %}

### Security Best Practices

1. **Change default passwords immediately**
2. **Use strong, unique passwords**
3. **Enable SSL/TLS in production**
4. **Configure network policies**
5. **Regular security updates**
6. **Monitor access logs**
7. **Use RBAC for Kubernetes access**

## Monitoring

Consider setting up monitoring for:

- AWX pod health and resource usage
- Database performance
- Storage utilization
- Network connectivity
- Application-level metrics

## Support

- **AWX Documentation:** https://ansible.readthedocs.io/projects/awx/en/latest/
- **AWX Operator:** https://github.com/ansible/awx-operator
- **Community Forum:** https://forum.ansible.com/
- **Issues:** Report issues in your project repository

## Contributing

1. Follow Kubernetes best practices
2. Test changes in development first
3. Update documentation
4. Use proper commit messages

---

**Generated with ❤️ by AWX Backstage Platform**

Environment: ${{ values.environment }} | Instance: ${{ values.name }} | Owner: ${{ values.owner }}

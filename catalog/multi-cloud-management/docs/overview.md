# Overview

## Architecture Deep Dive

### Multi-Cloud Abstraction Layer

The Multi-Cloud Management platform provides a unified abstraction layer that normalizes cloud provider APIs and resources:

```d2
direction: down

title: Multi-Cloud Abstraction Patterns {
  shape: text
  near: top-center
  style.font-size: 24
}

request: Application Request {
  shape: rectangle
  style.fill: "#E3F2FD"
}

interfaces: Unified Resource Interface {
  style.fill: "#E8F5E9"
  
  compute: Compute\nInterface {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  database: Database\nInterface {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  
  storage: Storage\nInterface {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

adapters: Provider Adapters {
  style.fill: "#FFF3E0"
  
  aws_adapter: AWS Adapter {
    style.fill: "#FF9900"
    style.font-color: white
    
    mapping: EC2 → VM\nRDS → DB\nS3 → Blob {
      shape: text
      style.font-size: 12
    }
  }
  
  azure_adapter: Azure Adapter {
    style.fill: "#0078D4"
    style.font-color: white
    
    mapping: VM → VM\nSQL → DB\nBlob → Blob {
      shape: text
      style.font-size: 12
    }
  }
  
  gcp_adapter: GCP Adapter {
    style.fill: "#4285F4"
    style.font-color: white
    
    mapping: GCE → VM\nSQL → DB\nGCS → Blob {
      shape: text
      style.font-size: 12
    }
  }
}

apis: Cloud APIs {
  style.fill: "#FCE4EC"
  
  aws_api: AWS API {shape: rectangle; style.fill: "#FF9900"; style.font-color: white}
  azure_api: Azure API {shape: rectangle; style.fill: "#0078D4"; style.font-color: white}
  gcp_api: GCP API {shape: rectangle; style.fill: "#4285F4"; style.font-color: white}
}

request -> interfaces
interfaces -> adapters
adapters.aws_adapter -> apis.aws_api
adapters.azure_adapter -> apis.azure_api
adapters.gcp_adapter -> apis.gcp_api
```

### Cross-Cloud Networking

```d2
direction: right

title: Cross-Cloud Network Topology {
  shape: text
  near: top-center
  style.font-size: 24
}

aws: AWS us-east-1 {
  style.fill: "#FFF3E0"
  
  vpc: VPC\n10.0.0.0/16 {
    style.fill: "#FF9900"
    style.font-color: white
    
    subnet: Private Subnet\n10.0.1.x {
      shape: rectangle
    }
  }
  
  vpn: VPN Gateway {
    shape: hexagon
    style.fill: "#FF9900"
    style.font-color: white
  }
  
  vpc -> vpn
}

azure: Azure eastus {
  style.fill: "#E3F2FD"
  
  vnet: VNet\n10.1.0.0/16 {
    style.fill: "#0078D4"
    style.font-color: white
    
    subnet: Private Subnet\n10.1.1.x {
      shape: rectangle
    }
  }
  
  vpn: VPN Gateway {
    shape: hexagon
    style.fill: "#0078D4"
    style.font-color: white
  }
  
  vnet -> vpn
}

gcp: GCP us-east1 {
  style.fill: "#E8F5E9"
  
  gcp_vpc: VPC\n10.2.0.0/16 {
    style.fill: "#4285F4"
    style.font-color: white
    
    subnet: Private Subnet\n10.2.1.x {
      shape: rectangle
    }
  }
  
  vpn: VPN Gateway {
    shape: hexagon
    style.fill: "#4285F4"
    style.font-color: white
  }
  
  gcp_vpc -> vpn
}

dns: Global DNS {
  style.fill: "#FCE4EC"
  
  routes: app.example.com\n├── aws.app → 10.0.1.x\n├── azure.app → 10.1.1.x\n└── gcp.app → 10.2.1.x {
    shape: document
    style.fill: "#E91E63"
    style.font-color: white
  }
}

aws.vpn <-> azure.vpn: IPSec Tunnel
azure.vpn <-> gcp.vpn: IPSec Tunnel
aws.vpn <-> gcp.vpn: IPSec Tunnel {style.stroke-dash: 3}
dns -> aws
dns -> azure
dns -> gcp
```

## Terraform Module Design

### Unified Compute Module

```hcl
# modules/compute/main.tf
# Multi-cloud compute abstraction

variable "cloud_provider" {
  description = "Target cloud provider: aws, azure, gcp"
  type        = string
  validation {
    condition     = contains(["aws", "azure", "gcp"], var.cloud_provider)
    error_message = "Valid values: aws, azure, gcp"
  }
}

variable "instance_config" {
  description = "Unified instance configuration"
  type = object({
    name          = string
    size          = string  # small, medium, large, xlarge
    image         = string
    subnet_id     = string
    tags          = map(string)
  })
}

locals {
  # Size mapping across clouds
  size_map = {
    aws = {
      small  = "t3.small"
      medium = "t3.medium"
      large  = "t3.large"
      xlarge = "t3.xlarge"
    }
    azure = {
      small  = "Standard_B1ms"
      medium = "Standard_B2s"
      large  = "Standard_B4ms"
      xlarge = "Standard_B8ms"
    }
    gcp = {
      small  = "e2-small"
      medium = "e2-medium"
      large  = "e2-standard-4"
      xlarge = "e2-standard-8"
    }
  }
}

# AWS EC2 Instance
resource "aws_instance" "this" {
  count = var.cloud_provider == "aws" ? 1 : 0

  ami           = var.instance_config.image
  instance_type = local.size_map.aws[var.instance_config.size]
  subnet_id     = var.instance_config.subnet_id

  tags = merge(var.instance_config.tags, {
    Name = var.instance_config.name
  })
}

# Azure Virtual Machine
resource "azurerm_linux_virtual_machine" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = var.instance_config.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = local.size_map.azure[var.instance_config.size]
  admin_username      = "adminuser"

  network_interface_ids = [azurerm_network_interface.this[0].id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.instance_config.tags
}

# GCP Compute Instance
resource "google_compute_instance" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name         = var.instance_config.name
  machine_type = local.size_map.gcp[var.instance_config.size]
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.instance_config.image
    }
  }

  network_interface {
    subnetwork = var.instance_config.subnet_id
  }

  labels = var.instance_config.tags
}

output "instance_id" {
  value = coalesce(
    try(aws_instance.this[0].id, null),
    try(azurerm_linux_virtual_machine.this[0].id, null),
    try(google_compute_instance.this[0].id, null)
  )
}

output "private_ip" {
  value = coalesce(
    try(aws_instance.this[0].private_ip, null),
    try(azurerm_linux_virtual_machine.this[0].private_ip_address, null),
    try(google_compute_instance.this[0].network_interface[0].network_ip, null)
  )
}
```

### Unified Kubernetes Module

```hcl
# modules/kubernetes/main.tf
# Multi-cloud Kubernetes cluster abstraction

variable "cloud_provider" {
  type = string
}

variable "cluster_config" {
  type = object({
    name               = string
    kubernetes_version = string
    node_pools = list(object({
      name           = string
      node_count     = number
      instance_type  = string
      disk_size_gb   = number
    }))
    network_config = object({
      vpc_id     = string
      subnet_ids = list(string)
    })
  })
}

# AWS EKS
module "eks" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_config.name
  cluster_version = var.cluster_config.kubernetes_version

  vpc_id     = var.cluster_config.network_config.vpc_id
  subnet_ids = var.cluster_config.network_config.subnet_ids

  eks_managed_node_groups = {
    for pool in var.cluster_config.node_pools : pool.name => {
      desired_size   = pool.node_count
      instance_types = [pool.instance_type]
      disk_size      = pool.disk_size_gb
    }
  }
}

# Azure AKS
resource "azurerm_kubernetes_cluster" "this" {
  count = var.cloud_provider == "azure" ? 1 : 0

  name                = var.cluster_config.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_config.name
  kubernetes_version  = var.cluster_config.kubernetes_version

  default_node_pool {
    name       = var.cluster_config.node_pools[0].name
    node_count = var.cluster_config.node_pools[0].node_count
    vm_size    = var.cluster_config.node_pools[0].instance_type
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }
}

# GCP GKE
resource "google_container_cluster" "this" {
  count = var.cloud_provider == "gcp" ? 1 : 0

  name     = var.cluster_config.name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = var.cluster_config.kubernetes_version

  network    = var.cluster_config.network_config.vpc_id
  subnetwork = var.cluster_config.network_config.subnet_ids[0]

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "this" {
  for_each = var.cloud_provider == "gcp" ? {
    for pool in var.cluster_config.node_pools : pool.name => pool
  } : {}

  name       = each.value.name
  cluster    = google_container_cluster.this[0].id
  node_count = each.value.node_count

  node_config {
    machine_type = each.value.instance_type
    disk_size_gb = each.value.disk_size_gb

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
```

## Identity Federation

### Cross-Cloud Identity Architecture

```yaml
# Cross-cloud identity federation configuration
identity_federation:
  # Primary identity provider
  primary_idp: azure_entra_id
  
  # AWS configuration
  aws:
    # SAML federation with Azure AD
    saml_provider:
      name: AzureAD
      metadata_url: https://login.microsoftonline.com/{tenant}/federationmetadata/2007-06/federationmetadata.xml
    
    # Role mappings
    role_mappings:
      - azure_group: Platform-Admins
        aws_role: arn:aws:iam::123456789:role/PlatformAdmin
      - azure_group: Developers
        aws_role: arn:aws:iam::123456789:role/Developer
  
  # GCP configuration
  gcp:
    # Workload Identity Federation
    workload_identity_pool: azure-identity-pool
    workload_identity_provider: azure-ad
    
    # Service account mappings
    sa_mappings:
      - azure_group: Platform-Admins
        gcp_sa: platform-admin@project.iam.gserviceaccount.com
      - azure_group: Developers
        gcp_sa: developer@project.iam.gserviceaccount.com
```

### Terraform Identity Configuration

```hcl
# AWS SAML Provider
resource "aws_iam_saml_provider" "azure_ad" {
  name                   = "AzureAD"
  saml_metadata_document = file("${path.module}/azure-ad-metadata.xml")
}

resource "aws_iam_role" "federated_admin" {
  name = "FederatedAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_saml_provider.azure_ad.arn
      }
      Action = "sts:AssumeRoleWithSAML"
      Condition = {
        StringEquals = {
          "SAML:aud" = "https://signin.aws.amazon.com/saml"
        }
      }
    }]
  })
}

# GCP Workload Identity Federation
resource "google_iam_workload_identity_pool" "azure" {
  project                   = var.project_id
  workload_identity_pool_id = "azure-identity-pool"
  display_name              = "Azure AD Pool"
}

resource "google_iam_workload_identity_pool_provider" "azure" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.azure.workload_identity_pool_id
  workload_identity_pool_provider_id = "azure-ad"
  display_name                       = "Azure AD"

  oidc {
    issuer_uri = "https://sts.windows.net/${var.azure_tenant_id}/"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.email"      = "assertion.email"
    "attribute.groups"     = "assertion.groups"
  }
}
```

## Policy as Code

### OPA/Rego Policies

```rego
# policies/multi-cloud-compliance.rego
package multicloud.compliance

# Deny resources without required tags
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    required_tags := {"Environment", "Owner", "CostCenter", "Project"}
    
    resource_tags := object.get(resource.values, "tags", {})
    missing := required_tags - {key | resource_tags[key]}
    count(missing) > 0
    
    msg := sprintf(
        "Resource %s is missing required tags: %v",
        [resource.address, missing]
    )
}

# Enforce encryption at rest
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    
    not has_encryption(resource)
    
    msg := sprintf("S3 bucket %s must have encryption enabled", [resource.address])
}

deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "azurerm_storage_account"
    
    not resource.values.enable_https_traffic_only
    
    msg := sprintf("Azure Storage %s must have HTTPS only enabled", [resource.address])
}

deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "google_storage_bucket"
    
    not has_uniform_bucket_access(resource)
    
    msg := sprintf("GCS bucket %s must have uniform bucket-level access", [resource.address])
}

# Enforce private endpoints for databases
deny[msg] {
    resource := input.planned_values.root_module.resources[_]
    is_database_resource(resource.type)
    
    is_publicly_accessible(resource)
    
    msg := sprintf("Database %s must not be publicly accessible", [resource.address])
}

is_database_resource(type) {
    type == "aws_db_instance"
}
is_database_resource(type) {
    type == "azurerm_postgresql_flexible_server"
}
is_database_resource(type) {
    type == "google_sql_database_instance"
}
```

### Sentinel Policies

```hcl
# policies/sentinel/enforce-regions.sentinel
import "tfplan/v2" as tfplan

# Allowed regions per cloud
allowed_regions = {
    "aws": ["us-east-1", "us-west-2", "eu-west-1"],
    "azure": ["eastus", "westus2", "westeurope"],
    "gcp": ["us-east1", "us-west1", "europe-west1"],
}

# AWS resources
aws_resources = filter tfplan.resource_changes as _, rc {
    rc.provider_name matches "registry.terraform.io/hashicorp/aws" and
    rc.mode is "managed" and
    rc.change.actions contains "create"
}

# Check AWS regions
aws_region_violations = filter aws_resources as _, r {
    r.change.after.region not in allowed_regions["aws"]
}

# Main rule
main = rule {
    length(aws_region_violations) is 0
}
```

## Cost Management

### Cross-Cloud Cost Tracking

```python
#!/usr/bin/env python3
# scripts/cost-report.py
"""Multi-cloud cost aggregation and reporting."""

import boto3
import json
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from azure.mgmt.costmanagement import CostManagementClient
from google.cloud import billing_v1

class MultiCloudCostReport:
    def __init__(self):
        self.aws_client = boto3.client('ce')
        self.azure_credential = DefaultAzureCredential()
        self.gcp_client = billing_v1.CloudBillingClient()
    
    def get_aws_costs(self, start_date: str, end_date: str) -> dict:
        """Get AWS costs by service."""
        response = self.aws_client.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='DAILY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'},
                {'Type': 'TAG', 'Key': 'Environment'}
            ]
        )
        return self._parse_aws_response(response)
    
    def get_azure_costs(self, subscription_id: str, 
                        start_date: str, end_date: str) -> dict:
        """Get Azure costs by resource group."""
        client = CostManagementClient(self.azure_credential)
        scope = f"/subscriptions/{subscription_id}"
        
        query = {
            "type": "ActualCost",
            "timeframe": "Custom",
            "timePeriod": {
                "from": start_date,
                "to": end_date
            },
            "dataset": {
                "granularity": "Daily",
                "aggregation": {
                    "totalCost": {"name": "Cost", "function": "Sum"}
                },
                "grouping": [
                    {"type": "Dimension", "name": "ResourceGroup"},
                    {"type": "Dimension", "name": "ServiceName"}
                ]
            }
        }
        
        response = client.query.usage(scope, query)
        return self._parse_azure_response(response)
    
    def get_gcp_costs(self, billing_account: str,
                      start_date: str, end_date: str) -> dict:
        """Get GCP costs by project and service."""
        # BigQuery query for billing export
        query = f"""
        SELECT
            project.name as project,
            service.description as service,
            SUM(cost) as total_cost,
            SUM(credits.amount) as credits
        FROM `{billing_account}.gcp_billing_export_v1_*`
        WHERE usage_start_time >= '{start_date}'
          AND usage_start_time < '{end_date}'
        GROUP BY project, service
        ORDER BY total_cost DESC
        """
        return self._execute_bq_query(query)
    
    def generate_report(self) -> dict:
        """Generate consolidated multi-cloud cost report."""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=30)
        
        date_format = "%Y-%m-%d"
        start_str = start_date.strftime(date_format)
        end_str = end_date.strftime(date_format)
        
        aws_costs = self.get_aws_costs(start_str, end_str)
        azure_costs = self.get_azure_costs(
            "subscription-id", start_str, end_str
        )
        gcp_costs = self.get_gcp_costs(
            "billing-account", start_str, end_str
        )
        
        return {
            "period": {"start": start_str, "end": end_str},
            "costs": {
                "aws": aws_costs,
                "azure": azure_costs,
                "gcp": gcp_costs
            },
            "total": sum([
                aws_costs.get("total", 0),
                azure_costs.get("total", 0),
                gcp_costs.get("total", 0)
            ])
        }

if __name__ == "__main__":
    reporter = MultiCloudCostReport()
    report = reporter.generate_report()
    print(json.dumps(report, indent=2))
```

## Observability

### Unified Monitoring Stack

```yaml
# Prometheus federation configuration
# prometheus/federation-config.yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  # AWS CloudWatch Exporter
  - job_name: 'aws-cloudwatch'
    static_configs:
      - targets: ['cloudwatch-exporter:9106']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'aws_.*'
        target_label: cloud
        replacement: 'aws'

  # Azure Monitor Exporter
  - job_name: 'azure-monitor'
    static_configs:
      - targets: ['azure-exporter:9276']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'azure_.*'
        target_label: cloud
        replacement: 'azure'

  # GCP Stackdriver Exporter
  - job_name: 'gcp-stackdriver'
    static_configs:
      - targets: ['stackdriver-exporter:9255']
    metric_relabel_configs:
      - source_labels: [__name__]
        regex: 'stackdriver_.*'
        target_label: cloud
        replacement: 'gcp'

  # Federate from cloud-specific Prometheus instances
  - job_name: 'federation-aws'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets: ['prometheus-aws.monitoring.svc:9090']

  - job_name: 'federation-azure'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets: ['prometheus-azure.monitoring.svc:9090']

  - job_name: 'federation-gcp'
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~".+"}'
    static_configs:
      - targets: ['prometheus-gcp.monitoring.svc:9090']
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Usage](usage.md) - Deployment examples, CI/CD, and troubleshooting

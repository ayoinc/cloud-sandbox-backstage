# Azure Kubernetes (AKS)

## AKS Module

Creates Azure Kubernetes Service cluster with managed node groups, Azure AD integration, and monitoring.

### Usage

```hcl
module "aks" {
  source = "path/to/azure/resources/kubernetes/aks"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"

  kubernetes_version = "1.28"
  sku_tier           = "Standard"

  default_node_pool = {
    name                 = "system"
    vm_size              = "Standard_D2s_v3"
    enable_auto_scaling  = true
    min_count            = 2
    max_count            = 5
    zones                = ["1", "2", "3"]
    only_critical_addons = true
  }

  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 10
      mode                = "User"
      node_labels = {
        workload = "general"
      }
    }
    spot = {
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 20
      priority            = "Spot"
      spot_max_price      = -1
      node_taints         = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
    }
  }

  # Azure AD Integration
  azure_ad_managed          = true
  azure_rbac_enabled        = true
  azure_ad_admin_group_ids  = ["00000000-0000-0000-0000-000000000000"]

  # Monitoring
  enable_oms_agent           = true
  log_analytics_workspace_id = module.monitoring.workspace_id

  # ACR Integration
  acr_id = module.acr.acr_id

  tags = module.tags.azure_tags
}
```

### Variables

| Variable                  | Type        | Default    | Description                |
| ------------------------- | ----------- | ---------- | -------------------------- |
| `kubernetes_version`      | string      | null       | K8s version (auto if null) |
| `sku_tier`                | string      | "Standard" | Free, Standard, Premium    |
| `private_cluster_enabled` | bool        | false      | Private cluster            |
| `default_node_pool`       | object      | {}         | Default node pool config   |
| `additional_node_pools`   | map(object) | {}         | Additional node pools      |
| `azure_ad_managed`        | bool        | true       | Azure AD integration       |
| `azure_rbac_enabled`      | bool        | true       | Azure RBAC for K8s         |
| `enable_oms_agent`        | bool        | true       | Container Insights         |

### Outputs

| Output             | Description                       |
| ------------------ | --------------------------------- |
| `cluster_id`       | AKS cluster ID                    |
| `cluster_name`     | AKS cluster name                  |
| `kube_config`      | Kubeconfig (sensitive)            |
| `oidc_issuer_url`  | OIDC issuer for workload identity |
| `kubelet_identity` | Kubelet managed identity          |

## Container Registry Module

```hcl
module "acr" {
  source = "path/to/azure/resources/containers/container-registry"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"

  sku           = "Premium"
  admin_enabled = false

  georeplications = [
    { location = "westus2", zone_redundancy_enabled = true }
  ]

  retention_policy_days  = 30
  trust_policy_enabled   = true

  tags = module.tags.azure_tags
}
```

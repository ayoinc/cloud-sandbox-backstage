# Plans the stack against mocked providers, so the tests need no Azure account and no cluster.
# Values not set in a run come from terraform.tfvars.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "22222222-2222-2222-2222-222222222222"
    }
  }
}

mock_provider "kubernetes" {}

mock_provider "helm" {}

run "configured_values" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size == local.node_vm_sizes[var.node_size]
    error_message = "The nodes use the VM size that belongs to node_size."
  }

  assert {
    condition = (
      azurerm_kubernetes_cluster.main.default_node_pool[0].enable_auto_scaling
      && azurerm_kubernetes_cluster.main.default_node_pool[0].min_count == var.node_min_count
      && azurerm_kubernetes_cluster.main.default_node_pool[0].max_count == max(var.node_min_count, var.node_max_count)
    )
    error_message = "The node pool scales between node_min_count and node_max_count."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.kubernetes_version == var.kubernetes_version
    error_message = "The cluster runs the Kubernetes version of kubernetes_version."
  }

  assert {
    condition     = local.cloud.network_policy_enforced == var.enable_network_policies
    error_message = "The platform components are told whether the cluster enforces network policies."
  }

  assert {
    condition     = length(module.external_dns_identity) == (var.enable_external_dns ? 1 : 0)
    error_message = "The identity of external-dns exists exactly when enable_external_dns is true."
  }

  assert {
    condition     = length(azurerm_network_security_rule.ingress_web) == (var.ingress_controller == "none" ? 0 : 1)
    error_message = "Web traffic from the internet is allowed exactly when an ingress controller is installed."
  }
}

run "small_nodes" {
  command = plan

  variables {
    node_size      = "small"
    node_min_count = 1
    node_max_count = 3
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size == "Standard_D2ls_v5"
    error_message = "small nodes are Standard_D2ls_v5 (2 vCPU, 4 GiB)."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].min_count == 1 && azurerm_kubernetes_cluster.main.default_node_pool[0].max_count == 3
    error_message = "The node pool scales between 1 and 3 nodes."
  }
}

run "medium_nodes" {
  command = plan

  variables {
    node_size = "medium"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size == "Standard_D4s_v5"
    error_message = "medium nodes are Standard_D4s_v5 (4 vCPU, 16 GiB)."
  }
}

run "large_nodes" {
  command = plan

  variables {
    node_size = "large"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].vm_size == "Standard_D8s_v5"
    error_message = "large nodes are Standard_D8s_v5 (8 vCPU, 32 GiB)."
  }
}

run "kubernetes_versions" {
  command = plan

  variables {
    kubernetes_version = "1.37"
  }

  assert {
    condition = (
      azurerm_kubernetes_cluster.main.kubernetes_version == "1.37"
      && azurerm_kubernetes_cluster.main.default_node_pool[0].orchestrator_version == "1.37"
    )
    error_message = "Control plane and nodes run the chosen Kubernetes version."
  }
}

run "ingress_nginx" {
  command = plan

  variables {
    ingress_controller = "nginx"
  }

  assert {
    condition     = length(azurerm_network_security_rule.ingress_web) == 1
    error_message = "Ports 80 and 443 are open to the internet for the ingress controller."
  }

  assert {
    condition     = local.cloud.ingress_service_annotations["service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"] == "/healthz"
    error_message = "The load balancer probes ingress-nginx on /healthz."
  }
}

run "ingress_traefik" {
  command = plan

  variables {
    ingress_controller = "traefik"
  }

  assert {
    condition     = length(azurerm_network_security_rule.ingress_web) == 1
    error_message = "Ports 80 and 443 are open to the internet for the ingress controller."
  }

  assert {
    condition     = length(local.cloud.ingress_service_annotations) == 0
    error_message = "Traefik needs no load balancer annotations."
  }
}

run "no_ingress_controller" {
  command = plan

  variables {
    ingress_controller = "none"
  }

  assert {
    condition     = length(azurerm_network_security_rule.ingress_web) == 0
    error_message = "Without an ingress controller the subnet accepts no traffic from the internet."
  }
}

run "all_components" {
  command = plan

  variables {
    enable_gitops                 = true
    enable_observability          = true
    enable_service_mesh           = true
    enable_cert_manager           = true
    enable_external_dns           = true
    ingress_controller            = "nginx"
    enable_pod_security_standards = true
    enable_network_policies       = true
    enable_opa                    = true
    enable_vault_integration      = true
  }

  assert {
    condition = (
      azurerm_kubernetes_cluster.main.network_profile[0].network_policy == "cilium"
      && azurerm_kubernetes_cluster.main.network_profile[0].network_data_plane == "cilium"
      && local.cloud.network_policy_enforced
    )
    error_message = "enable_network_policies turns on the Cilium data plane and its network policy engine."
  }

  assert {
    condition     = length(module.external_dns_identity) == 1
    error_message = "enable_external_dns creates the managed identity of external-dns."
  }

  assert {
    condition     = local.cloud.external_dns.provider == "azure" && length(local.cloud.external_dns.service_account_annotations) == 1
    error_message = "The external-dns service account is annotated with the client ID of its managed identity."
  }
}

run "no_components" {
  command = plan

  variables {
    enable_gitops                 = false
    enable_observability          = false
    enable_service_mesh           = false
    enable_cert_manager           = false
    enable_external_dns           = false
    ingress_controller            = "none"
    enable_pod_security_standards = false
    enable_network_policies       = false
    enable_opa                    = false
    enable_vault_integration      = false
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.network_profile[0].network_data_plane == "azure" && !local.cloud.network_policy_enforced
    error_message = "Without enable_network_policies the cluster runs no network policy engine."
  }

  assert {
    condition     = length(module.external_dns_identity) == 0 && length(local.cloud.external_dns.service_account_annotations) == 0
    error_message = "No identity for external-dns is created when it is disabled."
  }
}

run "production" {
  command = plan

  variables {
    environment     = "production"
    project_name    = "sixteen-chars-ab"
    location        = "southeastasia"
    subscription_id = "33333333-3333-3333-3333-333333333333"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.sku_tier == "Standard"
    error_message = "Production clusters use the Standard tier with the uptime SLA."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.name == "aks-sixteen-chars-ab-prod-southeastasia" && length(azurerm_kubernetes_cluster.main.name) <= 63
    error_message = "The cluster is named aks-<project>-prod-<location> and fits the 63 characters AKS allows."
  }

  assert {
    condition     = module.resource_group.name == "rg-sixteen-chars-ab-prod-southeastasia" && length(azurerm_kubernetes_cluster.main.node_resource_group) <= 80
    error_message = "The resource group is named rg-<project>-prod-<location> and the node resource group fits 80 characters."
  }
}

run "development" {
  command = plan

  variables {
    environment             = "dev"
    subscription_id         = null
    dns_zone_resource_group = "rg-shared-dns"
    enable_external_dns     = true
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.sku_tier == "Free"
    error_message = "Clusters outside production use the Free tier."
  }

  assert {
    condition     = local.dns_zone_scope == "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-shared-dns"
    error_message = "external-dns is granted access to the resource group in dns_zone_resource_group."
  }
}

run "maximum_below_minimum_nodes" {
  command = plan

  variables {
    node_min_count = 5
    node_max_count = 3
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.default_node_pool[0].min_count == 5 && azurerm_kubernetes_cluster.main.default_node_pool[0].max_count == 5
    error_message = "A node_max_count below node_min_count counts as node_min_count."
  }
}

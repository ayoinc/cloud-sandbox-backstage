data "azurerm_client_config" "current" {}

locals {
  dns_zone_resource_group = coalesce(var.dns_zone_resource_group, module.resource_group.name)

  dns_zone_scope = (
    var.dns_zone_resource_group == null
    ? module.resource_group.id
    : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.dns_zone_resource_group}"
  )
}

# Identity of the cluster's control plane. It manages load balancers and node network interfaces in the subnet of
# this stack, for which it needs Network Contributor on the virtual network.
module "cluster_identity" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/managed-identity?ref=${{ values.moduleRef }}"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  identity_name       = "id-${local.cluster_name}"

  role_assignments = [
    {
      scope                = module.network.vnet_id
      role_definition_name = "Network Contributor"
    },
  ]

  tags = local.common_tags
}

# Identity external-dns signs in with. The federated credential lets the Kubernetes service account external-dns
# in namespace external-dns exchange its token for this identity, which may change the records of the DNS zones
# in local.dns_zone_resource_group.
module "external_dns_identity" {
  count = var.enable_external_dns ? 1 : 0

  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/azure/resources/core/managed-identity?ref=${{ values.moduleRef }}"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  identity_name       = "id-${local.cluster_name}-external-dns"

  role_assignments = [
    {
      scope                = local.dns_zone_scope
      role_definition_name = "DNS Zone Contributor"
    },
  ]

  federated_identity_credentials = [
    {
      name      = "external-dns"
      issuer    = azurerm_kubernetes_cluster.main.oidc_issuer_url
      subject   = "system:serviceaccount:external-dns:external-dns"
      audiences = ["api://AzureADTokenExchange"]
    },
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Network security groups
# -----------------------------------------------------------------------------
#
# With enable_security_group_rules every tier gets a security group that ends
# in a deny-all rule: clients reach the web tier over HTTPS, the web tier
# reaches the app tier on the app ports, and only the app tier (which hosts
# the cluster nodes) reaches the data tier. Without it only the data subnet
# is restricted, to traffic from inside the virtual network.
#
# Traffic that a public load balancer of the cluster forwards keeps the
# address of the client, so the app tier rejects it: publish workloads
# through the web tier or Front Door.
#
# Security groups are attached to created subnets only. The subnets of an
# existing network keep the rules of their owner.

locals {
  # HTTPS (Key Vault, storage, Cosmos DB), MySQL, PostgreSQL, Azure Managed
  # Redis and Cosmos DB for MongoDB.
  data_tier_ports = ["443", "3306", "5432", "10000", "10255"]

  deny_all_inbound = {
    priority = 4096
    access   = "Deny"
    protocol = "*"
    sources  = ["*"]
    ports    = ["*"]
  }

  allow_load_balancer_probes = {
    priority = 200
    access   = "Allow"
    protocol = "*"
    sources  = ["AzureLoadBalancer"]
    ports    = ["*"]
  }

  web_tier_rules = merge(
    length(var.allowed_ingress_cidrs) == 0 ? {} : {
      allow-https-from-clients = {
        priority = 100
        access   = "Allow"
        protocol = "Tcp"
        sources  = var.allowed_ingress_cidrs
        ports    = ["443"]
      }
    },
    {
      allow-load-balancer-probes = local.allow_load_balancer_probes
      deny-all-inbound           = local.deny_all_inbound
    },
  )

  app_tier_rules = {
    allow-web-tier = {
      priority = 100
      access   = "Allow"
      protocol = "Tcp"
      sources  = local.public_subnet_cidrs
      ports    = [for port in var.app_tier_ports : tostring(port)]
    }
    allow-app-tier = {
      priority = 110
      access   = "Allow"
      protocol = "*"
      sources  = local.private_subnet_cidrs
      ports    = ["*"]
    }
    allow-load-balancer-probes = local.allow_load_balancer_probes
    deny-all-inbound           = local.deny_all_inbound
  }

  data_tier_rules = {
    allow-clients = {
      priority = 100
      access   = "Allow"
      protocol = "Tcp"
      sources  = var.enable_security_group_rules ? local.private_subnet_cidrs : [var.network_cidr]
      ports    = var.enable_security_group_rules ? local.data_tier_ports : ["*"]
    }
    deny-all-inbound = local.deny_all_inbound
  }

  security_tiers = !var.enable_networking ? {} : merge(
    { data = local.data_tier_rules },
    var.enable_security_group_rules ? { web = local.web_tier_rules, app = local.app_tier_rules } : {},
  )

  security_rules = merge([
    for tier, rules in local.security_tiers : {
      for name, rule in rules : "${tier}-${name}" => merge(rule, { tier = tier, name = name })
    }
  ]...)
}

resource "azurerm_network_security_group" "tier" {
  for_each = local.security_tiers

  name                = "${var.name_prefix}-${each.key}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "tier" {
  for_each = local.security_rules

  name                        = each.value.name
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.tier[each.value.tier].name
  priority                    = each.value.priority
  direction                   = "Inbound"
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_address_prefix  = "*"

  # Azure takes one value and a list of values in separate arguments.
  source_address_prefix   = length(each.value.sources) == 1 ? each.value.sources[0] : null
  source_address_prefixes = length(each.value.sources) == 1 ? null : each.value.sources
  destination_port_range  = length(each.value.ports) == 1 ? each.value.ports[0] : null
  destination_port_ranges = length(each.value.ports) == 1 ? null : each.value.ports
}

resource "azurerm_subnet_network_security_group_association" "public" {
  count = var.enable_networking && var.enable_security_group_rules ? 2 : 0

  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.tier["web"].id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = var.enable_networking && var.enable_security_group_rules ? 2 : 0

  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.tier["app"].id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  count = var.enable_networking ? 1 : 0

  subnet_id                 = azurerm_subnet.data[0].id
  network_security_group_id = azurerm_network_security_group.tier["data"].id
}

# -----------------------------------------------------------------------------
# Deletion protection
# -----------------------------------------------------------------------------

locals {
  deletion_lock_candidates = {
    database   = local.database_resource_id
    kubernetes = one(azurerm_kubernetes_cluster.this[*].id)
    key-vault  = one(azurerm_key_vault.this[*].id)
    backup     = one(azurerm_data_protection_backup_vault.this[*].id)
  }

  deletion_locks = {
    for name, enabled in {
      database   = var.enable_database
      kubernetes = var.enable_kubernetes
      key-vault  = local.key_vault_enabled
      backup     = var.enable_backup
    } : name => local.deletion_lock_candidates[name] if enabled && var.require_deletion_protection
  }
}

# A locked resource cannot be deleted, by Terraform or anyone else, until the
# lock is removed: set require_deletion_protection to false and apply first.
resource "azurerm_management_lock" "this" {
  for_each = local.deletion_locks

  name       = "${var.name_prefix}-${each.key}-delete-lock"
  scope      = each.value
  lock_level = "CanNotDelete"
  notes      = "Deletion protection required for the ${var.environment} environment."
}

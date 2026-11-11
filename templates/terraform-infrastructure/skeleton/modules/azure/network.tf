locals {
  # The address space is cut into 16 equal blocks: 0-1 public (web tier),
  # 8-9 private (app tier and cluster nodes), 15 data (private endpoints).
  public_subnet_cidrs  = [for i in range(2) : cidrsubnet(var.network_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(2) : cidrsubnet(var.network_cidr, 4, i + 8)]
  data_subnet_cidr     = cidrsubnet(var.network_cidr, 4, 15)

  # A NAT gateway serves one zone. Production, and any environment that is
  # not cost-optimised, gets one per private subnet in separate zones.
  nat_gateway_count = !var.enable_networking ? 0 : (local.production || !var.enable_cost_optimization ? 2 : 1)
  nat_gateway_zones = [
    for i in range(local.nat_gateway_count) :
    local.nat_gateway_count > 1 && local.zonal ? [var.availability_zones[i % length(var.availability_zones)]] : null
  ]

  # The network every component attaches to: the created one or the one
  # passed in. All three are empty when there is neither.
  network_available  = var.enable_networking || var.existing_network != null
  network_id         = var.enable_networking ? azurerm_virtual_network.this[0].id : try(var.existing_network.network_id, null)
  public_subnet_ids  = var.enable_networking ? azurerm_subnet.public[*].id : try(var.existing_network.public_subnet_ids, [])
  private_subnet_ids = var.enable_networking ? azurerm_subnet.private[*].id : try(var.existing_network.private_subnet_ids, [])

  # Private endpoints go to the data subnet, or to the first private subnet
  # of an existing network.
  endpoint_subnet_id = var.enable_networking ? azurerm_subnet.data[0].id : try(var.existing_network.private_subnet_ids[0], null)

  network_requirement = "needs a virtual network: set enable_networking to true or pass existing_network."
}

# -----------------------------------------------------------------------------
# Virtual network and subnets
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  count = var.enable_networking ? 1 : 0

  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.network_cidr]

  tags = local.tags
}

resource "azurerm_subnet" "public" {
  count = var.enable_networking ? 2 : 0

  name                 = "${var.name_prefix}-public-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [local.public_subnet_cidrs[count.index]]
}

# Private subnets reach the internet through the NAT gateway only.
resource "azurerm_subnet" "private" {
  count = var.enable_networking ? 2 : 0

  name                            = "${var.name_prefix}-private-${count.index + 1}"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.this[0].name
  address_prefixes                = [local.private_subnet_cidrs[count.index]]
  default_outbound_access_enabled = false
}

# The data subnet holds the private endpoints of the data stores. Network
# security group rules apply to them and it has no route to the internet.
resource "azurerm_subnet" "data" {
  count = var.enable_networking ? 1 : 0

  name                              = "${var.name_prefix}-data"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this[0].name
  address_prefixes                  = [local.data_subnet_cidr]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}

# -----------------------------------------------------------------------------
# NAT gateways
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "nat" {
  count = local.nat_gateway_count

  name                = "${var.name_prefix}-nat-ip-${count.index + 1}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = local.nat_gateway_zones[count.index]

  tags = local.tags
}

resource "azurerm_nat_gateway" "this" {
  count = local.nat_gateway_count

  name                = "${var.name_prefix}-nat-${count.index + 1}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
  zones               = local.nat_gateway_zones[count.index]

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = local.nat_gateway_count

  nat_gateway_id       = azurerm_nat_gateway.this[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.enable_networking ? 2 : 0

  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.this[count.index % local.nat_gateway_count].id
}

# -----------------------------------------------------------------------------
# Private DNS zone of the network foundation
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "internal" {
  count = local.dns_zone_enabled ? 1 : 0

  name                = "${var.name_prefix}.internal"
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = "The private DNS zone of a networking-foundation stack ${local.network_requirement}"
    }
  }
}

# Virtual machines in the network register their names in the zone.
resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  count = local.dns_zone_enabled && local.network_available ? 1 : 0

  name                  = "${var.name_prefix}-internal"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.internal[0].name
  virtual_network_id    = local.network_id
  registration_enabled  = true

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Flow logs
# -----------------------------------------------------------------------------

locals {
  flow_logs_enabled = var.require_flow_logs && local.network_available

  network_watcher = var.network_watcher != null ? var.network_watcher : {
    name                = "NetworkWatcher_${lower(replace(var.region, " ", ""))}"
    resource_group_name = "NetworkWatcherRG"
  }
}

resource "azurerm_network_watcher_flow_log" "this" {
  count = local.flow_logs_enabled ? 1 : 0

  name                 = "${var.name_prefix}-flow-log"
  network_watcher_name = local.network_watcher.name
  resource_group_name  = local.network_watcher.resource_group_name
  location             = azurerm_resource_group.this.location

  target_resource_id = local.network_id
  storage_account_id = azurerm_storage_account.logs[0].id
  enabled            = true

  # The lifecycle rule of the log storage account removes the records after
  # log_retention_days, without the 365-day limit of this setting.
  retention_policy {
    enabled = false
    days    = 0
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.this[0].workspace_id
    workspace_region      = azurerm_log_analytics_workspace.this[0].location
    workspace_resource_id = azurerm_log_analytics_workspace.this[0].id
    interval_in_minutes   = 10
  }

  tags = local.tags
}

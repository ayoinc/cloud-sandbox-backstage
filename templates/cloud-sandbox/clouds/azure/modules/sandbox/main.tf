locals {
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.name
  })

  # AKS nodes run in a private subnet.
  private_subnet_count = var.include_eks ? max(var.private_subnets, 1) : var.private_subnets

  # The address space is cut into 16 equal blocks: 0-3 public, 8-11 private,
  # 15 for the database.
  public_subnet_cidrs  = [for i in range(var.public_subnets) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(local.private_subnet_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
  database_subnet_cidr = cidrsubnet(var.vpc_cidr, 4, 15)

  # Database names cannot contain hyphens.
  database_name = "db_${replace(var.name, "-", "_")}"
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "${var.name}-rg"
  location = var.region

  tags = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vpc_cidr]

  tags = local.tags
}

resource "azurerm_subnet" "public" {
  count = var.public_subnets

  name                 = "${var.name}-public-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.public_subnet_cidrs[count.index]]
}

resource "azurerm_subnet" "private" {
  count = local.private_subnet_count

  name                 = "${var.name}-private-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.private_subnet_cidrs[count.index]]
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.name}-public-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_network_security_rule" "bastion_ssh" {
  count = var.include_bastion && length(var.bastion_allowed_cidrs) > 0 ? 1 : 0

  name                        = "allow-ssh-to-bastion"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.public.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.bastion_allowed_cidrs
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "public" {
  count = var.public_subnets

  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Private subnets accept traffic from inside the virtual network only, which
# is what the default rules of an empty security group allow.
resource "azurerm_network_security_group" "private" {
  count = local.private_subnet_count > 0 ? 1 : 0

  name                = "${var.name}-private-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "private" {
  count = local.private_subnet_count

  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private[0].id
}

# One NAT gateway gives all private subnets outbound internet access.
resource "azurerm_public_ip" "nat" {
  count = local.private_subnet_count > 0 ? 1 : 0

  name                = "${var.name}-nat-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_nat_gateway" "this" {
  count = local.private_subnet_count > 0 ? 1 : 0

  name                = "${var.name}-nat"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"

  tags = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = local.private_subnet_count > 0 ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count = local.private_subnet_count

  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

# -----------------------------------------------------------------------------
# Bastion host (optional)
# -----------------------------------------------------------------------------

# The key pair lives in the Terraform state; read the private key with
# `terraform output -raw bastion_ssh_private_key`.
resource "tls_private_key" "bastion" {
  count = var.include_bastion ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "bastion" {
  count = var.include_bastion ? 1 : 0

  name                = "${var.name}-bastion-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_network_interface" "bastion" {
  count = var.include_bastion ? 1 : 0

  name                = "${var.name}-bastion-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.public[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion[0].id
  }

  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "bastion" {
  count = var.include_bastion ? 1 : 0

  name                = "${var.name}-bastion"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  size                = "Standard_B2ats_v2"

  network_interface_ids = [azurerm_network_interface.bastion[0].id]

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.bastion[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = merge(local.tags, {
    Role = "bastion"
  })
}

# -----------------------------------------------------------------------------
# AKS cluster (optional)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "aks" {
  count = var.include_eks ? 1 : 0

  name                = "${var.name}-aks-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  count = var.include_eks ? 1 : 0

  name                = var.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.name
  kubernetes_version  = var.kubernetes_version

  # Without an allow list the API server is reachable from the virtual
  # network only.
  private_cluster_enabled = length(var.kubernetes_api_allowed_cidrs) == 0

  role_based_access_control_enabled = true

  default_node_pool {
    name           = "system"
    vm_size        = "Standard_D2s_v5"
    node_count     = 2
    vnet_subnet_id = azurerm_subnet.private[0].id
  }

  identity {
    type = "SystemAssigned"
  }

  # The service range must not overlap the virtual network.
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "172.30.0.0/16"
    dns_service_ip = "172.30.0.10"
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.kubernetes_api_allowed_cidrs) > 0 ? [1] : []

    content {
      authorized_ip_ranges = var.kubernetes_api_allowed_cidrs
    }
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks[0].id
  }

  tags = local.tags

  # Nodes need outbound access through the NAT gateway while they join.
  depends_on = [
    azurerm_subnet_nat_gateway_association.private,
    azurerm_nat_gateway_public_ip_association.this,
  ]
}

# -----------------------------------------------------------------------------
# PostgreSQL flexible server (optional)
# -----------------------------------------------------------------------------

resource "azurerm_subnet" "database" {
  count = var.include_rds ? 1 : 0

  name                 = "${var.name}-database"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.database_subnet_cidr]

  delegation {
    name = "postgresql"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "postgresql" {
  count = var.include_rds ? 1 : 0

  name                = "${var.name}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.this.name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count = var.include_rds ? 1 : 0

  name                  = "${var.name}-postgresql"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = local.tags
}

# The password lives in the Terraform state; read it with
# `terraform output -raw postgresql_admin_password`.
resource "random_password" "postgresql" {
  count = var.include_rds ? 1 : 0

  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "this" {
  count = var.include_rds ? 1 : 0

  name                = "${var.name}-postgresql"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  version    = "16"
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  administrator_login    = "sandbox_admin"
  administrator_password = random_password.postgresql[0].result

  # Reachable from the virtual network only.
  delegated_subnet_id           = azurerm_subnet.database[0].id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql[0].id
  public_network_access_enabled = false

  backup_retention_days = 7

  tags = local.tags

  # Azure picks the availability zone; it must not be reset on later applies.
  lifecycle {
    ignore_changes = [zone]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count = var.include_rds ? 1 : 0

  name      = local.database_name
  server_id = azurerm_postgresql_flexible_server.this[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

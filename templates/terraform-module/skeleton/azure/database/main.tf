# -----------------------------------------------------------------------------
# Azure Database Module - Main Resources
# PostgreSQL Flexible Server with Private Endpoint and Optional Redis Cache
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  postgresql_server_name = "${local.name_prefix}-psql"
  private_endpoint_name  = "${local.name_prefix}-psql-pe"
  redis_name             = "${local.name_prefix}-redis"

  # Private DNS zone name for PostgreSQL Flexible Server
  postgresql_private_dns_zone_name = "${var.project_name}${var.environment}.postgres.database.azure.com"
}

# -----------------------------------------------------------------------------
# Random Password for PostgreSQL Admin
# -----------------------------------------------------------------------------

resource "random_password" "postgresql_admin" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

# -----------------------------------------------------------------------------
# Store Password in Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "postgresql_admin_password" {
  name         = "${local.name_prefix}-psql-admin-password"
  value        = random_password.postgresql_admin.result
  key_vault_id = var.key_vault_id

  content_type = "PostgreSQL Admin Password"

  tags = merge(var.tags, {
    Purpose = "PostgreSQL Admin Password"
  })
}

resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  name         = "${local.name_prefix}-psql-connection-string"
  value        = "postgresql://${var.admin_username}:${random_password.postgresql_admin.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}?sslmode=require"
  key_vault_id = var.key_vault_id

  content_type = "PostgreSQL Connection String"

  tags = merge(var.tags, {
    Purpose = "PostgreSQL Connection String"
  })

  depends_on = [azurerm_postgresql_flexible_server.main]
}

# -----------------------------------------------------------------------------
# Private DNS Zone for PostgreSQL Flexible Server
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgresql" {
  name                = local.postgresql_private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${local.name_prefix}-psql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PostgreSQL Flexible Server
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "main" {
  name                = local.postgresql_server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Version and SKU
  version  = var.postgresql_version
  sku_name = var.sku_name

  # Storage configuration
  storage_mb        = var.storage_mb
  auto_grow_enabled = var.auto_grow_enabled

  # Admin credentials
  administrator_login    = var.admin_username
  administrator_password = random_password.postgresql_admin.result

  # Network configuration - use delegated subnet for VNet integration
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  # Backup configuration
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup

  # Availability zone
  zone = var.availability_zone

  # Authentication block
  authentication {
    active_directory_auth_enabled = var.enable_aad_auth
    password_auth_enabled         = var.enable_password_auth
    tenant_id                     = var.enable_aad_auth ? var.tenant_id : null
  }

  # High Availability (optional)
  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  # Maintenance window
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  tags = merge(var.tags, {
    Name = local.postgresql_server_name
  })

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
      administrator_password
    ]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgresql
  ]
}

# -----------------------------------------------------------------------------
# PostgreSQL Database
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = var.database_collation
  charset   = var.database_charset
}

# -----------------------------------------------------------------------------
# PostgreSQL Firewall Rules
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

# Allow Azure services (optional)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count = var.allow_azure_services ? 1 : 0

  name             = "AllowAllAzureServicesAndResourcesWithinAzureIps"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# -----------------------------------------------------------------------------
# PostgreSQL Server Configurations
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_configuration" "configs" {
  for_each = var.postgresql_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# -----------------------------------------------------------------------------
# Private Endpoint for PostgreSQL (for private connectivity)
# Note: When using delegated_subnet_id, private endpoint is not needed.
# This is provided for scenarios where you use public access with private endpoint
# -----------------------------------------------------------------------------

resource "azurerm_private_endpoint" "postgresql" {
  count = var.create_private_endpoint ? 1 : 0

  name                = local.private_endpoint_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${local.name_prefix}-psql-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.main.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "postgresql-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.postgresql.id]
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Azure Redis Cache (Optional)
# -----------------------------------------------------------------------------

resource "random_password" "redis" {
  count = var.enable_redis ? 1 : 0

  length      = 32
  special     = false
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
}

resource "azurerm_redis_cache" "main" {
  count = var.enable_redis ? 1 : 0

  name                = local.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  # Redis configuration
  redis_configuration {
    aof_backup_enabled              = var.redis_sku == "Premium" ? var.redis_aof_backup_enabled : null
    aof_storage_connection_string_0 = var.redis_sku == "Premium" && var.redis_aof_backup_enabled ? var.redis_aof_storage_connection_string : null
    enable_authentication           = true
    maxmemory_policy                = var.redis_maxmemory_policy
    maxfragmentationmemory_reserved = var.redis_sku == "Premium" || var.redis_sku == "Standard" ? var.redis_maxfragmentationmemory_reserved : null
    maxmemory_reserved              = var.redis_sku == "Premium" || var.redis_sku == "Standard" ? var.redis_maxmemory_reserved : null
  }

  # Private endpoint for Redis (Premium SKU only)
  public_network_access_enabled = var.redis_sku == "Premium" ? false : true

  # Patch schedule
  dynamic "patch_schedule" {
    for_each = var.redis_patch_schedule != null ? [var.redis_patch_schedule] : []
    content {
      day_of_week        = patch_schedule.value.day_of_week
      start_hour_utc     = patch_schedule.value.start_hour_utc
      maintenance_window = patch_schedule.value.maintenance_window
    }
  }

  tags = merge(var.tags, {
    Name = local.redis_name
  })
}

# Store Redis credentials in Key Vault
resource "azurerm_key_vault_secret" "redis_primary_key" {
  count = var.enable_redis ? 1 : 0

  name         = "${local.name_prefix}-redis-primary-key"
  value        = azurerm_redis_cache.main[0].primary_access_key
  key_vault_id = var.key_vault_id

  content_type = "Redis Primary Access Key"

  tags = merge(var.tags, {
    Purpose = "Redis Primary Access Key"
  })
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  count = var.enable_redis ? 1 : 0

  name         = "${local.name_prefix}-redis-connection-string"
  value        = azurerm_redis_cache.main[0].primary_connection_string
  key_vault_id = var.key_vault_id

  content_type = "Redis Connection String"

  tags = merge(var.tags, {
    Purpose = "Redis Connection String"
  })
}

# Private Endpoint for Redis (Premium SKU only)
resource "azurerm_private_endpoint" "redis" {
  count = var.enable_redis && var.redis_sku == "Premium" ? 1 : 0

  name                = "${local.name_prefix}-redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id != null ? var.private_endpoint_subnet_id : var.subnet_id

  private_service_connection {
    name                           = "${local.name_prefix}-redis-psc"
    private_connection_resource_id = azurerm_redis_cache.main[0].id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.redis_private_dns_zone_id != null ? [1] : []
    content {
      name                 = "redis-dns-group"
      private_dns_zone_ids = [var.redis_private_dns_zone_id]
    }
  }

  tags = var.tags
}

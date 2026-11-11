# -----------------------------------------------------------------------------
# Azure Database Module - Main Resources
# PostgreSQL Flexible Server with VNet integration and optional Azure Managed Redis
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "random_id" "database" {
  byte_length = 4
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Server and cache names are global DNS labels of at most 63 characters.
  short_prefix           = trimsuffix(substr(local.name_prefix, 0, 46), "-")
  postgresql_server_name = "${local.short_prefix}-psql-${random_id.database.hex}"
  redis_name             = "${local.short_prefix}-redis-${random_id.database.hex}"

  # The zone must end in postgres.database.azure.com and differ from the server name.
  postgresql_private_dns_zone_name = "${local.name_prefix}.private.postgres.database.azure.com"

  # The virtual network that owns the delegated subnet.
  vnet_id = var.vnet_id != null ? var.vnet_id : regex("^(.+)/subnets/[^/]+$", var.subnet_id)[0]

  tenant_id = var.tenant_id != null ? var.tenant_id : data.azurerm_client_config.current.tenant_id

  store_redis_key = var.enable_redis && var.redis_access_keys_enabled && var.store_credentials_in_key_vault
}

# -----------------------------------------------------------------------------
# PostgreSQL administrator password
# -----------------------------------------------------------------------------

resource "random_password" "postgresql_admin" {
  length           = 32
  special          = true
  override_special = "!#*()-_=+[]<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
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
  virtual_network_id    = local.vnet_id
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

  version  = var.postgresql_version
  sku_name = var.sku_name

  storage_mb        = var.storage_mb
  auto_grow_enabled = var.auto_grow_enabled

  administrator_login    = var.enable_password_auth ? var.admin_username : null
  administrator_password = var.enable_password_auth ? random_password.postgresql_admin.result : null

  # The server lives in the delegated subnet and has no public endpoint.
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup

  zone = var.availability_zone

  authentication {
    active_directory_auth_enabled = var.enable_aad_auth
    password_auth_enabled         = var.enable_password_auth
    tenant_id                     = var.enable_aad_auth ? local.tenant_id : null
  }

  dynamic "high_availability" {
    for_each = var.enable_high_availability ? [1] : []

    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-psql"
  })

  lifecycle {
    # Azure swaps the primary and standby zones after a failover.
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone,
    ]

    precondition {
      condition     = var.enable_password_auth || var.enable_aad_auth
      error_message = "At least one of enable_password_auth and enable_aad_auth must be true."
    }
    precondition {
      condition     = !var.enable_high_availability || !startswith(var.sku_name, "B_")
      error_message = "High availability is not available on Burstable SKUs: use a GP_ or MO_ sku_name."
    }
    precondition {
      condition     = !var.enable_aad_auth || var.aad_administrator != null
      error_message = "aad_administrator is required when enable_aad_auth is true."
    }
  }

  # The server resolves its own name through the linked zone while provisioning.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "main" {
  count = var.enable_aad_auth ? 1 : 0

  server_name         = azurerm_postgresql_flexible_server.main.name
  resource_group_name = var.resource_group_name
  tenant_id           = local.tenant_id
  object_id           = var.aad_administrator.object_id
  principal_name      = var.aad_administrator.principal_name
  principal_type      = var.aad_administrator.principal_type
}

# -----------------------------------------------------------------------------
# PostgreSQL Database and Server Parameters
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = var.database_collation
  charset   = var.database_charset
}

resource "azurerm_postgresql_flexible_server_configuration" "configs" {
  for_each = var.postgresql_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = each.value
}

# -----------------------------------------------------------------------------
# Credentials in Key Vault (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "postgresql_admin_password" {
  count = var.store_credentials_in_key_vault && var.enable_password_auth ? 1 : 0

  name            = "${local.name_prefix}-psql-admin-password"
  value           = random_password.postgresql_admin.result
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.secret_expiration_date

  tags = merge(var.tags, {
    Purpose = "PostgreSQL administrator password"
  })

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "key_vault_id is required when store_credentials_in_key_vault is true."
    }
  }
}

resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  count = var.store_credentials_in_key_vault && var.enable_password_auth ? 1 : 0

  name            = "${local.name_prefix}-psql-connection-string"
  value           = "postgresql://${var.admin_username}:${urlencode(random_password.postgresql_admin.result)}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${var.database_name}?sslmode=require"
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.secret_expiration_date

  tags = merge(var.tags, {
    Purpose = "PostgreSQL connection string"
  })

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "key_vault_id is required when store_credentials_in_key_vault is true."
    }
  }
}

# -----------------------------------------------------------------------------
# Azure Managed Redis (Optional)
# -----------------------------------------------------------------------------

resource "azurerm_managed_redis" "main" {
  count = var.enable_redis ? 1 : 0

  name                = local.redis_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.redis_sku

  high_availability_enabled = var.redis_high_availability_enabled
  public_network_access     = "Disabled"

  default_database {
    # Clients authenticate with Microsoft Entra ID unless access keys are enabled.
    access_keys_authentication_enabled = var.redis_access_keys_enabled
    client_protocol                    = "Encrypted"
    clustering_policy                  = var.redis_clustering_policy
    eviction_policy                    = var.redis_eviction_policy
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-redis"
  })
}

resource "azurerm_private_dns_zone" "redis" {
  count = var.enable_redis && var.create_redis_private_dns_zone ? 1 : 0

  name                = "privatelink.redis.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count = var.enable_redis && var.create_redis_private_dns_zone ? 1 : 0

  name                  = "${local.name_prefix}-redis-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = local.vnet_id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false

  tags = var.tags
}

# The cache is reachable only through this endpoint. It cannot share the
# PostgreSQL subnet, because delegated subnets do not accept private endpoints.
resource "azurerm_private_endpoint" "redis" {
  count = var.enable_redis ? 1 : 0

  name                = "${local.name_prefix}-redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${local.name_prefix}-redis-psc"
    private_connection_resource_id = azurerm_managed_redis.main[0].id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-dns-group"
    private_dns_zone_ids = [var.create_redis_private_dns_zone ? azurerm_private_dns_zone.redis[0].id : var.redis_private_dns_zone_id]
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.private_endpoint_subnet_id != null
      error_message = "private_endpoint_subnet_id is required when enable_redis is true (a subnet without delegation, for example the private subnet)."
    }
    precondition {
      condition     = var.create_redis_private_dns_zone || var.redis_private_dns_zone_id != null
      error_message = "redis_private_dns_zone_id is required when create_redis_private_dns_zone is false."
    }
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.redis]
}

resource "azurerm_key_vault_secret" "redis_primary_key" {
  count = local.store_redis_key ? 1 : 0

  name            = "${local.name_prefix}-redis-primary-key"
  value           = azurerm_managed_redis.main[0].default_database[0].primary_access_key
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.secret_expiration_date

  tags = merge(var.tags, {
    Purpose = "Redis primary access key"
  })

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "key_vault_id is required when store_credentials_in_key_vault is true."
    }
  }
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  count = local.store_redis_key ? 1 : 0

  name            = "${local.name_prefix}-redis-connection-string"
  value           = "rediss://:${urlencode(azurerm_managed_redis.main[0].default_database[0].primary_access_key)}@${azurerm_managed_redis.main[0].hostname}:${azurerm_managed_redis.main[0].default_database[0].port}"
  key_vault_id    = var.key_vault_id
  content_type    = "text/plain"
  expiration_date = var.secret_expiration_date

  tags = merge(var.tags, {
    Purpose = "Redis connection string"
  })

  lifecycle {
    precondition {
      condition     = var.key_vault_id != null
      error_message = "key_vault_id is required when store_credentials_in_key_vault is true."
    }
  }
}

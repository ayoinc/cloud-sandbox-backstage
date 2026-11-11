locals {
  postgresql_enabled = var.enable_database && var.database_type == "postgresql"
  mysql_enabled      = var.enable_database && var.database_type == "mysql"
  cosmos_enabled     = var.enable_database && contains(["mongodb", "cosmosdb"], var.database_type)
  mongodb_enabled    = var.enable_database && var.database_type == "mongodb"
  redis_enabled      = var.enable_database && var.database_type == "redis"

  database_admin_username = "dbadmin"
  database_name           = replace(var.name_prefix, "-", "_")
  database_backup_days    = var.enable_backup ? 35 : 7

  # Production runs a standby in a second zone where the region has zones.
  database_ha_mode = local.zonal ? "ZoneRedundant" : "SameZone"

  # Serverless Cosmos DB bills per request, but is limited to one region.
  cosmos_serverless = local.economy && !var.enable_disaster_recovery
  cosmos_name       = "${var.name_prefix}-cosmos-${local.suffix}"
  cosmos_locations = concat(
    [{ location = var.region, priority = 0, zone_redundant = local.production && local.zonal }],
    var.enable_disaster_recovery ? [{ location = var.secondary_region, priority = 1, zone_redundant = false }] : [],
  )

  database_resource_id = one(concat(
    azurerm_postgresql_flexible_server.this[*].id,
    azurerm_mysql_flexible_server.this[*].id,
    azurerm_cosmosdb_account.this[*].id,
    azurerm_managed_redis.this[*].id,
  ))

  database_endpoints = {
    postgresql = one(azurerm_postgresql_flexible_server.this[*].fqdn)
    mysql      = one(azurerm_mysql_flexible_server.this[*].fqdn)
    mongodb    = "${local.cosmos_name}.mongo.cosmos.azure.com:10255"
    cosmosdb   = one(azurerm_cosmosdb_account.this[*].endpoint)
    redis      = local.redis_enabled ? "${azurerm_managed_redis.this[0].hostname}:${azurerm_managed_redis.this[0].default_database[0].port}" : null
  }
  database_endpoint = var.enable_database ? local.database_endpoints[var.database_type] : null

  # What an application needs to sign in. Cosmos DB for NoSQL has no entry:
  # it accepts Microsoft Entra ID identities only.
  database_credentials = {
    postgresql = local.postgresql_enabled ? {
      host     = azurerm_postgresql_flexible_server.this[0].fqdn
      port     = 5432
      database = local.database_name
      username = local.database_admin_username
      password = random_password.database[0].result
    } : null
    mysql = local.mysql_enabled ? {
      host     = azurerm_mysql_flexible_server.this[0].fqdn
      port     = 3306
      database = local.database_name
      username = local.database_admin_username
      password = random_password.database[0].result
    } : null
    mongodb = local.mongodb_enabled ? {
      host     = "${local.cosmos_name}.mongo.cosmos.azure.com"
      port     = 10255
      database = local.database_name
      username = local.cosmos_name
      password = azurerm_cosmosdb_account.this[0].primary_key
    } : null
    redis = local.redis_enabled ? {
      host     = azurerm_managed_redis.this[0].hostname
      port     = azurerm_managed_redis.this[0].default_database[0].port
      database = null
      username = "default"
      password = azurerm_managed_redis.this[0].default_database[0].primary_access_key
    } : null
    cosmosdb = null
  }

  database_has_password        = var.enable_database && var.database_type != "cosmosdb"
  database_password            = local.database_has_password ? local.database_credentials[var.database_type].password : null
  database_credentials_stored  = local.database_has_password && var.enable_secrets_manager
  database_credentials_secret  = "${var.name_prefix}-database-credentials"
  database_credentials_content = local.database_credentials_stored ? jsonencode(local.database_credentials[var.database_type]) : null
}

# Administrator password of PostgreSQL and MySQL. Cosmos DB and Redis
# generate their own keys.
resource "random_password" "database" {
  count = local.postgresql_enabled || local.mysql_enabled ? 1 : 0

  length  = 32
  special = false
}

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "this" {
  count = local.postgresql_enabled ? 1 : 0

  name                = "${var.name_prefix}-psql-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  version           = "17"
  sku_name          = local.economy ? "B_Standard_B1ms" : "GP_Standard_D2ds_v5"
  storage_mb        = 32768
  auto_grow_enabled = true

  administrator_login    = local.database_admin_username
  administrator_password = random_password.database[0].result

  # Reachable through the private endpoint only.
  public_network_access_enabled = false

  backup_retention_days        = local.database_backup_days
  geo_redundant_backup_enabled = var.enable_disaster_recovery

  dynamic "high_availability" {
    for_each = local.production ? [1] : []

    content {
      mode = local.database_ha_mode
    }
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = concat(azurerm_user_assigned_identity.encryption[*].id, azurerm_user_assigned_identity.geo_encryption[*].id)
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id                     = local.kms_key_id
      primary_user_assigned_identity_id    = azurerm_user_assigned_identity.encryption[0].id
      geo_backup_key_vault_key_id          = local.geo_kms_key_id
      geo_backup_user_assigned_identity_id = one(azurerm_user_assigned_identity.geo_encryption[*].id)
    }
  }

  tags = local.tags

  # Azure picks the zones and swaps them on a failover; neither must be
  # reset on later applies.
  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]

    precondition {
      condition     = local.network_available
      error_message = "The database ${local.network_requirement}"
    }
  }

  depends_on = [time_sleep.encryption_access]
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count = local.postgresql_enabled ? 1 : 0

  name      = local.database_name
  server_id = azurerm_postgresql_flexible_server.this[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# -----------------------------------------------------------------------------
# MySQL
# -----------------------------------------------------------------------------

resource "azurerm_mysql_flexible_server" "this" {
  count = local.mysql_enabled ? 1 : 0

  name                = "${var.name_prefix}-mysql-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  version  = "8.4"
  sku_name = local.economy ? "B_Standard_B1ms" : "GP_Standard_D2ds_v4"

  administrator_login    = local.database_admin_username
  administrator_password = random_password.database[0].result

  # Reachable through the private endpoint only.
  public_network_access = "Disabled"

  backup_retention_days        = local.database_backup_days
  geo_redundant_backup_enabled = var.enable_disaster_recovery

  storage {
    size_gb           = 32
    auto_grow_enabled = true
  }

  dynamic "high_availability" {
    for_each = local.production ? [1] : []

    content {
      mode = local.database_ha_mode
    }
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = concat(azurerm_user_assigned_identity.encryption[*].id, azurerm_user_assigned_identity.geo_encryption[*].id)
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id                     = local.kms_key_id
      primary_user_assigned_identity_id    = azurerm_user_assigned_identity.encryption[0].id
      geo_backup_key_vault_key_id          = local.geo_kms_key_id
      geo_backup_user_assigned_identity_id = one(azurerm_user_assigned_identity.geo_encryption[*].id)
    }
  }

  tags = local.tags

  # Azure picks the zones and swaps them on a failover; neither must be
  # reset on later applies.
  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]

    precondition {
      condition     = local.network_available
      error_message = "The database ${local.network_requirement}"
    }
  }

  depends_on = [time_sleep.encryption_access]
}

resource "azurerm_mysql_flexible_database" "this" {
  count = local.mysql_enabled ? 1 : 0

  name                = local.database_name
  resource_group_name = azurerm_resource_group.this.name
  server_name         = azurerm_mysql_flexible_server.this[0].name
  charset             = "utf8mb4"
  collation           = "utf8mb4_0900_ai_ci"
}

# -----------------------------------------------------------------------------
# Cosmos DB (MongoDB API or NoSQL API)
# -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_account" "this" {
  count = local.cosmos_enabled ? 1 : 0

  name                = local.cosmos_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  offer_type          = "Standard"
  kind                = local.mongodb_enabled ? "MongoDB" : "GlobalDocumentDB"

  mongo_server_version = local.mongodb_enabled ? "7.0" : null

  # Reachable through the private endpoint only.
  public_network_access_enabled = false
  minimal_tls_version           = "Tls12"

  # The NoSQL API signs clients in with Microsoft Entra ID only. MongoDB
  # clients need the account key, which stays enabled by default.
  local_authentication_enabled = local.mongodb_enabled ? null : false

  automatic_failover_enabled = var.enable_disaster_recovery

  consistency_policy {
    consistency_level = "Session"
  }

  dynamic "geo_location" {
    for_each = local.cosmos_locations

    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  dynamic "capabilities" {
    for_each = toset(concat(
      local.mongodb_enabled ? ["EnableMongo"] : [],
      local.cosmos_serverless ? ["EnableServerless"] : [],
    ))

    content {
      name = capabilities.value
    }
  }

  # Continuous backups allow a restore to any point in time of the period.
  backup {
    type = "Continuous"
    tier = var.enable_backup ? "Continuous30Days" : "Continuous7Days"
  }

  key_vault_key_id      = local.kms_key_id
  default_identity_type = var.enable_kms ? "UserAssignedIdentity=${azurerm_user_assigned_identity.encryption[0].id}" : null

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.encryption[0].id]
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = "The database ${local.network_requirement}"
    }
  }

  depends_on = [time_sleep.encryption_access]
}

resource "azurerm_cosmosdb_mongo_database" "this" {
  count = local.mongodb_enabled ? 1 : 0

  name                = local.database_name
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.this[0].name

  dynamic "autoscale_settings" {
    for_each = local.cosmos_serverless ? [] : [1]

    content {
      max_throughput = 1000
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  count = local.cosmos_enabled && !local.mongodb_enabled ? 1 : 0

  name                = local.database_name
  resource_group_name = azurerm_resource_group.this.name
  account_name        = azurerm_cosmosdb_account.this[0].name

  dynamic "autoscale_settings" {
    for_each = local.cosmos_serverless ? [] : [1]

    content {
      max_throughput = 1000
    }
  }
}

# -----------------------------------------------------------------------------
# Redis (Azure Managed Redis)
# -----------------------------------------------------------------------------

resource "azurerm_managed_redis" "this" {
  count = local.redis_enabled ? 1 : 0

  name                = "${var.name_prefix}-redis-${local.suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku_name                  = local.economy ? "Balanced_B0" : (local.production ? "Balanced_B5" : "Balanced_B1")
  high_availability_enabled = !local.economy

  # Reachable through the private endpoint only.
  public_network_access = "Disabled"

  # Clients connect over TLS and sign in with the generated access key.
  default_database {
    client_protocol                    = "Encrypted"
    access_keys_authentication_enabled = true

    # Snapshots on disk survive a restart of the cache.
    persistence_redis_database_backup_frequency = var.enable_backup ? "6h" : null
  }

  dynamic "identity" {
    for_each = var.enable_kms ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.encryption[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.enable_kms ? [1] : []

    content {
      key_vault_key_id          = local.kms_key_id
      user_assigned_identity_id = azurerm_user_assigned_identity.encryption[0].id
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = local.network_available
      error_message = "The database ${local.network_requirement}"
    }
  }

  depends_on = [time_sleep.encryption_access]
}

# -----------------------------------------------------------------------------
# Credentials in the Key Vault
# -----------------------------------------------------------------------------

# Changes whenever the stored credentials change, which replaces the
# deployment below and writes a new version of the secret.
resource "terraform_data" "database_credentials_version" {
  count = local.database_credentials_stored ? 1 : 0

  triggers_replace = sha256(local.database_credentials_content)
}

# The secret is a JSON document with host, port, database, username and
# password.
resource "azurerm_resource_group_template_deployment" "database_credentials" {
  count = local.database_credentials_stored ? 1 : 0

  name                = "${var.name_prefix}-database-credentials"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  template_content    = local.secret_template

  parameters_content = jsonencode({
    vaultName   = { value = azurerm_key_vault.this[0].name }
    secretName  = { value = local.database_credentials_secret }
    secretValue = { value = local.database_credentials_content }
  })

  tags = local.tags

  # Azure does not return secure parameters, so a comparison with the
  # configuration would always report a change.
  lifecycle {
    ignore_changes       = [parameters_content]
    replace_triggered_by = [terraform_data.database_credentials_version]
  }
}

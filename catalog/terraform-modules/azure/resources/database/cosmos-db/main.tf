terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)

  # Flatten databases and containers for iteration
  database_containers = flatten([
    for db in var.databases : [
      for container in lookup(db, "containers", []) : {
        database_name        = db.name
        container_name       = container.name
        partition_key_path   = container.partition_key_path
        throughput           = lookup(container, "throughput", null)
        autoscale_max        = lookup(container, "autoscale_max_throughput", null)
        indexing_policy      = lookup(container, "indexing_policy", null)
        unique_keys          = lookup(container, "unique_keys", [])
        default_ttl          = lookup(container, "default_ttl", null)
        analytical_store_ttl = lookup(container, "analytical_store_ttl", null)
      }
    ]
  ])
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "this" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.offer_type
  kind                = var.kind

  enable_automatic_failover = var.enable_automatic_failover
  enable_free_tier          = var.enable_free_tier

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? var.max_interval_in_seconds : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? var.max_staleness_prefix : null
  }

  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = lookup(geo_location.value, "zone_redundant", false)
    }
  }

  # Capabilities for different APIs (MongoDB, Cassandra, Table, Gremlin, Serverless)
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  # Analytical storage
  analytical_storage_enabled = var.enable_analytical_storage

  dynamic "analytical_storage" {
    for_each = var.enable_analytical_storage ? [1] : []
    content {
      schema_type = var.analytical_storage_schema_type
    }
  }

  # Backup policy
  dynamic "backup" {
    for_each = var.backup_type == "Periodic" ? [1] : []
    content {
      type                = "Periodic"
      interval_in_minutes = var.backup_interval_in_minutes
      retention_in_hours  = var.backup_retention_in_hours
      storage_redundancy  = var.backup_storage_redundancy
    }
  }

  dynamic "backup" {
    for_each = var.backup_type == "Continuous" ? [1] : []
    content {
      type = "Continuous"
    }
  }

  # Network configuration
  ip_range_filter                   = var.ip_range_filter
  is_virtual_network_filter_enabled = var.is_virtual_network_filter_enabled
  public_network_access_enabled     = var.public_network_access_enabled

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = lookup(virtual_network_rule.value, "ignore_missing_vnet_service_endpoint", false)
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # CORS rules
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }

  tags = local.tags
}

# SQL API Databases
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = {
    for db in var.databases : db.name => db
    if !contains(var.capabilities, "EnableMongo") && !contains(var.capabilities, "EnableCassandra") && !contains(var.capabilities, "EnableGremlin") && !contains(var.capabilities, "EnableTable")
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "autoscale_max_throughput", null) == null ? lookup(each.value, "throughput", null) : null

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# SQL API Containers
resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = {
    for container in local.database_containers : "${container.database_name}-${container.container_name}" => container
    if !contains(var.capabilities, "EnableMongo") && !contains(var.capabilities, "EnableCassandra") && !contains(var.capabilities, "EnableGremlin") && !contains(var.capabilities, "EnableTable")
  }

  name                   = each.value.container_name
  resource_group_name    = var.resource_group_name
  account_name           = azurerm_cosmosdb_account.this.name
  database_name          = azurerm_cosmosdb_sql_database.this[each.value.database_name].name
  partition_key_path     = each.value.partition_key_path
  partition_key_version  = 2
  throughput             = each.value.autoscale_max == null ? each.value.throughput : null
  default_ttl            = each.value.default_ttl
  analytical_storage_ttl = each.value.analytical_store_ttl

  dynamic "autoscale_settings" {
    for_each = each.value.autoscale_max != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max
    }
  }

  dynamic "indexing_policy" {
    for_each = each.value.indexing_policy != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = lookup(indexing_policy.value, "indexing_mode", "consistent")

      dynamic "included_path" {
        for_each = lookup(indexing_policy.value, "included_paths", [])
        content {
          path = included_path.value
        }
      }

      dynamic "excluded_path" {
        for_each = lookup(indexing_policy.value, "excluded_paths", [])
        content {
          path = excluded_path.value
        }
      }

      dynamic "composite_index" {
        for_each = lookup(indexing_policy.value, "composite_indexes", [])
        content {
          dynamic "index" {
            for_each = composite_index.value
            content {
              path  = index.value.path
              order = index.value.order
            }
          }
        }
      }

      dynamic "spatial_index" {
        for_each = lookup(indexing_policy.value, "spatial_indexes", [])
        content {
          path = spatial_index.value
        }
      }
    }
  }

  dynamic "unique_key" {
    for_each = each.value.unique_keys
    content {
      paths = unique_key.value.paths
    }
  }

  dynamic "conflict_resolution_policy" {
    for_each = var.enable_multiple_write_locations ? [1] : []
    content {
      mode                          = var.conflict_resolution_mode
      conflict_resolution_path      = var.conflict_resolution_mode == "LastWriterWins" ? var.conflict_resolution_path : null
      conflict_resolution_procedure = var.conflict_resolution_mode == "Custom" ? var.conflict_resolution_procedure : null
    }
  }
}

# MongoDB API Databases
resource "azurerm_cosmosdb_mongo_database" "this" {
  for_each = {
    for db in var.databases : db.name => db
    if contains(var.capabilities, "EnableMongo")
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "autoscale_max_throughput", null) == null ? lookup(each.value, "throughput", null) : null

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Cassandra Keyspace
resource "azurerm_cosmosdb_cassandra_keyspace" "this" {
  for_each = {
    for db in var.databases : db.name => db
    if contains(var.capabilities, "EnableCassandra")
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "autoscale_max_throughput", null) == null ? lookup(each.value, "throughput", null) : null

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Gremlin Database
resource "azurerm_cosmosdb_gremlin_database" "this" {
  for_each = {
    for db in var.databases : db.name => db
    if contains(var.capabilities, "EnableGremlin")
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "autoscale_max_throughput", null) == null ? lookup(each.value, "throughput", null) : null

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Table API
resource "azurerm_cosmosdb_table" "this" {
  for_each = {
    for db in var.databases : db.name => db
    if contains(var.capabilities, "EnableTable")
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "autoscale_max_throughput", null) == null ? lookup(each.value, "throughput", null) : null

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "autoscale_max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.autoscale_max_throughput
    }
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.account_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.account_name}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = [var.private_endpoint_subresource]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = local.tags
}

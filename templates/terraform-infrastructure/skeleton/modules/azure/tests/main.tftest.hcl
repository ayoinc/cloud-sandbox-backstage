# Plan-only tests against mocked providers: no credentials, no resources.
# Run from the module directory: terraform init -backend=false && terraform test

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      object_id       = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "random" {}
mock_provider "time" {}

# Everything is off except the network.
variables {
  name_prefix         = "acme-dev"
  environment         = "development"
  region              = "westeurope"
  tags                = { Project = "acme" }
  infrastructure_type = "web-application"

  enable_networking           = true
  network_cidr                = "10.20.0.0/16"
  enable_security_group_rules = false
  require_flow_logs           = false

  enable_kubernetes  = false
  node_size          = "medium"
  enable_autoscaling = true
  min_nodes          = 2
  max_nodes          = 5

  enable_database = false
  database_type   = "postgresql"
  enable_storage  = false
  enable_cdn      = false
  enable_waf      = false

  enable_secrets_manager      = false
  enable_kms                  = false
  require_deletion_protection = false

  enable_backup             = false
  enable_monitoring         = false
  enable_managed_prometheus = false
  enable_alerting           = false
  log_retention_days        = 30
  enable_disaster_recovery  = false
  enable_cost_optimization  = false
}

run "defaults_minimal" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "acme-dev-rg" && azurerm_resource_group.this.location == "westeurope"
    error_message = "The resource group is named after the prefix and lives in the region."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["Project"] == "acme" && azurerm_resource_group.this.tags["Environment"] == "development"
    error_message = "Resources carry the given tags and the environment."
  }

  assert {
    condition     = azurerm_virtual_network.this[0].address_space == toset(["10.20.0.0/16"])
    error_message = "The virtual network uses network_cidr."
  }

  assert {
    condition     = azurerm_subnet.public[*].address_prefixes == [tolist(["10.20.0.0/20"]), tolist(["10.20.16.0/20"])]
    error_message = "Public subnets are the first two /20 blocks."
  }

  assert {
    condition     = azurerm_subnet.private[*].address_prefixes == [tolist(["10.20.128.0/20"]), tolist(["10.20.144.0/20"])]
    error_message = "Private subnets are the ninth and tenth /20 blocks."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 2 && length(azurerm_subnet_nat_gateway_association.private) == 2
    error_message = "Every private subnet gets a NAT gateway unless costs are optimised."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_network_security_group.tier))) == "data"
    error_message = "Without tier rules only the data subnet has a security group."
  }

  assert {
    condition     = azurerm_network_security_rule.tier["data-allow-clients"].source_address_prefix == "10.20.0.0/16"
    error_message = "Without tier rules the data subnet accepts traffic from the virtual network only."
  }

  assert {
    condition     = azurerm_network_security_rule.tier["data-deny-all-inbound"].access == "Deny"
    error_message = "The data subnet denies everything else."
  }

  assert {
    condition = alltrue([
      length(azurerm_kubernetes_cluster.this) == 0,
      length(azurerm_postgresql_flexible_server.this) == 0,
      length(azurerm_storage_account.this) == 0,
      length(azurerm_key_vault.this) == 0,
      length(azurerm_log_analytics_workspace.this) == 0,
      length(azurerm_private_endpoint.this) == 0,
      length(azurerm_management_lock.this) == 0,
    ])
    error_message = "Optional components are not created unless enabled."
  }

  assert {
    condition = alltrue([
      output.kubernetes_cluster_name == null,
      output.database_endpoint == null,
      output.database_name == null,
      output.storage_bucket_name == null,
      output.data_lake_bucket_names == [],
      output.waf_id == null,
      output.kms_key_id == null,
      output.secrets_store_id == null,
      output.private_dns_zone_name == null,
    ])
    error_message = "Outputs of components that are not created are null or empty."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "The subnets of the created network are exposed."
  }
}

run "everything_on_in_production" {
  command = plan

  variables {
    environment         = "production"
    secondary_region    = "northeurope"
    infrastructure_type = "container-platform"

    allowed_ingress_cidrs       = ["203.0.113.0/24"]
    enable_security_group_rules = true
    require_flow_logs           = true

    enable_kubernetes = true
    enable_database   = true
    enable_storage    = true
    enable_cdn        = true
    enable_waf        = true

    enable_secrets_manager      = true
    enable_kms                  = true
    require_deletion_protection = true

    enable_backup             = true
    enable_monitoring         = true
    enable_managed_prometheus = true
    enable_alerting           = true
    alert_email               = "platform@example.com"
    log_retention_days        = 90
    enable_disaster_recovery  = true
    enable_cost_optimization  = true
  }

  assert {
    condition     = join(",", sort(keys(azurerm_network_security_group.tier))) == "app,data,web"
    error_message = "Tier rules create a security group per tier."
  }

  assert {
    condition     = azurerm_network_security_rule.tier["web-allow-https-from-clients"].source_address_prefix == "203.0.113.0/24" && azurerm_network_security_rule.tier["web-allow-https-from-clients"].destination_port_range == "443"
    error_message = "The web tier accepts HTTPS from the allowed client CIDR blocks."
  }

  assert {
    condition     = azurerm_network_security_rule.tier["data-allow-clients"].source_address_prefixes == toset(["10.20.128.0/20", "10.20.144.0/20"])
    error_message = "The data tier accepts traffic from the app tier only."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 2 && azurerm_nat_gateway.this[0].zones == toset(["1"]) && azurerm_nat_gateway.this[1].zones == toset(["2"])
    error_message = "Production has a NAT gateway per zone."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].private_cluster_enabled && azurerm_kubernetes_cluster.this[0].local_account_disabled
    error_message = "The cluster API is private and local accounts are disabled."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].sku_tier == "Standard" && azurerm_kubernetes_cluster.this[0].network_profile[0].network_policy == "cilium"
    error_message = "Production uses the Standard tier and network policies are enforced."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].default_node_pool[0].vm_size == "Standard_D4s_v5" && azurerm_kubernetes_cluster.this[0].default_node_pool[0].min_count == 2 && azurerm_kubernetes_cluster.this[0].default_node_pool[0].max_count == 5
    error_message = "The node pool uses the medium size and scales between min_nodes and max_nodes."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster_node_pool.spot) == 0
    error_message = "Production never runs on spot nodes."
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.this[0].oms_agent) == 1 && length(azurerm_kubernetes_cluster.this[0].monitor_metrics) == 1 && length(azurerm_kubernetes_cluster.this[0].key_vault_secrets_provider) == 1
    error_message = "Monitoring, Prometheus and the secrets provider are wired to the cluster."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.this[0].public_network_access_enabled == false && azurerm_postgresql_flexible_server.this[0].backup_retention_days == 35 && azurerm_postgresql_flexible_server.this[0].geo_redundant_backup_enabled
    error_message = "The database is private, keeps backups for 35 days and copies them to the paired region."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.this[0].high_availability[0].mode == "ZoneRedundant" && azurerm_postgresql_flexible_server.this[0].sku_name == "GP_Standard_D2ds_v5"
    error_message = "The production database is zone-redundant on a general-purpose tier."
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server.this[0].customer_managed_key) == 1 && length(azurerm_key_vault.secondary) == 1
    error_message = "The database is encrypted with the customer-managed key, and its geo-redundant backups with a key in the secondary region."
  }

  assert {
    condition     = azurerm_key_vault.this[0].purge_protection_enabled && azurerm_key_vault.this[0].rbac_authorization_enabled && azurerm_key_vault.this[0].network_acls[0].default_action == "Deny"
    error_message = "The Key Vault uses role assignments, purge protection and a deny-by-default firewall."
  }

  assert {
    condition     = length(azurerm_resource_group_template_deployment.database_credentials) == 1 && output.database_password == null
    error_message = "The database credentials are stored in the Key Vault and not exposed as an output."
  }

  assert {
    condition     = azurerm_storage_account.this[0].account_replication_type == "GZRS" && azurerm_storage_account.this[0].min_tls_version == "TLS1_2" && azurerm_storage_account.this[0].https_traffic_only_enabled
    error_message = "Storage is geo-zone-redundant and accepts TLS 1.2 over HTTPS only."
  }

  assert {
    condition     = azurerm_storage_account.this[0].network_rules[0].default_action == "Deny" && azurerm_storage_account.this[0].blob_properties[0].versioning_enabled && azurerm_storage_account.this[0].shared_access_key_enabled == false
    error_message = "Storage denies public addresses, versions blobs and has no account key access."
  }

  assert {
    condition     = length(azurerm_storage_account.this[0].customer_managed_key) == 1 && length(azurerm_storage_management_policy.this) == 1
    error_message = "Storage uses the customer-managed key and a lifecycle policy."
  }

  assert {
    condition     = azurerm_cdn_frontdoor_profile.this[0].sku_name == "Premium_AzureFrontDoor" && azurerm_cdn_frontdoor_route.storage[0].https_redirect_enabled && azurerm_cdn_frontdoor_route.storage[0].forwarding_protocol == "HttpsOnly"
    error_message = "Front Door redirects to HTTPS and talks HTTPS to the origin."
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_origin.storage[0].private_link) == 1 && length(azurerm_resource_group_template_deployment.front_door_link_approval) == 1
    error_message = "Front Door reaches storage over an approved private link."
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_firewall_policy.this) == 1 && length(azurerm_cdn_frontdoor_security_policy.this) == 1 && length(azurerm_web_application_firewall_policy.regional) == 0
    error_message = "The firewall policy is attached to Front Door."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_private_endpoint.this))) == "database,key-vault,storage"
    error_message = "The database, the Key Vault and storage get private endpoints."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_management_lock.this))) == "backup,database,key-vault,kubernetes"
    error_message = "Deletion protection locks the database, the cluster and the vaults."
  }

  assert {
    condition     = azurerm_data_protection_backup_vault.this[0].redundancy == "GeoRedundant" && length(azurerm_data_protection_backup_instance_blob_storage.this) == 1 && length(azurerm_data_protection_backup_instance_postgresql_flexible_server.this) == 1
    error_message = "The backup vault is geo-redundant and protects blobs and the database."
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].retention_in_days == 90 && length(azurerm_network_watcher_flow_log.this) == 1 && length(azurerm_application_insights_workbook.this) == 1
    error_message = "Logs are kept for log_retention_days, flow logs are on and there is a workbook."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_monitor_diagnostic_setting.this))) == "cdn,database,key-vault,kubernetes,registry,storage"
    error_message = "Every created component sends its logs to the workspace."
  }

  assert {
    condition     = length(azurerm_monitor_workspace.this) == 1 && length(azurerm_dashboard_grafana.this) == 1 && length(azurerm_monitor_data_collection_rule_association.prometheus) == 1
    error_message = "Managed Prometheus and Grafana are created and wired to the cluster."
  }

  assert {
    condition     = one(azurerm_monitor_action_group.this[0].email_receiver).email_address == "platform@example.com"
    error_message = "The alert email is subscribed to the action group."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_monitor_metric_alert.this))) == "cdn-server-errors,database-cpu,database-storage,kubernetes-node-cpu,kubernetes-node-memory,storage-availability,waf-blocked-requests"
    error_message = "Alerts cover the database, the cluster, the CDN, the firewall and storage."
  }

  assert {
    condition     = azurerm_container_registry.this[0].sku == "Premium" && azurerm_container_registry.this[0].admin_enabled == false && length(azurerm_container_registry.this[0].georeplications) == 1
    error_message = "The production registry is Premium, replicated and has no admin user."
  }

  assert {
    condition     = length(azurerm_role_assignment.kubernetes_registry) == 1 && length(azurerm_role_assignment.kubernetes_secrets) == 1
    error_message = "The cluster may pull images and read secrets."
  }
}

run "database_mysql" {
  command = plan

  variables {
    enable_database        = true
    database_type          = "mysql"
    enable_secrets_manager = true
    enable_kms             = true
  }

  assert {
    condition     = azurerm_mysql_flexible_server.this[0].public_network_access == "Disabled" && azurerm_mysql_flexible_server.this[0].backup_retention_days == 7
    error_message = "MySQL is private and keeps backups for 7 days without enable_backup."
  }

  assert {
    condition     = length(azurerm_mysql_flexible_server.this[0].high_availability) == 0 && length(azurerm_mysql_flexible_server.this[0].customer_managed_key) == 1
    error_message = "MySQL outside production has no standby and uses the customer-managed key."
  }

  assert {
    condition     = azurerm_mysql_flexible_database.this[0].name == "acme_dev" && output.database_name == "acme_dev"
    error_message = "The database name is the prefix with underscores."
  }

  assert {
    condition     = azurerm_private_dns_zone.private_link["mysql"].name == "privatelink.mysql.database.azure.com"
    error_message = "MySQL resolves through its private link DNS zone."
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server.this) + length(azurerm_cosmosdb_account.this) + length(azurerm_managed_redis.this) == 0
    error_message = "Only the selected database engine is created."
  }
}

run "database_mongodb" {
  command = plan

  variables {
    enable_database          = true
    database_type            = "mongodb"
    enable_kms               = true
    enable_backup            = true
    enable_disaster_recovery = true
    secondary_region         = "northeurope"
  }

  assert {
    condition     = azurerm_cosmosdb_account.this[0].kind == "MongoDB" && azurerm_cosmosdb_account.this[0].public_network_access_enabled == false
    error_message = "MongoDB is a private Cosmos DB account with the MongoDB API."
  }

  assert {
    condition     = azurerm_cosmosdb_account.this[0].automatic_failover_enabled
    error_message = "Disaster recovery adds the secondary region with automatic failover."
  }

  assert {
    condition     = one(azurerm_cosmosdb_account.this[0].backup).tier == "Continuous30Days"
    error_message = "enable_backup extends continuous backups to 30 days."
  }

  assert {
    condition     = length(azurerm_cosmosdb_mongo_database.this) == 1 && length(azurerm_cosmosdb_sql_database.this) == 0
    error_message = "A MongoDB database is created."
  }

  assert {
    condition     = output.database_endpoint != null && length(azurerm_resource_group_template_deployment.database_credentials) == 0
    error_message = "Without a Key Vault for secrets the credentials are not stored."
  }

  assert {
    condition     = length(azurerm_key_vault.secondary) == 0
    error_message = "Only PostgreSQL and MySQL need a key in the secondary region."
  }
}

run "database_cosmosdb" {
  command = plan

  variables {
    enable_database          = true
    database_type            = "cosmosdb"
    enable_secrets_manager   = true
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_cosmosdb_account.this[0].kind == "GlobalDocumentDB" && azurerm_cosmosdb_account.this[0].local_authentication_enabled == false
    error_message = "Cosmos DB for NoSQL accepts Microsoft Entra ID identities only."
  }

  assert {
    condition     = [for capability in azurerm_cosmosdb_account.this[0].capabilities : capability.name] == ["EnableServerless"]
    error_message = "A cost-optimised account outside production is serverless."
  }

  assert {
    condition     = length(azurerm_cosmosdb_sql_database.this) == 1 && length(azurerm_cosmosdb_sql_database.this[0].autoscale_settings) == 0
    error_message = "A NoSQL database without provisioned throughput is created."
  }

  assert {
    condition     = output.database_credentials_secret_id == null && output.database_password == null
    error_message = "Cosmos DB for NoSQL has no password to store or expose."
  }

  assert {
    condition     = azurerm_private_endpoint.this["database"].private_service_connection[0].subresource_names == tolist(["Sql"])
    error_message = "The private endpoint targets the NoSQL API."
  }
}

run "database_redis" {
  command = plan

  variables {
    enable_database = true
    database_type   = "redis"
    enable_alerting = true
  }

  assert {
    condition     = azurerm_managed_redis.this[0].public_network_access == "Disabled" && azurerm_managed_redis.this[0].default_database[0].client_protocol == "Encrypted"
    error_message = "Redis is private and accepts TLS connections only."
  }

  assert {
    condition     = azurerm_managed_redis.this[0].sku_name == "Balanced_B1" && azurerm_managed_redis.this[0].high_availability_enabled
    error_message = "Redis outside production uses a small highly available tier."
  }

  assert {
    condition     = output.database_name == null
    error_message = "Redis has no database name."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_monitor_metric_alert.this))) == "database-memory"
    error_message = "Redis memory is alerted on."
  }
}

run "infrastructure_type_data_platform" {
  command = plan

  variables {
    infrastructure_type      = "data-platform"
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_storage_account.data_lake[0].is_hns_enabled && join(",", sort(keys(azurerm_storage_container.data_lake))) == "curated,raw"
    error_message = "A data platform gets a data lake with raw and curated containers."
  }

  assert {
    condition     = length(azurerm_storage_management_policy.data_lake[0].rule) == 2
    error_message = "Both data lake containers have a lifecycle rule."
  }

  assert {
    condition     = length(output.data_lake_bucket_names) == 2 && length(azurerm_container_registry.this) == 0
    error_message = "The data lake containers are exposed and no registry is created."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_private_endpoint.this))) == "data-lake-blob,data-lake-dfs"
    error_message = "The data lake is reachable over private endpoints for both of its APIs."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 1
    error_message = "A cost-optimised environment outside production has a single NAT gateway."
  }
}

run "infrastructure_type_ml_platform" {
  command = plan

  variables {
    infrastructure_type = "ml-platform"
  }

  assert {
    condition     = length(azurerm_storage_account.data_lake) == 1 && length(azurerm_container_registry.this) == 1
    error_message = "A machine learning platform gets a data lake and a container registry."
  }

  assert {
    condition     = azurerm_container_registry.this[0].sku == "Standard"
    error_message = "The registry outside production uses the Standard SKU."
  }
}

run "infrastructure_type_container_platform" {
  command = plan

  variables {
    infrastructure_type = "container-platform"
  }

  assert {
    condition     = length(azurerm_container_registry.this) == 1 && length(azurerm_storage_account.data_lake) == 0
    error_message = "A container platform gets a container registry only."
  }
}

run "infrastructure_type_serverless_platform" {
  command = plan

  variables {
    infrastructure_type = "serverless-platform"
  }

  assert {
    condition     = length(azurerm_container_registry.this) == 1 && length(azurerm_storage_account.data_lake) == 0
    error_message = "A serverless platform gets a container registry only."
  }
}

run "infrastructure_type_networking_foundation" {
  command = plan

  variables {
    infrastructure_type = "networking-foundation"
  }

  assert {
    condition     = azurerm_private_dns_zone.internal[0].name == "acme-dev.internal" && output.private_dns_zone_name == "acme-dev.internal"
    error_message = "A network foundation gets a private DNS zone named after the prefix."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.internal[0].registration_enabled
    error_message = "The zone is linked to the virtual network."
  }

  assert {
    condition     = length(azurerm_container_registry.this) + length(azurerm_storage_account.data_lake) == 0
    error_message = "A network foundation gets no registry and no data lake."
  }
}

run "existing_network" {
  command = plan

  variables {
    enable_networking = false
    existing_network = {
      network_id         = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/shared-rg/providers/Microsoft.Network/virtualNetworks/shared-vnet"
      public_subnet_ids  = ["/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/shared-rg/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/public-1"]
      private_subnet_ids = ["/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/shared-rg/providers/Microsoft.Network/virtualNetworks/shared-vnet/subnets/private-1"]
    }

    enable_kubernetes = true
    enable_database   = true
    require_flow_logs = true
  }

  assert {
    condition     = length(azurerm_virtual_network.this) + length(azurerm_subnet.private) + length(azurerm_nat_gateway.this) + length(azurerm_network_security_group.tier) == 0
    error_message = "No network resources are created in an existing network."
  }

  assert {
    condition     = output.network_id == var.existing_network.network_id && output.private_subnet_ids == var.existing_network.private_subnet_ids
    error_message = "The existing network is passed through to the outputs."
  }

  assert {
    condition     = azurerm_private_endpoint.this["database"].subnet_id == var.existing_network.private_subnet_ids[0]
    error_message = "Private endpoints go to the first existing private subnet."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].default_node_pool[0].vnet_subnet_id == var.existing_network.private_subnet_ids[0] && azurerm_kubernetes_cluster.this[0].network_profile[0].outbound_type == "loadBalancer"
    error_message = "The cluster nodes join the existing private subnet."
  }

  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.private_link["postgresql"].virtual_network_id == var.existing_network.network_id
    error_message = "Private DNS zones are linked to the existing network."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.this[0].target_resource_id == var.existing_network.network_id && length(azurerm_log_analytics_workspace.this) == 1
    error_message = "Flow logs cover the existing network and get a workspace although monitoring is off."
  }
}

run "database_without_network_fails" {
  command = plan

  variables {
    enable_networking = false
    enable_database   = true
  }

  expect_failures = [azurerm_postgresql_flexible_server.this]
}

run "cdn_with_waf" {
  command = plan

  variables {
    enable_storage = true
    enable_cdn     = true
    enable_waf     = true
  }

  assert {
    condition     = azurerm_cdn_frontdoor_firewall_policy.this[0].mode == "Prevention" && length(azurerm_cdn_frontdoor_firewall_policy.this[0].managed_rule) == 2
    error_message = "The Front Door firewall blocks with managed rule sets."
  }

  assert {
    condition     = azurerm_cdn_frontdoor_firewall_policy.this[0].sku_name == azurerm_cdn_frontdoor_profile.this[0].sku_name
    error_message = "The firewall policy and the Front Door profile share a SKU."
  }

  assert {
    condition     = azurerm_storage_container.cdn[0].name == "cdn" && azurerm_cdn_frontdoor_route.storage[0].cdn_frontdoor_origin_path == "/cdn"
    error_message = "Front Door serves the cdn container."
  }

  assert {
    condition     = azurerm_storage_container.content[0].container_access_type == "private"
    error_message = "The content container stays private."
  }
}

run "cdn_without_waf" {
  command = plan

  variables {
    enable_storage = true
    enable_cdn     = true
  }

  assert {
    condition     = length(azurerm_cdn_frontdoor_profile.this) == 1 && length(azurerm_cdn_frontdoor_firewall_policy.this) + length(azurerm_cdn_frontdoor_security_policy.this) + length(azurerm_web_application_firewall_policy.regional) == 0
    error_message = "A CDN without a firewall creates no firewall policy."
  }

  assert {
    condition     = output.waf_id == null
    error_message = "There is no firewall policy to expose."
  }
}

run "waf_without_cdn" {
  command = plan

  variables {
    enable_waf = true
  }

  assert {
    condition     = length(azurerm_web_application_firewall_policy.regional) == 1 && length(azurerm_cdn_frontdoor_firewall_policy.this) == 0
    error_message = "Without a CDN the firewall policy is regional."
  }

  assert {
    condition     = azurerm_web_application_firewall_policy.regional[0].policy_settings[0].mode == "Prevention"
    error_message = "The regional firewall policy blocks."
  }
}

run "autoscaling_off" {
  command = plan

  variables {
    enable_kubernetes  = true
    enable_autoscaling = false
    node_size          = "small"
    min_nodes          = 3

    kubernetes_api_allowed_cidrs = ["198.51.100.0/24"]
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].default_node_pool[0].auto_scaling_enabled == false && azurerm_kubernetes_cluster.this[0].default_node_pool[0].node_count == 3
    error_message = "Without autoscaling the node count is fixed at min_nodes."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].default_node_pool[0].vm_size == "Standard_D2s_v5"
    error_message = "Small nodes have two vCPUs."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].private_cluster_enabled == false && azurerm_kubernetes_cluster.this[0].api_server_access_profile[0].authorized_ip_ranges == toset(["198.51.100.0/24"])
    error_message = "An allow list opens the API to exactly those CIDR blocks."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].network_profile[0].outbound_type == "userAssignedNATGateway"
    error_message = "Nodes of a created network leave through the NAT gateways."
  }
}

run "spot_nodes_when_cost_optimised" {
  command = plan

  variables {
    enable_kubernetes        = true
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.spot[0].priority == "Spot" && azurerm_kubernetes_cluster_node_pool.spot[0].min_count == 2 && azurerm_kubernetes_cluster_node_pool.spot[0].max_count == 5
    error_message = "Workloads run on an autoscaled spot pool."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].default_node_pool[0].node_count == 1 && azurerm_kubernetes_cluster.this[0].default_node_pool[0].only_critical_addons_enabled
    error_message = "One regular node keeps the system components running."
  }
}

run "log_retention_of_seven_years" {
  command = plan

  variables {
    enable_kubernetes  = true
    enable_database    = true
    enable_monitoring  = true
    require_flow_logs  = true
    log_retention_days = 2557
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].retention_in_days == 730
    error_message = "The workspace keeps its maximum of 730 days available for queries."
  }

  assert {
    condition     = one(azurerm_storage_management_policy.logs[0].rule[0].actions[0].base_blob).delete_after_days_since_modification_greater_than == 2557
    error_message = "The log storage account keeps flow logs and archived resource logs for log_retention_days."
  }

  assert {
    condition     = azurerm_storage_management_policy.logs[0].rule[0].filters[0].blob_types == toset(["appendBlob", "blockBlob"])
    error_message = "The lifecycle rule covers flow logs (block blobs) and resource logs (append blobs)."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_log_analytics_workspace_table.container_logs))) == "ContainerLogV2,KubeEvents" && azurerm_log_analytics_workspace_table.container_logs["ContainerLogV2"].total_retention_in_days == 2922
    error_message = "The container log tables get long-term retention for the next whole number of years: eight for 2557 days."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_monitor_diagnostic_setting.this))) == "database,kubernetes" && length(azurerm_storage_account.logs) == 1
    error_message = "Resource logs have an archive to be written to."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.this[0].retention_policy[0].enabled == false
    error_message = "Flow log retention is left to the lifecycle rule of the storage account."
  }
}

run "log_retention_of_one_week" {
  command = plan

  variables {
    enable_monitoring  = true
    require_flow_logs  = true
    log_retention_days = 7
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].retention_in_days == 30
    error_message = "The workspace cannot keep less than 30 days."
  }

  assert {
    condition     = one(azurerm_storage_management_policy.logs[0].rule[0].actions[0].base_blob).delete_after_days_since_modification_greater_than == 7
    error_message = "Flow logs are deleted after log_retention_days."
  }

  assert {
    condition     = length(azurerm_log_analytics_workspace_table.container_logs) == 0
    error_message = "Long-term retention is only configured above 730 days."
  }
}

run "monitoring_without_flow_logs_needs_no_log_storage" {
  command = plan

  variables {
    enable_monitoring  = true
    log_retention_days = 365
  }

  assert {
    condition     = azurerm_log_analytics_workspace.this[0].retention_in_days == 365 && length(azurerm_storage_account.logs) == 0
    error_message = "Up to 730 days the workspace alone keeps the logs."
  }
}

run "cost_optimised_postgresql" {
  command = plan

  variables {
    enable_database          = true
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.this[0].sku_name == "B_Standard_B1ms" && length(azurerm_postgresql_flexible_server.this[0].high_availability) == 0
    error_message = "A cost-optimised database outside production uses the smallest burstable tier without a standby."
  }

  assert {
    condition     = output.database_credentials_secret_id == null && length(azurerm_resource_group_template_deployment.database_credentials) == 0 && length(random_password.database) == 1
    error_message = "Without a Key Vault the generated password is not stored; it is the sensitive database_password output."
  }
}

run "cost_optimised_mysql" {
  command = plan

  variables {
    enable_database          = true
    database_type            = "mysql"
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_mysql_flexible_server.this[0].sku_name == "B_Standard_B1ms"
    error_message = "A cost-optimised MySQL server outside production uses the smallest burstable tier."
  }
}

run "production_mysql" {
  command = plan

  variables {
    environment              = "production"
    enable_database          = true
    database_type            = "mysql"
    enable_kms               = true
    enable_backup            = true
    enable_disaster_recovery = true
    secondary_region         = "northeurope"
    availability_zones       = []
  }

  assert {
    condition     = azurerm_mysql_flexible_server.this[0].high_availability[0].mode == "SameZone" && azurerm_mysql_flexible_server.this[0].backup_retention_days == 35
    error_message = "In a region without zones the standby runs in the same zone; backups are kept for 35 days."
  }

  assert {
    condition     = azurerm_mysql_flexible_server.this[0].geo_redundant_backup_enabled && length(azurerm_key_vault.secondary) == 1 && azurerm_key_vault.secondary[0].location == "northeurope"
    error_message = "Geo-redundant backups are encrypted with a key in the secondary region."
  }

  assert {
    condition     = length(azurerm_data_protection_backup_vault.this) == 1 && length(azurerm_data_protection_backup_instance_postgresql_flexible_server.this) == 0
    error_message = "The backup vault exists, but only PostgreSQL gets a vault backup."
  }
}

run "cost_optimised_redis_with_backup" {
  command = plan

  variables {
    enable_database          = true
    database_type            = "redis"
    enable_backup            = true
    enable_secrets_manager   = true
    enable_cost_optimization = true
  }

  assert {
    condition     = azurerm_managed_redis.this[0].sku_name == "Balanced_B0" && azurerm_managed_redis.this[0].high_availability_enabled == false
    error_message = "A cost-optimised cache outside production is the smallest size without a replica."
  }

  assert {
    condition     = azurerm_managed_redis.this[0].default_database[0].persistence_redis_database_backup_frequency == "6h"
    error_message = "enable_backup persists the cache to disk."
  }

  assert {
    condition     = length(azurerm_resource_group_template_deployment.database_credentials) == 1 && output.database_password == null
    error_message = "The access key is stored in the Key Vault."
  }
}

run "production_redis" {
  command = plan

  variables {
    environment     = "production"
    enable_database = true
    database_type   = "redis"
    enable_kms      = true
  }

  assert {
    condition     = azurerm_managed_redis.this[0].sku_name == "Balanced_B5" && azurerm_managed_redis.this[0].high_availability_enabled && length(azurerm_managed_redis.this[0].customer_managed_key) == 1
    error_message = "The production cache is highly available and encrypted with the customer-managed key."
  }
}

run "production_cosmosdb" {
  command = plan

  variables {
    environment                 = "production"
    enable_database             = true
    database_type               = "cosmosdb"
    enable_kms                  = true
    require_deletion_protection = true
    enable_cost_optimization    = true
  }

  assert {
    condition     = length(azurerm_cosmosdb_account.this[0].capabilities) == 0 && length(azurerm_cosmosdb_sql_database.this[0].autoscale_settings) == 1
    error_message = "Production never uses the serverless tier."
  }

  assert {
    condition     = join(",", sort(keys(azurerm_management_lock.this))) == "database,key-vault"
    error_message = "Deletion protection locks the database and the Key Vault."
  }
}

run "rejects_unknown_database_type" {
  command = plan

  variables {
    database_type = "dynamodb"
  }

  expect_failures = [var.database_type]
}

run "disaster_recovery_needs_secondary_region" {
  command = plan

  variables {
    enable_disaster_recovery = true
  }

  expect_failures = [var.enable_disaster_recovery]
}

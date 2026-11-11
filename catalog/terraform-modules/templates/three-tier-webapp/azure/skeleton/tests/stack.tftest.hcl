# Plans the stack against mocked providers, so the tests need no Azure account.
# Values not set in a run come from terraform.tfvars.

mock_provider "azurerm" {}

mock_provider "random" {}

mock_provider "tls" {}

run "configured_values" {
  command = plan

  assert {
    condition     = length(azurerm_kubernetes_cluster.main) + length(azurerm_linux_virtual_machine_scale_set.app) + length(azurerm_container_app.app) == 1
    error_message = "Exactly one of the AKS cluster, the scale set and the Container App exists."
  }

  assert {
    condition     = length(module.sql) + length(azurerm_postgresql_flexible_server.main) + length(module.cosmos) == 1
    error_message = "Exactly one of the SQL server, the PostgreSQL server and the Cosmos DB account exists."
  }

  assert {
    condition     = length(module.front_door) == (var.enable_front_door ? 1 : 0)
    error_message = "A Front Door profile exists exactly when enable_front_door is true."
  }

  assert {
    condition     = azurerm_application_gateway.main.sku[0].name == (var.enable_waf ? "WAF_v2" : "Standard_v2")
    error_message = "The Application Gateway runs on the WAF_v2 SKU exactly when enable_waf is true."
  }
}

run "aks" {
  command = plan

  variables {
    compute_type = "aks"
    vm_size      = "Standard_D4s_v5"
    min_nodes    = 3
    max_nodes    = 7
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.main) == 1 && length(azurerm_linux_virtual_machine_scale_set.app) == 0 && length(azurerm_container_app.app) == 0
    error_message = "aks creates an AKS cluster and no other compute."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main[0].default_node_pool[0].vm_size == "Standard_D4s_v5"
    error_message = "vm_size sets the size of the AKS nodes."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main[0].default_node_pool[0].min_count == 3 && azurerm_kubernetes_cluster.main[0].default_node_pool[0].max_count == 7
    error_message = "min_nodes and max_nodes bound the AKS node autoscaler."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main[0].private_cluster_enabled
    error_message = "The cluster is private while no address range is authorised."
  }

  assert {
    condition     = contains(keys(local.subnets), "ingress") && local.backend_protocol == "Http" && output.aks_ingress_ip == cidrhost(local.subnet_prefixes.ingress, 10)
    error_message = "The gateway sends requests to the fixed ingress address in the ingress subnet."
  }
}

run "aks_with_public_api_server" {
  command = plan

  variables {
    compute_type             = "aks"
    aks_authorized_ip_ranges = ["203.0.113.0/24"]
  }

  assert {
    condition     = !azurerm_kubernetes_cluster.main[0].private_cluster_enabled && length(azurerm_kubernetes_cluster.main[0].api_server_access_profile) == 1
    error_message = "Authorised address ranges give the API server a restricted public endpoint."
  }
}

run "vmss" {
  command = plan

  variables {
    compute_type = "vmss"
    vm_size      = "Standard_B2s"
    min_nodes    = 2
    max_nodes    = 5
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.app) == 1 && length(azurerm_kubernetes_cluster.main) == 0 && length(azurerm_container_app.app) == 0
    error_message = "vmss creates a scale set and no other compute."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.app[0].sku == "Standard_B2s"
    error_message = "vm_size sets the size of the scale set instances."
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.app[0].profile[0].capacity[0].minimum == 2 && azurerm_monitor_autoscale_setting.app[0].profile[0].capacity[0].maximum == 5
    error_message = "min_nodes and max_nodes bound the scale set autoscaling."
  }

  assert {
    condition     = length(module.nat_gateway) == 1 && length(tls_private_key.vmss) == 1 && !contains(keys(local.subnets), "ingress")
    error_message = "The scale set gets a NAT gateway and a generated SSH key, and no ingress subnet."
  }
}

run "container_apps" {
  command = plan

  variables {
    compute_type = "container-apps"
    min_nodes    = 1
    max_nodes    = 4
  }

  assert {
    condition     = length(azurerm_container_app.app) == 1 && length(azurerm_kubernetes_cluster.main) == 0 && length(azurerm_linux_virtual_machine_scale_set.app) == 0
    error_message = "container-apps creates a Container App and no other compute."
  }

  assert {
    condition     = azurerm_container_app.app[0].template[0].min_replicas == 1 && azurerm_container_app.app[0].template[0].max_replicas == 4
    error_message = "min_nodes and max_nodes bound the replicas of the Container App."
  }

  assert {
    condition     = azurerm_container_app_environment.main[0].internal_load_balancer_enabled && local.subnets["app"].delegation.service_delegation.name == "Microsoft.App/environments"
    error_message = "The Container Apps environment is internal and its subnet is delegated."
  }

  assert {
    condition     = local.backend_protocol == "Https" && local.backend_port == 443
    error_message = "The gateway reaches the Container App over HTTPS."
  }
}

run "sql_database" {
  command = plan

  variables {
    database_type = "sql-database"
    database_sku  = "GP_Gen5_2"
  }

  assert {
    condition     = length(module.sql) == 1 && length(azurerm_postgresql_flexible_server.main) == 0 && length(module.cosmos) == 0
    error_message = "sql-database creates an Azure SQL server and no other database."
  }

  assert {
    condition     = length(azurerm_private_endpoint.sql) == 1 && local.subnets["data"].delegation == null
    error_message = "The SQL server is reached through a private endpoint in the data subnet."
  }
}

run "postgresql" {
  command = plan

  variables {
    database_type = "postgresql"
    database_sku  = "B_Standard_B1ms"
  }

  assert {
    condition     = length(azurerm_postgresql_flexible_server.main) == 1 && length(module.sql) == 0 && length(module.cosmos) == 0
    error_message = "postgresql creates a flexible server and no other database."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.main[0].sku_name == "B_Standard_B1ms" && !azurerm_postgresql_flexible_server.main[0].public_network_access_enabled
    error_message = "database_sku sets the size of the flexible server, which has no public endpoint."
  }

  assert {
    condition     = local.subnets["data"].delegation.service_delegation.name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "The data subnet is delegated to the flexible server."
  }
}

run "cosmos_db_serverless" {
  command = plan

  variables {
    database_type = "cosmos-db"
    database_sku  = "serverless"
  }

  assert {
    condition     = length(module.cosmos) == 1 && length(module.sql) == 0 && length(azurerm_postgresql_flexible_server.main) == 0
    error_message = "cosmos-db creates a Cosmos DB account and no other database."
  }

  assert {
    condition     = length(azurerm_private_endpoint.cosmos) == 1 && local.subnets["data"].delegation == null
    error_message = "The Cosmos DB account is reached through a private endpoint in the data subnet."
  }

  assert {
    condition     = length(random_password.database) == 0 && output.database_admin_username == null
    error_message = "Cosmos DB has no administrator login."
  }
}

run "cosmos_db_autoscale" {
  command = plan

  variables {
    database_type = "cosmos-db"
    database_sku  = "autoscale"
  }

  assert {
    condition     = length(module.cosmos) == 1
    error_message = "The autoscale capacity mode creates a Cosmos DB account."
  }
}

run "production_with_edge_services" {
  command = plan

  variables {
    environment       = "production"
    enable_waf        = true
    enable_front_door = true
  }

  assert {
    condition     = azurerm_application_gateway.main.sku[0].name == "WAF_v2" && length(azurerm_web_application_firewall_policy.gateway) == 1
    error_message = "enable_waf runs the gateway on WAF_v2 with a firewall policy."
  }

  assert {
    condition     = azurerm_web_application_firewall_policy.gateway[0].policy_settings[0].mode == "Prevention" && azurerm_web_application_firewall_policy.gateway[0].managed_rules[0].managed_rule_set[0].type == "OWASP"
    error_message = "The firewall policy applies the OWASP rule set in Prevention mode."
  }

  assert {
    condition     = length(module.front_door) == 1 && azurerm_network_security_rule.gateway_web.source_address_prefix == "AzureFrontDoor.Backend"
    error_message = "enable_front_door creates the profile and admits only Front Door to the gateway."
  }

  assert {
    condition     = length(azurerm_web_application_firewall_policy.gateway[0].custom_rules) == 1
    error_message = "With WAF and Front Door, requests without this profile's Front Door ID are blocked."
  }

  assert {
    condition     = module.resource_group.name == "rg-${var.project_name}-prod-${var.location}" && azurerm_application_gateway.main.autoscale_configuration[0].min_capacity == 2
    error_message = "production is deployed as prod with at least two gateway instances."
  }
}

run "without_edge_services" {
  command = plan

  variables {
    enable_waf        = false
    enable_front_door = false
  }

  assert {
    condition     = azurerm_application_gateway.main.sku[0].name == "Standard_v2" && length(azurerm_web_application_firewall_policy.gateway) == 0
    error_message = "Without WAF the gateway runs on Standard_v2 and has no firewall policy."
  }

  assert {
    condition     = length(module.front_door) == 0 && azurerm_network_security_rule.gateway_web.source_address_prefix == "Internet"
    error_message = "Without Front Door the gateway is reached from the internet directly."
  }

  assert {
    condition     = !local.serves_https && !contains(azurerm_network_security_rule.gateway_web.destination_port_ranges, "443")
    error_message = "Without a certificate the gateway listens on port 80 only."
  }

  assert {
    condition     = output.front_door_host_name == null
    error_message = "There is no Front Door host name without Front Door."
  }
}

run "https_listener" {
  command = plan

  variables {
    tls_certificate_secret_id = "https://kv-example.vault.azure.net/secrets/web-certificate"
  }

  assert {
    condition     = local.serves_https && contains(azurerm_network_security_rule.gateway_web.destination_port_ranges, "443")
    error_message = "A certificate adds the HTTPS listener and opens port 443 to it."
  }
}

run "rejects_sku_of_another_database" {
  command = plan

  variables {
    database_type = "postgresql"
    database_sku  = "GP_Gen5_2"
  }

  expect_failures = [var.database_sku]
}

run "maximum_below_minimum" {
  command = plan

  variables {
    compute_type = "container-apps"
    min_nodes    = 5
    max_nodes    = 2
  }

  assert {
    condition     = azurerm_container_app.app[0].template[0].min_replicas == 5 && azurerm_container_app.app[0].template[0].max_replicas == 5
    error_message = "A maximum below the minimum is raised to the minimum."
  }
}

run "address_space_in_another_private_block" {
  command = plan

  variables {
    compute_type       = "aks"
    vnet_address_space = "172.20.0.7/16"
  }

  assert {
    condition     = local.vnet_address_space == "172.20.0.0/16" && local.subnet_prefixes.app == "172.20.16.0/20"
    error_message = "The subnets are carved out of the network address of the address space."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main[0].network_profile[0].service_cidr == "10.0.0.0/16" && azurerm_kubernetes_cluster.main[0].network_profile[0].pod_cidr == "192.168.0.0/16"
    error_message = "Pod and service addresses stay outside the virtual network."
  }
}

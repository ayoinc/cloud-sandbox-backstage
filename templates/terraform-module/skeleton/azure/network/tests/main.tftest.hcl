mock_provider "azurerm" {}

variables {
  project_name        = "demo"
  environment         = "dev"
  resource_group_name = "demo-dev-rg"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.main.name == "vnet-demo-dev"
    error_message = "VNet name must derive from project and environment."
  }

  assert {
    condition     = length(azurerm_resource_group.main) == 0
    error_message = "No resource group is created when one is supplied."
  }

  assert {
    condition     = sort(keys(azurerm_subnet.main)) == tolist(["database-1", "kubernetes-1", "private-1", "public-1"])
    error_message = "One subnet per tier is expected by default."
  }

  assert {
    condition     = azurerm_subnet.main["public-1"].address_prefixes == tolist(["10.0.0.0/20"]) && azurerm_subnet.main["kubernetes-1"].address_prefixes == tolist(["10.0.48.0/20"])
    error_message = "Subnets must be carved consecutively from the VNet CIDR."
  }

  assert {
    condition     = azurerm_subnet.main["database-1"].delegation[0].service_delegation[0].name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "Database subnets must be delegated to PostgreSQL Flexible Server."
  }

  assert {
    condition     = length(azurerm_subnet.main["private-1"].delegation) == 0
    error_message = "Only database subnets are delegated."
  }

  assert {
    condition     = length(azurerm_nat_gateway.main) == 1 && sort(keys(azurerm_subnet_nat_gateway_association.main)) == tolist(["kubernetes-1", "private-1"])
    error_message = "The NAT Gateway serves the private and kubernetes subnets."
  }

  assert {
    condition     = !contains(keys(azurerm_network_security_rule.inbound), "public/AllowPublicIngress")
    error_message = "Public subnets must stay closed to the internet by default."
  }

  assert {
    condition     = azurerm_network_security_rule.inbound["database/AllowDatabaseFromApplications"].source_address_prefixes == toset(["10.0.16.0/20", "10.0.48.0/20"])
    error_message = "Database subnets accept traffic only from the private and kubernetes subnets."
  }

  assert {
    condition     = azurerm_network_security_rule.inbound["database/DenyAllInbound"].access == "Deny"
    error_message = "Database subnets must deny all other inbound traffic."
  }

  assert {
    condition     = sort(keys(azurerm_subnet_route_table_association.main)) == tolist(["database-1", "private-1", "public-1"])
    error_message = "Kubernetes subnets must not get a route table."
  }

  assert {
    condition     = sort(keys(output.subnet_ids)) == tolist(["database", "kubernetes", "private", "public"])
    error_message = "subnet_ids must expose one entry per tier."
  }
}

run "creates_resource_group_when_none_given" {
  command = plan

  variables {
    resource_group_name = null
  }

  assert {
    condition     = azurerm_resource_group.main[0].name == "rg-demo-dev-network"
    error_message = "A resource group must be created when none is supplied."
  }
}

run "public_ingress_and_multiple_subnets" {
  command = plan

  variables {
    vnet_cidr            = "10.20.0.0/16"
    subnet_count         = 2
    public_ingress_cidrs = ["203.0.113.0/24"]
    public_ingress_ports = [443]
  }

  assert {
    condition     = length(azurerm_subnet.main) == 8
    error_message = "Two subnets per tier are expected."
  }

  assert {
    condition     = azurerm_subnet.main["private-2"].address_prefixes == tolist(["10.20.48.0/20"])
    error_message = "Second private subnet must follow the tier layout."
  }

  assert {
    condition     = azurerm_network_security_rule.inbound["public/AllowPublicIngress"].source_address_prefixes == toset(["203.0.113.0/24"])
    error_message = "Public ingress must be limited to the allow-list."
  }

  assert {
    condition     = azurerm_network_security_rule.inbound["public/AllowPublicIngress"].destination_port_range == "443"
    error_message = "Public ingress must open only the requested port."
  }
}

run "nat_and_service_endpoints_disabled" {
  command = plan

  variables {
    enable_nat               = false
    enable_service_endpoints = false
  }

  assert {
    condition     = length(azurerm_nat_gateway.main) == 0 && length(azurerm_public_ip.nat) == 0 && length(azurerm_subnet_nat_gateway_association.main) == 0
    error_message = "No NAT resources are created when NAT is disabled."
  }

  assert {
    condition     = length(azurerm_subnet.main["private-1"].service_endpoints) == 0
    error_message = "Service endpoints must be absent when disabled."
  }
}

run "zonal_public_ip_disabled" {
  command = plan

  variables {
    enable_zone_redundancy = false
  }

  assert {
    condition     = azurerm_public_ip.nat[0].zones == null
    error_message = "The NAT public IP must not be zonal when zone redundancy is disabled."
  }
}

run "rejects_open_public_ingress" {
  command = plan

  variables {
    public_ingress_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.public_ingress_cidrs]
}

run "rejects_too_many_subnets" {
  command = plan

  variables {
    subnet_count   = 4
    subnet_newbits = 3
  }

  expect_failures = [var.subnet_count]
}

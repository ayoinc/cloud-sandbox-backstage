# Plan-only tests against mocked providers: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test

mock_provider "azurerm" {}
mock_provider "random" {}
mock_provider "tls" {}

variables {
  name            = "test-sandbox"
  environment     = "sandbox"
  region          = "eastus"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = 2
  private_subnets = 2
  include_bastion = false
  include_eks     = false
  include_rds     = false
}

run "root_module_plans" {
  command = plan

  assert {
    condition     = output.resource_group_name == "test-sandbox-rg"
    error_message = "The resource group is named after the sandbox."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "The root module must expose one ID per subnet."
  }

  assert {
    condition     = output.bastion_public_ip == null && output.aks_cluster_name == null && output.postgresql_fqdn == null
    error_message = "Outputs of components that are not included must be null."
  }
}

run "network_layout" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  assert {
    condition     = length(azurerm_virtual_network.this.address_space) == 1 && contains(azurerm_virtual_network.this.address_space, "10.0.0.0/16")
    error_message = "The virtual network must use vpc_cidr."
  }

  assert {
    condition     = azurerm_subnet.public[*].address_prefixes == [tolist(["10.0.0.0/20"]), tolist(["10.0.16.0/20"])]
    error_message = "Public subnets must be the first /20 blocks of the address space."
  }

  assert {
    condition     = azurerm_subnet.private[*].address_prefixes == [tolist(["10.0.128.0/20"]), tolist(["10.0.144.0/20"])]
    error_message = "Private subnets must start at the ninth /20 block of the address space."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 1 && length(azurerm_subnet_nat_gateway_association.private) == 2
    error_message = "Private subnets need a NAT gateway."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["Project"] == "test-sandbox" && azurerm_resource_group.this.tags["Environment"] == "sandbox"
    error_message = "Resources must carry the project and environment tags."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.bastion) == 0 && length(azurerm_kubernetes_cluster.this) == 0 && length(azurerm_postgresql_flexible_server.this) == 0
    error_message = "Optional components must not be created unless included."
  }
}

run "public_only_network" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    public_subnets  = 1
    private_subnets = 0
  }

  assert {
    condition     = length(azurerm_subnet.public) == 1 && length(azurerm_subnet.private) == 0
    error_message = "Subnet counts must follow the variables."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 0 && length(azurerm_network_security_group.private) == 0
    error_message = "No NAT gateway is needed without private subnets."
  }
}

run "bastion_ssh_is_closed_by_default" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_bastion = true
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine.bastion) == 1
    error_message = "The bastion must be created when included."
  }

  assert {
    condition     = azurerm_linux_virtual_machine.bastion[0].disable_password_authentication
    error_message = "The bastion must accept SSH keys only."
  }

  assert {
    condition     = length(azurerm_network_security_rule.bastion_ssh) == 0
    error_message = "SSH must stay closed unless bastion_allowed_cidrs is set."
  }
}

run "bastion_ssh_allow_list" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_bastion       = true
    bastion_allowed_cidrs = ["203.0.113.0/24"]
  }

  assert {
    condition     = azurerm_network_security_rule.bastion_ssh[0].source_address_prefixes == toset(["203.0.113.0/24"])
    error_message = "The SSH rule must allow exactly the listed CIDR blocks."
  }
}

run "aks_is_private_by_default" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    private_subnets = 0
    include_eks     = true
  }

  assert {
    condition     = length(azurerm_subnet.private) == 1
    error_message = "AKS needs a private subnet even when none were requested."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].private_cluster_enabled
    error_message = "The AKS API must be private unless kubernetes_api_allowed_cidrs is set."
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this[0].network_profile[0].network_policy == "azure"
    error_message = "Network policies must be enabled."
  }
}

run "postgresql_is_private" {
  command = plan

  module {
    source = "./modules/sandbox"
  }

  variables {
    include_rds = true
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.this[0].public_network_access_enabled == false
    error_message = "The database must not be reachable from the internet."
  }

  assert {
    condition     = azurerm_subnet.database[0].address_prefixes == tolist(["10.0.240.0/20"])
    error_message = "The database subnet is the last /20 block of the address space."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server_database.this[0].name == "db_test_sandbox"
    error_message = "The database name is derived from the sandbox name."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/28"
  }

  expect_failures = [var.vpc_cidr]
}

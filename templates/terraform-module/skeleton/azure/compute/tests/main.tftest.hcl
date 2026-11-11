mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/44444444-4444-4444-4444-444444444444"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "tls" {
  mock_resource "tls_private_key" {
    defaults = {
      public_key_openssh = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD1SX3+3YXYCnxQ18ppr6ty58a6n8tWbyKnXvy2StCkX2+WXAW4l/NfttqcuYVlh07efAb4KRGZRh6mARXwv+5G8SZSQsFpboTpJ5pukPUKg7sRiRYiyFGBFu7KGyzzUT851rSrn7Am6EUud0ZsvPDE3H3EBjbvum5nnIqkGabEYVfsbpJ1fAzuiH/lwUj50tJk+mHaWHDpm1Q7Qk4d/+pbWyQZ0K6144FfXSROFkK4qyn+ftayaK7o1hO6FIH7pntpbb8D7CsMdr7y1m74qrxCWSWwR3eHg8AXQoIwc29KrGOyUdPbbZRpF2TH7eBaMuTurytFGXKxaujcd+2BSiP platform@example.com"
    }
  }
}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
  subnet_id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.name == "demo-platform-services-dev-vmss" && azurerm_linux_virtual_machine_scale_set.main.sku == "Standard_B2s_v2"
    error_message = "The scale set must use the derived name and default size."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.disable_password_authentication && azurerm_linux_virtual_machine_scale_set.main.secure_boot_enabled && azurerm_linux_virtual_machine_scale_set.main.vtpm_enabled
    error_message = "Password login must be disabled and trusted launch enabled."
  }

  assert {
    condition     = length(tls_private_key.ssh) == 1
    error_message = "An SSH key pair must be generated when none is supplied."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.source_image_reference[0].offer == "ubuntu-24_04-lts"
    error_message = "The default image must be Ubuntu 24.04 LTS."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.main.network_interface[0].ip_configuration[0].public_ip_address) == 0
    error_message = "Instances must not get public IPs by default."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.upgrade_mode == "Manual" && length(azurerm_linux_virtual_machine_scale_set.main.automatic_os_upgrade_policy) == 0
    error_message = "Automatic OS upgrades are off by default."
  }

  assert {
    condition     = azurerm_network_security_rule.allow["AllowSSH"].source_address_prefixes == toset(["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"])
    error_message = "SSH must be limited to private address ranges by default."
  }

  assert {
    condition     = azurerm_network_security_rule.deny_all_inbound.access == "Deny" && azurerm_network_security_rule.deny_all_inbound.priority == 4096
    error_message = "All other inbound traffic must be denied."
  }

  assert {
    condition     = azurerm_role_assignment.vmss_reader.scope == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg" && azurerm_role_assignment.vmss_reader.role_definition_name == "Reader"
    error_message = "The identity must only read its own resource group."
  }

  assert {
    condition     = azurerm_monitor_autoscale_setting.vmss.profile[0].capacity[0].minimum == 1 && azurerm_monitor_autoscale_setting.vmss.profile[0].capacity[0].maximum == 5
    error_message = "Autoscale bounds must follow the instance variables."
  }

  assert {
    condition     = length(azurerm_monitor_autoscale_setting.vmss.notification) == 0 && length(azurerm_monitor_data_collection_rule_association.vmss) == 0
    error_message = "Notifications and rule association are off by default."
  }
}

run "all_features" {
  command = plan

  variables {
    ssh_public_key                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD1SX3+3YXYCnxQ18ppr6ty58a6n8tWbyKnXvy2StCkX2+WXAW4l/NfttqcuYVlh07efAb4KRGZRh6mARXwv+5G8SZSQsFpboTpJ5pukPUKg7sRiRYiyFGBFu7KGyzzUT851rSrn7Am6EUud0ZsvPDE3H3EBjbvum5nnIqkGabEYVfsbpJ1fAzuiH/lwUj50tJk+mHaWHDpm1Q7Qk4d/+pbWyQZ0K6144FfXSROFkK4qyn+ftayaK7o1hO6FIH7pntpbb8D7CsMdr7y1m74qrxCWSWwR3eHg8AXQoIwc29KrGOyUdPbbZRpF2TH7eBaMuTurytFGXKxaujcd+2BSiP platform@example.com"
    zones                         = ["1", "2", "3"]
    enable_public_ip              = true
    enable_automatic_os_upgrade   = true
    enable_encryption_at_host     = true
    ssh_allowed_cidrs             = []
    ingress_allowed_cidrs         = ["203.0.113.0/24"]
    ingress_ports                 = [8443]
    health_check_port             = 8080
    autoscale_notification_emails = ["platform@example.com"]
    data_collection_rule_id       = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/demo-dev-rg/providers/Microsoft.Insights/dataCollectionRules/demo-dcr"
  }

  assert {
    condition     = length(tls_private_key.ssh) == 0 && output.ssh_private_key == null
    error_message = "No key pair is generated when a public key is supplied."
  }

  assert {
    condition     = one(azurerm_linux_virtual_machine_scale_set.main.admin_ssh_key).public_key == "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD1SX3+3YXYCnxQ18ppr6ty58a6n8tWbyKnXvy2StCkX2+WXAW4l/NfttqcuYVlh07efAb4KRGZRh6mARXwv+5G8SZSQsFpboTpJ5pukPUKg7sRiRYiyFGBFu7KGyzzUT851rSrn7Am6EUud0ZsvPDE3H3EBjbvum5nnIqkGabEYVfsbpJ1fAzuiH/lwUj50tJk+mHaWHDpm1Q7Qk4d/+pbWyQZ0K6144FfXSROFkK4qyn+ftayaK7o1hO6FIH7pntpbb8D7CsMdr7y1m74qrxCWSWwR3eHg8AXQoIwc29KrGOyUdPbbZRpF2TH7eBaMuTurytFGXKxaujcd+2BSiP platform@example.com"
    error_message = "The supplied public key must be installed."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.zones == toset(["1", "2", "3"]) && azurerm_linux_virtual_machine_scale_set.main.encryption_at_host_enabled
    error_message = "Zones and host encryption must be applied."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.main.upgrade_mode == "Automatic" && azurerm_linux_virtual_machine_scale_set.main.automatic_os_upgrade_policy[0].enable_automatic_os_upgrade
    error_message = "Automatic OS upgrades must be configured."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.main.network_interface[0].ip_configuration[0].public_ip_address) == 1
    error_message = "Instances must get public IPs when requested."
  }

  assert {
    condition     = !contains(keys(azurerm_network_security_rule.allow), "AllowSSH") && azurerm_network_security_rule.allow["AllowApplication"].destination_port_ranges == toset(["8443"])
    error_message = "SSH must be closed and only the requested application port opened."
  }

  assert {
    condition     = length(azurerm_monitor_autoscale_setting.vmss.notification) == 1 && length(azurerm_monitor_data_collection_rule_association.vmss) == 1
    error_message = "Notifications and the rule association must be created."
  }
}

run "rejects_open_ssh" {
  command = plan

  variables {
    ssh_allowed_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_allowed_cidrs]
}

run "rejects_inverted_instance_bounds" {
  command = plan

  variables {
    instances_min = 4
    instances_max = 2
  }

  expect_failures = [azurerm_linux_virtual_machine_scale_set.main]
}

run "rejects_non_rsa_key" {
  command = plan

  variables {
    ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample user@example.com"
  }

  expect_failures = [var.ssh_public_key]
}

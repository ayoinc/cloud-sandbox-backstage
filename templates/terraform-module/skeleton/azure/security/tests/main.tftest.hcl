mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }

  mock_data "azurerm_subscription" {
    defaults = {
      subscription_id = "44444444-4444-4444-4444-444444444444"
      display_name    = "Mock Subscription"
    }
  }
}

mock_provider "random" {}
mock_provider "time" {}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.tenant_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The vault must belong to the tenant of the current client."
  }

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled && azurerm_key_vault.main.purge_protection_enabled
    error_message = "RBAC authorization and purge protection must be on by default."
  }

  assert {
    condition     = azurerm_key_vault.main.network_acls[0].default_action == "Deny" && azurerm_key_vault.main.network_acls[0].bypass == "AzureServices"
    error_message = "The vault firewall must deny by default."
  }

  assert {
    condition     = length(azurerm_role_assignment.terraform_key_vault_admin) == 1 && length(azurerm_role_assignment.identity_key_vault_crypto_user) == 1 && length(azurerm_role_assignment.identity_key_vault_secrets_user) == 1
    error_message = "RBAC mode must create the three role assignments."
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.terraform) == 0 && length(azurerm_key_vault_access_policy.identity) == 0
    error_message = "RBAC mode must not create access policies."
  }

  assert {
    condition     = length(azurerm_key_vault_key.encryption) == 0 && length(time_sleep.rbac_propagation) == 0 && output.encryption_key_name == null
    error_message = "No encryption key is created by default."
  }

  assert {
    condition     = azurerm_log_analytics_workspace.security.name == "demo-platform-services-dev-security-logs" && azurerm_log_analytics_workspace.security.retention_in_days == 90
    error_message = "The security log workspace must use the derived name and 90 day retention."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.key_vault.enabled_log) == 2
    error_message = "Vault audit and policy logs must be collected."
  }

  assert {
    condition     = length(azurerm_security_center_subscription_pricing.defender) == 0 && length(azurerm_application_insights.main) == 0
    error_message = "Defender and Application Insights are off by default."
  }
}

run "encryption_key_with_rbac" {
  command = plan

  variables {
    create_encryption_key = true
    encryption_key_size   = 4096
    network_acls = {
      ip_rules = ["203.0.113.10/32"]
    }
  }

  assert {
    condition     = azurerm_key_vault_key.encryption[0].key_type == "RSA" && azurerm_key_vault_key.encryption[0].key_size == 4096
    error_message = "An RSA 4096 key must be planned."
  }

  assert {
    condition     = azurerm_key_vault_key.encryption[0].rotation_policy[0].expire_after == "P365D" && azurerm_key_vault_key.encryption[0].rotation_policy[0].automatic[0].time_before_expiry == "P30D"
    error_message = "The key must rotate automatically before it expires."
  }

  assert {
    condition     = time_sleep.rbac_propagation[0].create_duration == "90s"
    error_message = "Key creation must wait for the role assignment to propagate."
  }

  assert {
    condition     = azurerm_key_vault.main.network_acls[0].ip_rules == toset(["203.0.113.10/32"])
    error_message = "The firewall must admit the listed address."
  }
}

run "access_policies_and_ec_key" {
  command = plan

  variables {
    enable_rbac_authorization = false
    create_encryption_key     = true
    encryption_key_type       = "EC"
    encryption_key_curve      = "P-384"
    network_acls = {
      ip_rules = ["203.0.113.10/32"]
    }
  }

  assert {
    condition     = length(azurerm_key_vault_access_policy.terraform) == 1 && length(azurerm_key_vault_access_policy.identity) == 1
    error_message = "Access policy mode must create both policies."
  }

  assert {
    condition     = azurerm_key_vault_access_policy.terraform[0].object_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The Terraform policy must target the current client."
  }

  assert {
    condition     = length(azurerm_role_assignment.terraform_key_vault_admin) == 0 && length(time_sleep.rbac_propagation) == 0
    error_message = "Access policy mode must not create role assignments."
  }

  assert {
    condition     = azurerm_key_vault_key.encryption[0].curve == "P-384" && azurerm_key_vault_key.encryption[0].key_opts == tolist(["sign", "verify"])
    error_message = "An EC P-384 signing key must be planned."
  }
}

run "defender_and_application_insights" {
  command = plan

  variables {
    enable_defender             = true
    defender_resource_types     = ["KeyVaults", "Containers"]
    enable_application_insights = true
  }

  assert {
    condition     = sort(keys(azurerm_security_center_subscription_pricing.defender)) == tolist(["Containers", "KeyVaults"])
    error_message = "Defender must cover exactly the requested resource types."
  }

  assert {
    condition     = azurerm_application_insights.main[0].local_authentication_enabled == false && azurerm_application_insights.main[0].ip_masking_enabled
    error_message = "Application Insights must disable local authentication and mask IPs by default."
  }
}

run "rejects_key_behind_closed_firewall" {
  command = plan

  variables {
    create_encryption_key = true
  }

  expect_failures = [azurerm_key_vault_key.encryption]
}

run "rejects_hsm_key_on_standard_vault" {
  command = plan

  variables {
    create_encryption_key = true
    encryption_key_type   = "RSA-HSM"
    network_acls = {
      ip_rules = ["203.0.113.10/32"]
    }
  }

  expect_failures = [azurerm_key_vault_key.encryption]
}

# Runs with `tofu test`. The provider is mocked, so no cloud account,
# credentials or state bucket are needed and nothing is created.

{%- if values.cloud == 'aws' %}
mock_provider "aws" {}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "123456789012"
  }
}

override_data {
  target = data.aws_partition.current
  values = {
    partition = "aws"
  }
}

override_data {
  target = data.aws_availability_zones.available
  values = {
    names = ["${{ values.region }}a", "${{ values.region }}b", "${{ values.region }}c"]
  }
}

override_resource {
  target = aws_vpc.main
  values = {
    arn = "arn:aws:ec2:${{ values.region }}:123456789012:vpc/vpc-0123456789abcdef0"
  }
}

variables {
  environment      = "dev"
  network_cidr     = "10.10.0.0/20"
  state_bucket     = "unused-in-tests"
  state_kms_key_id = "unused-in-tests"
}

run "dev_defaults" {
  command = plan

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "dev should span two availability zones."
  }

  assert {
    condition     = alltrue([for subnet in aws_subnet.private : !subnet.map_public_ip_on_launch])
    error_message = "Private subnets must not assign public addresses."
  }

  assert {
    condition     = aws_s3_bucket.logs.bucket == "${{ values.name }}-dev-logs-123456789012"
    error_message = "The log bucket name should end in the account ID."
  }

  assert {
    condition     = aws_s3_bucket.logs.force_destroy
    error_message = "Outside prod the log bucket may be destroyed with its contents."
  }

  assert {
    condition     = aws_flow_log.main.log_destination == "arn:aws:s3:::${{ values.name }}-dev-logs-123456789012/vpc-flow-logs/"
    error_message = "Flow logs should be delivered to the log bucket."
  }

  assert {
    condition     = aws_kms_key.logs.enable_key_rotation
    error_message = "The log key must rotate."
  }
}

run "prod_is_protected" {
  command = plan

  variables {
    environment             = "prod"
    availability_zone_count = 3
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "prod should span three availability zones."
  }

  assert {
    condition     = !aws_s3_bucket.logs.force_destroy
    error_message = "The prod log bucket must not be destroyable while it holds objects."
  }
}

run "flow_logs_can_be_switched_off" {
  command = plan

  variables {
    enable_flow_logs = false
  }

  assert {
    condition     = aws_flow_log.main == null
    error_message = "No flow log should be planned when enable_flow_logs is false."
  }
}

run "bucket_is_private_and_encrypted" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.logs.block_public_acls,
      aws_s3_bucket_public_access_block.logs.block_public_policy,
      aws_s3_bucket_public_access_block.logs.ignore_public_acls,
      aws_s3_bucket_public_access_block.logs.restrict_public_buckets,
    ])
    error_message = "All four public access blocks must be on."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.logs.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "The log bucket must be encrypted with the customer managed key."
  }

  assert {
    condition     = output.account_id == "123456789012"
    error_message = "The account ID should be parsed from the ARN of the VPC."
  }
}

run "rejects_an_oversized_network" {
  command = plan

  variables {
    network_cidr = "10.0.0.0/8"
  }

  expect_failures = [var.network_cidr]
}

run "rejects_an_unknown_environment" {
  command = plan

  variables {
    environment = "sandbox"
  }

  expect_failures = [var.environment]
}
{%- elif values.cloud == 'azure' %}
mock_provider "azurerm" {}

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
}

override_resource {
  target = azurerm_resource_group.main
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-${{ values.name }}-dev"
  }
}

# Azure resources validate the IDs they are given, so the mocked resources
# that others refer to get well-formed ones.
override_resource {
  target = azurerm_network_security_group.private
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-${{ values.name }}-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-${{ values.name }}-dev-private"
  }
}

override_resource {
  target = azurerm_subnet.private
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-${{ values.name }}-dev/providers/Microsoft.Network/virtualNetworks/vnet-${{ values.name }}-dev/subnets/snet-private"
  }
}

override_resource {
  target = azurerm_storage_account.logs
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-${{ values.name }}-dev/providers/Microsoft.Storage/storageAccounts/stsampledev"
  }
}

variables {
  environment           = "dev"
  network_cidr          = "10.10.0.0/20"
  state_storage_account = "unused"
  state_key_vault_uri   = "https://unused.vault.azure.net"
}

run "dev_defaults" {
  command = plan

  assert {
    condition     = azurerm_resource_group.main.name == "rg-${{ values.name }}-dev"
    error_message = "The resource group should be named after the stack and the environment."
  }

  assert {
    condition     = can(regex("^st[a-z0-9]{5,22}$", azurerm_storage_account.logs.name))
    error_message = "The storage account name must be 3 to 24 lowercase letters and digits."
  }

  assert {
    condition     = azurerm_storage_account.logs.account_replication_type == "LRS"
    error_message = "Outside prod the log storage is locally redundant."
  }

  assert {
    condition     = azurerm_management_lock.main == null
    error_message = "No lock should be planned unless lock_resource_group is true."
  }

  assert {
    condition     = !azurerm_subnet.private.default_outbound_access_enabled
    error_message = "The private subnet must not have default outbound access."
  }
}

run "storage_is_private" {
  command = plan

  assert {
    condition = alltrue([
      !azurerm_storage_account.logs.allow_nested_items_to_be_public,
      !azurerm_storage_account.logs.shared_access_key_enabled,
      azurerm_storage_account.logs.https_traffic_only_enabled,
      azurerm_storage_account.logs.infrastructure_encryption_enabled,
      azurerm_storage_account.logs.min_tls_version == "TLS1_2",
    ])
    error_message = "The log storage account must refuse public access, shared keys and old TLS versions."
  }

  assert {
    condition     = one(azurerm_storage_account.logs.network_rules).default_action == "Deny"
    error_message = "The storage firewall must deny by default."
  }
}

run "prod_is_protected" {
  command = plan

  variables {
    environment         = "prod"
    lock_resource_group = true
  }

  assert {
    condition     = azurerm_storage_account.logs.account_replication_type == "GRS"
    error_message = "The prod log storage should be geo-redundant."
  }

  assert {
    condition     = azurerm_management_lock.main.lock_level == "CanNotDelete"
    error_message = "The prod resource group should be locked against deletion."
  }
}

run "outputs" {
  command = apply

  assert {
    condition     = output.subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "The subscription should be parsed from the ID of the resource group."
  }
}

run "rejects_an_oversized_network" {
  command = plan

  variables {
    network_cidr = "10.0.0.0/8"
  }

  expect_failures = [var.network_cidr]
}

run "rejects_an_unknown_environment" {
  command = plan

  variables {
    environment = "sandbox"
  }

  expect_failures = [var.environment]
}
{%- else %}
mock_provider "google" {}

override_data {
  target = data.google_storage_project_service_account.current
  values = {
    member = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
  }
}

override_resource {
  target = google_compute_network.main
  values = {
    id = "projects/sample-project/global/networks/${{ values.name }}-dev"
  }
}

variables {
  project_id    = "sample-project"
  environment   = "dev"
  network_cidr  = "10.10.0.0/20"
  state_bucket  = "unused-in-tests"
  state_kms_key = "unused-in-tests"
}

run "dev_defaults" {
  command = plan

  assert {
    condition     = !google_compute_network.main.auto_create_subnetworks
    error_message = "The network must not create subnets in every region."
  }

  assert {
    condition     = google_compute_subnetwork.private.private_ip_google_access
    error_message = "The private subnet should reach Google APIs without public addresses."
  }

  assert {
    condition     = google_storage_bucket.logs.name == "sample-project-${{ values.name }}-dev-logs"
    error_message = "The log bucket name should start with the project ID."
  }

  assert {
    condition     = google_storage_bucket.logs.force_destroy
    error_message = "Outside prod the log bucket may be destroyed with its contents."
  }

  assert {
    condition     = google_compute_router_nat.main == null
    error_message = "No NAT gateway should be planned unless enable_nat is true."
  }
}

run "bucket_is_private_and_encrypted" {
  command = plan

  assert {
    condition     = google_storage_bucket.logs.uniform_bucket_level_access && google_storage_bucket.logs.public_access_prevention == "enforced"
    error_message = "The log bucket must enforce uniform access and public access prevention."
  }

  assert {
    condition     = google_kms_crypto_key.logs.rotation_period == "7776000s"
    error_message = "The log key should rotate every 90 days."
  }
}

run "prod_is_protected" {
  command = plan

  variables {
    environment = "prod"
    enable_nat  = true
  }

  assert {
    condition     = !google_storage_bucket.logs.force_destroy
    error_message = "The prod log bucket must not be destroyable while it holds objects."
  }

  assert {
    condition     = google_compute_router_nat.main.nat_ip_allocate_option == "AUTO_ONLY"
    error_message = "A NAT gateway should be planned when enable_nat is true."
  }
}

run "outputs" {
  command = apply

  assert {
    condition     = output.project_id == "sample-project" && output.network_name == "${{ values.name }}-dev"
    error_message = "The project and the network name should be parsed from the ID of the network."
  }
}

run "rejects_an_oversized_network" {
  command = plan

  variables {
    network_cidr = "10.0.0.0/8"
  }

  expect_failures = [var.network_cidr]
}

run "rejects_an_unknown_environment" {
  command = plan

  variables {
    environment = "sandbox"
  }

  expect_failures = [var.environment]
}
{%- endif %}

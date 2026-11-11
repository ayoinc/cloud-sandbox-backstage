# Runs with `tofu test`. The provider is mocked: no credentials are needed and
# nothing is created.

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

variables {
  name        = "sample-dev"
  kms_key_arn = "arn:aws:kms:${{ values.region }}:123456789012:key/00000000-0000-0000-0000-000000000000"
}

run "bucket_is_private_and_encrypted" {
  command = plan

  assert {
    condition     = aws_s3_bucket.logs.bucket == "sample-dev-logs-123456789012"
    error_message = "The bucket name should end in the account ID."
  }

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
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.logs.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.kms_key_arn
    error_message = "The bucket must be encrypted with the key of the foundation unit."
  }

  assert {
    condition     = !aws_s3_bucket.logs.force_destroy
    error_message = "The bucket must not be destroyable by default."
  }
}

run "rejects_short_retention" {
  command = plan

  variables {
    log_retention_days = 7
  }

  expect_failures = [var.log_retention_days]
}
{%- elif values.cloud == 'azure' %}
mock_provider "azurerm" {}

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
}

# The container validates the ID of its storage account, so the mocked account
# gets a well-formed one.
override_resource {
  target = azurerm_storage_account.logs
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sample-dev/providers/Microsoft.Storage/storageAccounts/stsampledev"
  }
}

variables {
  name                = "sample-dev"
  environment         = "dev"
  region              = "${{ values.region }}"
  resource_group_name = "rg-sample-dev"
}

run "storage_is_private" {
  command = plan

  assert {
    condition     = can(regex("^st[a-z0-9]{5,22}$", azurerm_storage_account.logs.name))
    error_message = "The storage account name must be 3 to 24 lowercase letters and digits."
  }

  assert {
    condition = alltrue([
      !azurerm_storage_account.logs.allow_nested_items_to_be_public,
      !azurerm_storage_account.logs.shared_access_key_enabled,
      azurerm_storage_account.logs.https_traffic_only_enabled,
      azurerm_storage_account.logs.min_tls_version == "TLS1_2",
    ])
    error_message = "The storage account must refuse public access, shared keys and old TLS versions."
  }

  assert {
    condition     = azurerm_storage_account.logs.account_replication_type == "LRS"
    error_message = "Outside prod the storage is locally redundant."
  }

  assert {
    condition     = one(azurerm_storage_account.logs.network_rules).default_action == "Deny"
    error_message = "The storage firewall must deny by default."
  }
}

run "prod_is_geo_redundant" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition     = azurerm_storage_account.logs.account_replication_type == "GRS"
    error_message = "The prod storage should be geo-redundant."
  }
}

run "rejects_short_retention" {
  command = plan

  variables {
    log_retention_days = 7
  }

  expect_failures = [var.log_retention_days]
}
{%- else %}
mock_provider "google" {}

override_data {
  target = data.google_client_config.current
  values = {
    project = "sample-project"
  }
}

variables {
  name       = "sample-dev"
  region     = "${{ values.region }}"
  kms_key_id = "projects/sample-project/locations/${{ values.region }}/keyRings/sample-dev/cryptoKeys/logs"
}

run "bucket_is_private_and_encrypted" {
  command = plan

  assert {
    condition     = google_storage_bucket.logs.name == "sample-project-sample-dev-logs"
    error_message = "The bucket name should start with the project ID."
  }

  assert {
    condition     = google_storage_bucket.logs.uniform_bucket_level_access && google_storage_bucket.logs.public_access_prevention == "enforced"
    error_message = "The bucket must enforce uniform access and public access prevention."
  }

  assert {
    condition     = one(google_storage_bucket.logs.encryption).default_kms_key_name == var.kms_key_id
    error_message = "The bucket must be encrypted with the key of the foundation unit."
  }

  assert {
    condition     = !google_storage_bucket.logs.force_destroy
    error_message = "The bucket must not be destroyable by default."
  }
}

run "rejects_short_retention" {
  command = plan

  variables {
    log_retention_days = 7
  }

  expect_failures = [var.log_retention_days]
}
{%- endif %}

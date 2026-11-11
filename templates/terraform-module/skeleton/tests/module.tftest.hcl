{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# Plan-only tests against mocked providers: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test
{%- if aws %}

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

mock_provider "archive" {}
{%- endif %}
{%- if azure %}

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
      id              = "/subscriptions/44444444-4444-4444-4444-444444444444"
      subscription_id = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "tls" {}
mock_provider "time" {}
{%- endif %}
{%- if gcp %}

mock_provider "google" {}
{%- endif %}

mock_provider "random" {}

variables {
  project_name = "example"
  environment  = "dev"
{%- if gcp %}

  gcp_project_id = "example-project"
{%- endif %}

  enable_network       = true
  enable_security      = true
  enable_storage       = true
  enable_observability = true
  enable_compute       = false
  enable_database      = false
  enable_kubernetes    = false
  enable_serverless    = false
}

run "default_building_blocks" {
  command = plan

  assert {
    condition     = output.project_name == "example" && output.environment == "dev"
    error_message = "The module reports the project and environment it was given."
  }
{%- if aws %}

  assert {
    condition     = length(module.aws_network) == 1 && length(module.aws_security) == 1 && length(module.aws_storage) == 1 && length(module.aws_observability) == 1
    error_message = "Network, security, storage and observability are created by default on AWS."
  }

  assert {
    condition     = length(module.aws_compute) == 0 && length(module.aws_database) == 0 && length(module.aws_kubernetes) == 0 && length(module.aws_serverless) == 0
    error_message = "Compute, database, Kubernetes and serverless are off by default on AWS."
  }
{%- endif %}
{%- if azure %}

  assert {
    condition     = azurerm_resource_group.main.name == "example-dev-rg"
    error_message = "The Azure resource group is named after project and environment."
  }

  assert {
    condition     = length(module.azure_network) == 1 && length(module.azure_security) == 1 && length(module.azure_storage) == 1 && length(module.azure_observability) == 1
    error_message = "Network, security, storage and observability are created by default on Azure."
  }

  assert {
    condition     = length(module.azure_compute) == 0 && length(module.azure_database) == 0 && length(module.azure_kubernetes) == 0 && length(module.azure_serverless) == 0
    error_message = "Compute, database, Kubernetes and serverless are off by default on Azure."
  }
{%- endif %}
{%- if gcp %}

  assert {
    condition     = length(module.gcp_network) == 1 && length(module.gcp_security) == 1 && length(module.gcp_storage) == 1 && length(module.gcp_observability) == 1
    error_message = "Network, security, storage and observability are created by default on Google Cloud."
  }

  assert {
    condition     = length(module.gcp_compute) == 0 && length(module.gcp_database) == 0 && length(module.gcp_kubernetes) == 0 && length(module.gcp_serverless) == 0
    error_message = "Compute, database, Kubernetes and serverless are off by default on Google Cloud."
  }

  assert {
    condition     = contains(keys(google_project_service.this), "compute.googleapis.com") && !contains(keys(google_project_service.this), "container.googleapis.com")
    error_message = "Only the APIs of the enabled building blocks are switched on."
  }
{%- endif %}
}

run "every_building_block" {
  command = plan

  variables {
    environment       = "prod"
    enable_compute    = true
    enable_database   = true
    enable_kubernetes = true
    enable_serverless = true
{%- if azure %}

    azure_resource_group_name = "custom-rg"
{%- endif %}
  }
{%- if aws %}

  assert {
    condition     = length(module.aws_compute) == 1 && length(module.aws_database) == 1 && length(module.aws_kubernetes) == 1 && length(module.aws_serverless) == 1
    error_message = "Every AWS building block must plan when switched on."
  }
{%- endif %}
{%- if azure %}

  assert {
    condition     = azurerm_resource_group.main.name == "custom-rg"
    error_message = "azure_resource_group_name overrides the derived name."
  }

  assert {
    condition     = length(module.azure_compute) == 1 && length(module.azure_database) == 1 && length(module.azure_kubernetes) == 1 && length(module.azure_serverless) == 1
    error_message = "Every Azure building block must plan when switched on."
  }
{%- endif %}
{%- if gcp %}

  assert {
    condition     = length(module.gcp_compute) == 1 && length(module.gcp_database) == 1 && length(module.gcp_kubernetes) == 1 && length(module.gcp_serverless) == 1
    error_message = "Every Google Cloud building block must plan when switched on."
  }

  assert {
    condition     = contains(keys(google_project_service.this), "container.googleapis.com") && contains(keys(google_project_service.this), "sqladmin.googleapis.com")
    error_message = "The APIs of the enabled building blocks are switched on."
  }
{%- endif %}
}

run "nothing_enabled" {
  command = plan

  variables {
    enable_network       = false
    enable_security      = false
    enable_storage       = false
    enable_observability = false
  }
{%- if aws %}

  assert {
    condition     = output.aws_vpc_id == null && output.aws_bucket_name == null && length(output.aws_private_subnet_ids) == 0
    error_message = "AWS outputs of building blocks that are off must be empty."
  }
{%- endif %}
{%- if azure %}

  assert {
    condition     = output.azure_vnet_id == null && output.azure_storage_account_name == null
    error_message = "Azure outputs of building blocks that are off must be null."
  }
{%- endif %}
{%- if gcp %}

  assert {
    condition     = output.gcp_network_name == null && output.gcp_bucket_name == null
    error_message = "Google Cloud outputs of building blocks that are off must be null."
  }
{%- endif %}
}

run "compute_needs_the_network" {
  command = plan

  variables {
    enable_network = false
    enable_compute = true
  }

  expect_failures = [var.enable_compute]
}

run "database_needs_the_network" {
  command = plan

  variables {
    enable_network  = false
    enable_database = true
  }

  expect_failures = [var.enable_database]
}

run "kubernetes_needs_the_network" {
  command = plan

  variables {
    enable_network    = false
    enable_kubernetes = true
  }

  expect_failures = [var.enable_kubernetes]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

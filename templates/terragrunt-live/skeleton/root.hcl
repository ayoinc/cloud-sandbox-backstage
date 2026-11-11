# Root configuration, included by every unit.
#
# It reads where the unit sits in live/<environment>/<region>/ and from that
# generates the remote state backend and the provider, so no unit repeats them.

locals {
  project = "${{ values.name }}"
  owner   = "${{ values.owner | replace('group:', '') | replace('user:', '') | replace('default/', '') }}"

  env    = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
  region = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals.region

  tags = {
    project     = local.project
    environment = local.env.environment
    owner       = local.owner
    managed-by  = "terragrunt"
  }

  # One state object per unit, keyed by its path in the repository:
  # live/dev/${{ values.region }}/storage
  state_key = replace(path_relative_to_include(), "/.terragrunt-stack", "")
}

# `--feature offline=true` swaps the remote backend for a local one, so the
# units can be validated without credentials or a state bucket. The pipeline
# uses it for the checks that run before sign-in.
feature "offline" {
  default = false
}
{%- if values.cloud == 'aws' %}

# The state bucket differs per AWS account, so it comes from the environment:
# the pipeline sets STATE_BUCKET from the GitHub environment it runs in.
remote_state {
  backend = feature.offline.value ? "local" : "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    local = {}
    s3 = {
      bucket       = get_env("STATE_BUCKET", "")
      key          = "${local.state_key}/tofu.tfstate"
      region       = get_env("STATE_REGION", local.region)
      encrypt      = true
      use_lockfile = true
    }
  }[feature.offline.value ? "local" : "s3"]
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"

      default_tags {
        tags = ${jsonencode(local.tags)}
      }
    }
  EOF
}

inputs = {
  environment = local.env.environment
  region      = local.region
  tags        = local.tags
}
{%- elif values.cloud == 'azure' %}

# The state storage account differs per subscription, so it comes from the
# environment: the pipeline sets STATE_STORAGE_ACCOUNT from the GitHub
# environment it runs in.
remote_state {
  backend = feature.offline.value ? "local" : "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    local = {}
    azurerm = {
      storage_account_name = get_env("STATE_STORAGE_ACCOUNT", "")
      container_name       = get_env("STATE_CONTAINER", "tfstate")
      key                  = "${local.state_key}/tofu.tfstate"
      use_azuread_auth     = true
    }
  }[feature.offline.value ? "local" : "azurerm"]
}

# The subscription comes from ARM_SUBSCRIPTION_ID, or from the Azure CLI when
# run locally.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "azurerm" {
      storage_use_azuread = true

      features {}
    }
  EOF
}

inputs = {
  environment = local.env.environment
  region      = local.region
  tags        = local.tags
}
{%- else %}

# The project and the state bucket differ per environment, so they come from
# the environment: the pipeline sets GOOGLE_PROJECT, which the provider reads,
# and STATE_BUCKET from the GitHub environment it runs in.
remote_state {
  backend = feature.offline.value ? "local" : "gcs"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    local = {}
    gcs = {
      bucket = get_env("STATE_BUCKET", "")
      prefix = local.state_key
    }
  }[feature.offline.value ? "local" : "gcs"]
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "google" {
      region = "${local.region}"

      default_labels = ${jsonencode(local.tags)}
    }
  EOF
}

inputs = {
  environment = local.env.environment
  region      = local.region
  tags        = local.tags
}
{%- endif %}

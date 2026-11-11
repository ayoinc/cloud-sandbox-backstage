# Client-side encryption of state and plan files. OpenTofu encrypts them with a
# data key issued by the cloud key service before they leave the machine, so
# the state bucket, its replicas and any uploaded plan artifact only ever hold
# ciphertext. `enforced = true` makes OpenTofu refuse to read or write
# unencrypted state.
#
# To rotate to a new key, add a second key_provider and method, point `state`
# and `plan` at it and name the old method in a `fallback` block until every
# environment has been applied once.
{%- if values.cloud == 'aws' %}
terraform {
  encryption {
    key_provider "aws_kms" "state" {
      kms_key_id = var.state_kms_key_id
      region     = var.state_region
      key_spec   = "AES_256"

      encryption_context = {
        Stack       = var.name
        Environment = var.environment
      }
    }

    method "aes_gcm" "state" {
      keys = key_provider.aws_kms.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
{%- elif values.cloud == 'azure' %}
terraform {
  encryption {
    key_provider "azure_vault" "state" {
      vault_uri      = var.state_key_vault_uri
      vault_key_name = var.state_key_name
      key_length     = 32
    }

    method "aes_gcm" "state" {
      keys = key_provider.azure_vault.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
{%- else %}
terraform {
  encryption {
    key_provider "gcp_kms" "state" {
      kms_encryption_key = var.state_kms_key
      key_length         = 32
    }

    method "aes_gcm" "state" {
      keys = key_provider.gcp_kms.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
{%- endif %}

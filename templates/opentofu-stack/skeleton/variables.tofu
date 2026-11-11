variable "name" {
  description = "Name of the stack; prefix of every resource name."
  type        = string
  default     = "${{ values.name }}"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,22}[a-z0-9]$", var.name))
    error_message = "The name must be 2 to 24 lowercase letters, numbers and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment this run deploys: dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "owner" {
  description = "Team that owns the stack; recorded on every resource."
  type        = string
  default     = "${{ values.owner | replace('group:', '') | replace('user:', '') | replace('default/', '') }}"
}

variable "network_cidr" {
  description = "IPv4 range of the network, between /16 and /24."
  type        = string

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && tonumber(split("/", var.network_cidr)[1]) >= 16 && tonumber(split("/", var.network_cidr)[1]) <= 24
    error_message = "The network range must be a valid IPv4 CIDR block between /16 and /24."
  }
}

variable "log_retention_days" {
  description = "Days that log objects are kept before they are deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Logs must be kept for at least 30 days."
  }
}
{%- if values.cloud == 'aws' %}

variable "region" {
  description = "AWS region the stack is deployed to."
  type        = string
  default     = "${{ values.region }}"
}

variable "availability_zone_count" {
  description = "Number of availability zones the private subnets span."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 4
    error_message = "Use between 2 and 4 availability zones."
  }
}

variable "enable_flow_logs" {
  description = "Deliver VPC flow logs to the log bucket."
  type        = bool
  default     = true
}

# State settings. These are read while the backend and the encryption block are
# initialised, so they can only come from -var, -var-file or TF_VAR_* values.

variable "state_bucket" {
  description = "S3 bucket that holds the state."
  type        = string
}

variable "state_region" {
  description = "Region of the state bucket and of the state encryption key."
  type        = string
  default     = "${{ values.region }}"
}

variable "state_kms_key_id" {
  description = "ARN of the KMS key that encrypts state and plan files."
  type        = string
}
{%- elif values.cloud == 'azure' %}

variable "region" {
  description = "Azure region the stack is deployed to."
  type        = string
  default     = "${{ values.region }}"
}

variable "lock_resource_group" {
  description = "Put a CanNotDelete lock on the resource group."
  type        = bool
  default     = false
}

# State settings. These are read while the backend and the encryption block are
# initialised, so they can only come from -var, -var-file or TF_VAR_* values.

variable "state_storage_account" {
  description = "Storage account that holds the state."
  type        = string
}

variable "state_container" {
  description = "Blob container that holds the state."
  type        = string
  default     = "tfstate"
}

variable "state_key_vault_uri" {
  description = "URI of the Key Vault that holds the state encryption key, for example https://kv-tofu-state.vault.azure.net."
  type        = string
}

variable "state_key_name" {
  description = "Name of the RSA key in the Key Vault that wraps the state encryption key."
  type        = string
  default     = "tofu-state"
}
{%- else %}

variable "project_id" {
  description = "Google Cloud project the stack is deployed to."
  type        = string
}

variable "region" {
  description = "Google Cloud region the stack is deployed to."
  type        = string
  default     = "${{ values.region }}"
}

variable "enable_nat" {
  description = "Create a Cloud NAT gateway so private instances can reach the internet."
  type        = bool
  default     = false
}

# State settings. These are read while the backend and the encryption block are
# initialised, so they can only come from -var, -var-file or TF_VAR_* values.

variable "state_bucket" {
  description = "Cloud Storage bucket that holds the state."
  type        = string
}

variable "state_kms_key" {
  description = "Resource name of the Cloud KMS key that encrypts state and plan files: projects/<project>/locations/<location>/keyRings/<ring>/cryptoKeys/<key>."
  type        = string
}
{%- endif %}

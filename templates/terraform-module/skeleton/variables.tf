{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
variable "project_name" {
  description = "Project name; prefixes every resource name. Lowercase letters, digits and hyphens, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3 to 40 lowercase letters, digits and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name: dev, staging or prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Feature flags
# -----------------------------------------------------------------------------

variable "enable_network" {
  description = "Create the network."
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Create the encryption key, secret store and identities."
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Create object storage."
  type        = bool
  default     = true
}

variable "enable_observability" {
  description = "Create the log destination, dashboard and alerts."
  type        = bool
  default     = true
}

variable "enable_compute" {
  description = "Create the virtual machine group. Needs enable_network."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_compute || var.enable_network
    error_message = "enable_compute needs enable_network = true: the machines run in the network this module creates."
  }
}

variable "enable_database" {
  description = "Create the managed database. Needs enable_network."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_database || var.enable_network
    error_message = "enable_database needs enable_network = true: the database is reachable only inside the network this module creates."
  }
}

variable "enable_kubernetes" {
  description = "Create the managed Kubernetes cluster. Needs enable_network."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_kubernetes || var.enable_network
    error_message = "enable_kubernetes needs enable_network = true: the nodes run in the network this module creates."
  }
}

variable "enable_serverless" {
  description = "Create the serverless function or service."
  type        = bool
  default     = false
}
{%- if aws %}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

variable "aws_vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_availability_zones" {
  description = "Availability zones for the subnets. Empty uses the first three zones of the provider's region."
  type        = list(string)
  default     = []
}
{%- endif %}
{%- if azure %}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------

variable "azure_location" {
  description = "Azure location for all resources."
  type        = string
  default     = "eastus2"
}

variable "azure_resource_group_name" {
  description = "Name of the resource group the module creates. Null derives it from project_name and environment."
  type        = string
  default     = null
}

variable "azure_vnet_cidr" {
  description = "Address space of the virtual network."
  type        = string
  default     = "10.1.0.0/16"
}
{%- endif %}
{%- if gcp %}

# -----------------------------------------------------------------------------
# Google Cloud
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "ID of the Google Cloud project the resources are created in."
  type        = string
}

variable "gcp_region" {
  description = "Region for regional resources."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Zone for zonal resources. Null uses zone a of gcp_region."
  type        = string
  default     = null
}

variable "gcp_network_cidr" {
  description = "Address range of the VPC network."
  type        = string
  default     = "10.2.0.0/16"
}

variable "gcp_enable_apis" {
  description = "Enable the Google Cloud APIs the selected features need. Set to false when the APIs are managed elsewhere."
  type        = bool
  default     = true
}
{%- endif %}

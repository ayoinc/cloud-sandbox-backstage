{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
variable "project_name" {
  description = "Project name; prefixes every resource name."
  type        = string
  default     = "example"
}

variable "environment" {
  description = "Environment name: dev, staging or prod."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags for all resources."
  type        = map(string)
  default     = {}
}
{%- if aws %}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}
{%- endif %}
{%- if azure %}

variable "azure_location" {
  description = "Azure location."
  type        = string
  default     = "eastus2"
}
{%- endif %}
{%- if gcp %}

variable "gcp_project_id" {
  description = "ID of the Google Cloud project."
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region."
  type        = string
  default     = "us-central1"
}
{%- endif %}

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
  description = "Create the virtual machine group."
  type        = bool
  default     = false
}

variable "enable_database" {
  description = "Create the managed database."
  type        = bool
  default     = false
}

variable "enable_kubernetes" {
  description = "Create the managed Kubernetes cluster."
  type        = bool
  default     = false
}

variable "enable_serverless" {
  description = "Create the serverless function or service."
  type        = bool
  default     = false
}

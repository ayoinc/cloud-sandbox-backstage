variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "${{ values.projectName }}"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "Cloud region"
  type        = string
  {%- if values.cloudProvider == "aws" %}
  default     = "${{ values.awsRegion }}"
  {%- elif values.cloudProvider == "azure" %}
  default     = "${{ values.azureRegion }}"
  {%- else %}
  default     = "${{ values.gcpRegion }}"
  {%- endif %}
}

{%- if values.cloudProvider == "azure" %}
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "${{ values.azureSubscriptionId }}"
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "${{ values.gcpProjectId }}"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = ""
}

variable "subnetwork_name" {
  description = "Subnetwork name"
  type        = string
  default     = ""
}
{%- endif %}

{%- if values.cloudProvider == "aws" %}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
  default     = []
}
{%- endif %}

{%- if values.enableDataWarehouse %}
variable "warehouse_admin_username" {
  description = "Data warehouse admin username"
  type        = string
  default     = "admin"
}

variable "warehouse_admin_password" {
  description = "Data warehouse admin password"
  type        = string
  sensitive   = true
}
{%- endif %}

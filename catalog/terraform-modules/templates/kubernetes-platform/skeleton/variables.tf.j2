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
{%- endif %}

variable "vpc_cidr" {
  description = "CIDR block for VPC/VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "${{ values.kubernetesVersion }}"
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = ${{ values.nodePoolConfig.minNodes }}
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = ${{ values.nodePoolConfig.maxNodes }}
}

{%- if values.enableObservability %}
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}
{%- endif %}

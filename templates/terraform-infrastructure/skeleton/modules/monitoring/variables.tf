# Monitoring Module Variables

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for monitoring"
  type        = string
  default     = "monitoring"
}

variable "enable_grafana" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "enable_alertmanager" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "enable_ingress" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = false
}

variable "grafana_hosts" {
  description = "Hosts for Grafana ingress"
  type        = list(string)
  default     = []
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "metrics_retention_days" {
  description = "Metrics retention in days"
  type        = number
  default     = 15
}

variable "common_tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}

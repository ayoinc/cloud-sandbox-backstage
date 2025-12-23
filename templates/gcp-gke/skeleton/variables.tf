variable "name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the cluster purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "${{ values.region }}"
}

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  default     = "${{ values.gcpProject }}"
}

variable "cluster_mode" {
  description = "Cluster mode (autopilot or standard)"
  type        = string
  default     = "${{ values.clusterMode }}"
}

variable "machine_type" {
  description = "Machine type for nodes (standard mode only)"
  type        = string
  default     = "${{ values.machineType }}"
}

variable "node_count" {
  description = "Initial node count (standard mode only)"
  type        = number
  default     = ${{ values.nodeCount }}
}

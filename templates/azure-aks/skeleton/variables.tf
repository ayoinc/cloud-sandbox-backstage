variable "name" {
  description = "Name of the AKS cluster"
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

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "${{ values.location }}"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "${{ values.kubernetesVersion }}"
}

variable "node_vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "${{ values.nodeVmSize }}"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = ${{ values.nodeCount }}
}

variable "max_node_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = ${{ values.maxNodeCount }}
}

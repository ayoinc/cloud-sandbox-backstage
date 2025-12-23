variable "name" {
  description = "Name of the EKS cluster"
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
  description = "AWS Region"
  type        = string
  default     = "${{ values.region }}"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "${{ values.kubernetesVersion }}"
}

variable "node_instance_type" {
  description = "EC2 instance type for nodes"
  type        = string
  default     = "${{ values.nodeInstanceType }}"
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = ${{ values.nodeDesiredSize }}
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = ${{ values.nodeMaxSize }}
}

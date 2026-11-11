# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the project, used in the names of all resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,14}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 2 to 16 lowercase letters, digits and hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subscription_id" {
  description = "Subscription the resources are created in. null uses the subscription of the credentials Terraform runs with."
  type        = string
  default     = null
}

# --- Cluster ------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes minor version of the cluster, for example 1.36. AKS runs its latest patch release."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be a minor version such as 1.36."
  }
}

variable "node_min_count" {
  description = "Smallest number of nodes the cluster autoscaler keeps"
  type        = number

  validation {
    condition     = var.node_min_count >= 1 && floor(var.node_min_count) == var.node_min_count
    error_message = "node_min_count must be a whole number of at least 1."
  }
}

variable "node_max_count" {
  description = "Largest number of nodes the cluster autoscaler may add. A value below node_min_count counts as node_min_count."
  type        = number

  validation {
    condition     = var.node_max_count >= 1 && var.node_max_count <= 1000 && floor(var.node_max_count) == var.node_max_count
    error_message = "node_max_count must be a whole number between 1 and 1000."
  }
}

variable "node_size" {
  description = "Size of the nodes: small (2 vCPU, 4 GiB), medium (4 vCPU, 16 GiB) or large (8 vCPU, 32 GiB)"
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.node_size)
    error_message = "node_size must be small, medium or large."
  }
}

variable "availability_zones" {
  description = "Availability zones the nodes are spread over"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "cluster_admin_group_object_ids" {
  description = "Object IDs of the Microsoft Entra ID groups whose members are administrators of the cluster"
  type        = list(string)
  default     = []
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDR ranges that may reach the Kubernetes API server. Empty allows every address; the pipeline must stay inside the ranges."
  type        = list(string)
  default     = []
}

# --- Network ------------------------------------------------------------------

variable "vnet_cidr" {
  description = "Address space of the virtual network. The nodes use its first /20."
  type        = string
  default     = "10.40.0.0/16"
}

variable "pod_cidr" {
  description = "Address range of the pods (overlay network, not part of the virtual network)"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Address range of the Kubernetes services. Must not overlap vnet_cidr or pod_cidr."
  type        = string
  default     = "10.245.0.0/16"
}

# --- DNS ----------------------------------------------------------------------

variable "dns_zone_resource_group" {
  description = "Resource group, in the same subscription, that holds the Azure DNS zones external-dns manages. null uses the resource group of this stack."
  type        = string
  default     = null
}

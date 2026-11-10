# =============================================================================
# Azure Full Infrastructure - Variables
# =============================================================================
# Values come from environments/*.tfvars.
# =============================================================================

# -----------------------------------------------------------------------------
# Project
# -----------------------------------------------------------------------------

variable "name" {
  description = "Project name used in resource names"
  type        = string

  # Key Vault allows 24 characters for "kv-<name>-<environment>".
  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 13 && can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.name))
    error_message = "Name must be 3-13 characters: lowercase letters, digits and single hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "description" {
  description = "What this infrastructure is for"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Team that owns the infrastructure"
  type        = string
  default     = ""
}

variable "business_unit" {
  description = "Business unit that pays for the infrastructure"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
}

variable "secondary_location" {
  description = "Secondary Azure region, used for the container registry replica when disaster recovery is enabled"
  type        = string
}

variable "tags" {
  description = "Additional tags for every resource"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Modules
# -----------------------------------------------------------------------------

variable "enable_networking" {
  description = "Create the virtual network, subnets and network security groups"
  type        = bool
}

variable "enable_compute" {
  description = "Create Linux virtual machines (needs the networking module)"
  type        = bool
}

variable "enable_containers" {
  description = "Create the AKS cluster and the container registry"
  type        = bool
}

variable "enable_storage" {
  description = "Create the storage account"
  type        = bool
}

variable "enable_database" {
  description = "Create the PostgreSQL flexible server"
  type        = bool
}

variable "enable_security" {
  description = "Create the Key Vault"
  type        = bool
}

variable "enable_identity" {
  description = "Create the user-assigned managed identity"
  type        = bool
}

variable "enable_monitoring" {
  description = "Create the Log Analytics workspace and Application Insights"
  type        = bool
}

variable "enable_integration" {
  description = "Create the Service Bus namespace and the Event Grid topic"
  type        = bool
}

variable "enable_governance" {
  description = "Create the budget and the tag policies"
  type        = bool
}

# -----------------------------------------------------------------------------
# Resilience and Cost
# -----------------------------------------------------------------------------

variable "enable_dr" {
  description = "Disaster recovery: geo-redundant storage and database backups, and a registry replica in the secondary region"
  type        = bool
  default     = false
}

variable "enable_high_availability" {
  description = "High availability: zone-redundant storage, database standby, AKS nodes and virtual machines"
  type        = bool
  default     = false
}

variable "enable_auto_shutdown" {
  description = "Shut virtual machines down every day at auto_shutdown_time (never applied in prod)"
  type        = bool
  default     = false
}

variable "auto_shutdown_time" {
  description = "Daily shutdown time in UTC, as HHMM"
  type        = string
  default     = "1900"
}

variable "restrict_network_access" {
  description = "Limit Key Vault and storage access to the virtual network and allowed_ip_ranges. Terraform then needs a runner inside the network or its address in allowed_ip_ranges."
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Public IP addresses or CIDR ranges allowed to reach Key Vault and storage"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space of the virtual network (a /16 is expected; the subnets are carved out of it)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "The address space must be a valid CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for outbound traffic from the default, AKS and compute subnets"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Create an Azure Bastion host for access to the virtual machines"
  type        = bool
  default     = false
}

variable "enable_ddos_protection" {
  description = "Create a DDoS protection plan for the virtual network (billed monthly at a fixed price)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Containers
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version: a minor version (1.37), for which AKS selects the latest patch, or a full version"
  type        = string
  default     = "1.37"
}

variable "aks_node_vm_size" {
  description = "VM size of the AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_node_count" {
  description = "Initial number of AKS user nodes"
  type        = number
  default     = 2
}

variable "aks_min_node_count" {
  description = "Minimum number of AKS user nodes for the autoscaler"
  type        = number
  default     = 1
}

variable "aks_max_node_count" {
  description = "Maximum number of AKS user nodes for the autoscaler"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

variable "database_sku_name" {
  description = "PostgreSQL server SKU, for example B_Standard_B1ms or GP_Standard_D2s_v3"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "database_storage_mb" {
  description = "PostgreSQL storage size in MB"
  type        = number
  default     = 32768
}

# -----------------------------------------------------------------------------
# Compute
# -----------------------------------------------------------------------------

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "vm_count" {
  description = "Number of virtual machines"
  type        = number
  default     = 1
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the virtual machines (null generates a key pair)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Monitoring and Governance
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Days the Log Analytics workspace keeps its logs"
  type        = number
  default     = 30
}

variable "monthly_budget" {
  description = "Monthly budget of the primary resource group, in the billing currency"
  type        = number
  default     = 1000
}

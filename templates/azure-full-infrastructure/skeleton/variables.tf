# Environment
variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  type    = string
  default = "eastus"
}

# Networking
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    default = { address_prefixes = ["10.0.1.0/24"] }
    aks     = { address_prefixes = ["10.0.2.0/24"] }
    compute = { address_prefixes = ["10.0.3.0/24"] }
    data    = { address_prefixes = ["10.0.4.0/24"] }
  }
}

# Compute
variable "vm_config" {
  type = map(object({
    size  = string
    count = number
  }))
  default = {}
}

variable "app_service_sku" {
  type    = string
  default = "B1"
}

# Containers
variable "kubernetes_version" {
  type    = string
  default = "1.28"
}

variable "aks_node_pools" {
  type = map(object({
    vm_size    = string
    node_count = number
    min_count  = number
    max_count  = number
  }))
  default = {
    default = {
      vm_size    = "Standard_D2_v2"
      node_count = 2
      min_count  = 1
      max_count  = 5
    }
  }
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

# Storage
variable "storage_tier" {
  type    = string
  default = "Standard"
}

variable "storage_replication" {
  type    = string
  default = "LRS"
}

# Database
variable "sql_sku" {
  type    = string
  default = "S0"
}

variable "postgresql_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "redis_sku" {
  type    = string
  default = "Basic"
}

# Monitoring
variable "log_retention_days" {
  type    = number
  default = 30
}

# Integration
variable "service_bus_sku" {
  type    = string
  default = "Standard"
}

variable "apim_sku" {
  type    = string
  default = "Developer_1"
}

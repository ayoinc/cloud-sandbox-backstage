# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name)) && length(var.project_name) <= 16
    error_message = "project_name must be at most 16 lowercase letters, digits and hyphens, start with a letter and end with a letter or digit."
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

variable "vnet_address_space" {
  description = "Private address space of the virtual network. The subnets are carved out of it, so it must be /18 or larger."
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0)) && try(tonumber(split("/", var.vnet_address_space)[1]) <= 18, false)
    error_message = "vnet_address_space must be an IPv4 CIDR block of size /18 or larger."
  }
}

# --- Application tier ---------------------------------------------------------

variable "compute_type" {
  description = "How the application runs: aks, vmss or container-apps"
  type        = string

  validation {
    condition     = contains(["aks", "vmss", "container-apps"], var.compute_type)
    error_message = "compute_type must be aks, vmss or container-apps."
  }
}

variable "vm_size" {
  description = "Size of the AKS nodes or the scale set instances (aks and vmss)"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_-]*$", var.vm_size))
    error_message = "vm_size must be the name of a virtual machine size, such as Standard_D2s_v3."
  }
}

variable "min_nodes" {
  description = "Smallest number of AKS nodes, scale set instances or Container App replicas"
  type        = number

  validation {
    condition     = var.min_nodes >= 1 && var.min_nodes <= 100 && floor(var.min_nodes) == var.min_nodes
    error_message = "min_nodes must be a whole number between 1 and 100."
  }
}

variable "max_nodes" {
  description = "Largest number of AKS nodes, scale set instances or Container App replicas. min_nodes is used when this is below it."
  type        = number

  validation {
    condition     = var.max_nodes >= 1 && var.max_nodes <= 100 && floor(var.max_nodes) == var.max_nodes
    error_message = "max_nodes must be a whole number between 1 and 100."
  }
}

variable "cpu_target" {
  description = "Average CPU utilisation, in percent, above which the scale set adds an instance (vmss)"
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target >= 30 && var.cpu_target <= 90
    error_message = "cpu_target must be between 30 and 90."
  }
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path the Application Gateway requests to check the application"
  type        = string
  default     = "/"
}

variable "kubernetes_version" {
  description = "Kubernetes version of the AKS cluster. The default version of the region is used while this is null."
  type        = string
  default     = null
}

variable "kubernetes_pod_cidr" {
  description = "Address range of the pods in the AKS overlay network. While null, a range outside vnet_address_space is chosen."
  type        = string
  default     = null
}

variable "kubernetes_service_cidr" {
  description = "Address range of the Kubernetes services. While null, a range outside vnet_address_space is chosen."
  type        = string
  default     = null
}

variable "aks_authorized_ip_ranges" {
  description = "Public address ranges allowed to reach the Kubernetes API server. The cluster is private while this is empty."
  type        = list(string)
  default     = []
}

variable "aks_admin_group_object_ids" {
  description = "Object IDs of the Microsoft Entra groups that administer the AKS cluster"
  type        = list(string)
  default     = []
}

variable "vmss_admin_username" {
  description = "Administrator user of the scale set instances (vmss)"
  type        = string
  default     = "azureuser"
}

variable "vmss_admin_ssh_public_key" {
  description = "SSH public key of the administrator user. A key pair is generated and kept in the state while this is null."
  type        = string
  default     = null
}

variable "vmss_custom_data" {
  description = "cloud-init configuration of the scale set instances. The default installs nginx listening on app_port."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Container image of the application (container-apps)"
  type        = string
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "container_cpu" {
  description = "vCPUs of one Container App replica"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory of one Container App replica"
  type        = string
  default     = "1Gi"
}

variable "container_concurrent_requests" {
  description = "Concurrent requests per replica above which the Container App adds a replica"
  type        = number
  default     = 50
}

# --- Data tier ----------------------------------------------------------------

variable "database_type" {
  description = "Database service: sql-database, postgresql or cosmos-db"
  type        = string

  validation {
    condition     = contains(["sql-database", "postgresql", "cosmos-db"], var.database_type)
    error_message = "database_type must be sql-database, postgresql or cosmos-db."
  }
}

variable "database_sku" {
  description = "Azure SQL Database SKU (GP_Gen5_2, S0), PostgreSQL flexible server SKU (GP_Standard_D2s_v3, B_Standard_B1ms) or Cosmos DB capacity mode (serverless, autoscale)"
  type        = string

  validation {
    condition = (
      var.database_type == "sql-database" ? can(regex("^(Basic|S[0-9]+|P[0-9]+|(GP|BC|HS)(_S)?_[A-Za-z0-9]+_[0-9]+)$", var.database_sku)) :
      var.database_type == "postgresql" ? can(regex("^(B|GP|MO)_Standard_[A-Za-z0-9_]+$", var.database_sku)) :
      contains(["serverless", "autoscale"], var.database_sku)
    )
    error_message = "database_sku does not belong to database_type: use an Azure SQL Database SKU such as GP_Gen5_2 for sql-database, a flexible server SKU such as GP_Standard_D2s_v3 for postgresql, and serverless or autoscale for cosmos-db."
  }
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "app"
}

variable "database_admin_username" {
  description = "Administrator login of the SQL or PostgreSQL server. Its password is generated."
  type        = string
  default     = "dbadmin"
}

variable "database_storage_gb" {
  description = "Storage of the SQL database or the PostgreSQL server in GB"
  type        = number
  default     = 32

  validation {
    condition     = contains([32, 64, 128, 256, 512, 1024], var.database_storage_gb)
    error_message = "database_storage_gb must be 32, 64, 128, 256, 512 or 1024."
  }
}

variable "postgresql_version" {
  description = "Major version of the PostgreSQL flexible server"
  type        = string
  default     = "16"
}

variable "cosmos_max_throughput" {
  description = "Upper limit of the autoscaled throughput of the Cosmos DB database in RU/s (capacity mode autoscale)"
  type        = number
  default     = 1000

  validation {
    condition     = var.cosmos_max_throughput >= 1000 && var.cosmos_max_throughput % 1000 == 0
    error_message = "cosmos_max_throughput must be a multiple of 1000."
  }
}

# --- Edge ---------------------------------------------------------------------

variable "tls_certificate_secret_id" {
  description = "Key Vault secret ID of the certificate for the HTTPS listener of the Application Gateway. The gateway serves HTTP only while this is null."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Run the Application Gateway on the WAF_v2 SKU with the OWASP rule set in Prevention mode"
  type        = bool
}

variable "enable_front_door" {
  description = "Put Azure Front Door in front of the Application Gateway"
  type        = bool
}

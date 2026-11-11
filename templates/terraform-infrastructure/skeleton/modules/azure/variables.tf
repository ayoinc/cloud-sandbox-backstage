# -----------------------------------------------------------------------------
# Naming and placement
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for all resource names: up to 24 lowercase letters, digits and hyphens, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,22}[a-z0-9])?$", var.name_prefix))
    error_message = "name_prefix must be 1 to 24 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Environment of the stack: development, staging or production."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be development, staging or production."
  }
}

variable "region" {
  description = "Azure location of the stack, for example westeurope."
  type        = string
}

variable "secondary_region" {
  description = "Second Azure location used for disaster recovery. Geo-redundant storage and database backups always replicate to the Azure paired region of region, so use that pair here."
  type        = string
  default     = null
}

variable "availability_zones" {
  description = "Availability zones of region. Set to an empty list for a region without zones: zone-redundant options are then replaced by their single-zone equivalents."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "tags" {
  description = "Tags for every resource."
  type        = map(string)
}

variable "infrastructure_type" {
  description = "Kind of platform: web-application, data-platform, ml-platform, container-platform, serverless-platform or networking-foundation."
  type        = string

  validation {
    condition = contains([
      "web-application", "data-platform", "ml-platform",
      "container-platform", "serverless-platform", "networking-foundation",
    ], var.infrastructure_type)
    error_message = "infrastructure_type must be web-application, data-platform, ml-platform, container-platform, serverless-platform or networking-foundation."
  }
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

variable "enable_networking" {
  description = "Create the virtual network. When false, existing_network is used."
  type        = bool
}

variable "network_cidr" {
  description = "Address space of the created virtual network, /24 or larger. It is cut into 16 equal blocks for the subnets."
  type        = string

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && try(tonumber(split("/", var.network_cidr)[1]), 32) <= 24
    error_message = "network_cidr must be an IPv4 CIDR block of /24 or larger, for example 10.0.0.0/16."
  }
}

variable "existing_network" {
  description = "Virtual network to use when enable_networking is false: its resource ID and the resource IDs of its public and private subnets."
  type = object({
    network_id         = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
  default = null
}

variable "allowed_ingress_cidrs" {
  description = "Client CIDR blocks allowed to reach the web tier over HTTPS."
  type        = list(string)
  default     = []
}

variable "enable_security_group_rules" {
  description = "Create tiered network security groups (web, app, data). When false, only the data subnet is restricted, to traffic from inside the virtual network."
  type        = bool
}

variable "app_tier_ports" {
  description = "TCP ports of the app tier that the web tier may reach when enable_security_group_rules is true."
  type        = list(number)
  default     = [80, 443, 8080]
}

variable "require_flow_logs" {
  description = "Send virtual network flow logs to a storage account and a Log Analytics workspace."
  type        = bool
}

variable "network_watcher" {
  description = "Network Watcher of region that owns the flow log. Defaults to the one Azure creates for every region with a virtual network."
  type = object({
    name                = string
    resource_group_name = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Kubernetes
# -----------------------------------------------------------------------------

variable "enable_kubernetes" {
  description = "Create an AKS cluster in the private subnets."
  type        = bool
}

variable "kubernetes_version" {
  description = "Kubernetes version of the cluster. Null uses the current AKS default."
  type        = string
  default     = null
}

variable "kubernetes_api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the Kubernetes API. Empty makes the cluster private: the API is reachable from the virtual network only."
  type        = list(string)
  default     = []
}

variable "kubernetes_service_cidr" {
  description = "Address range of Kubernetes services. It must not overlap the virtual network."
  type        = string
  default     = "172.20.0.0/16"
}

variable "kubernetes_pod_cidr" {
  description = "Address range of the pod overlay network. It must not overlap the virtual network."
  type        = string
  default     = "172.24.0.0/14"
}

variable "node_size" {
  description = "Size of the worker nodes: small (2 vCPU), medium (4 vCPU), large (8 vCPU) or xlarge (16 vCPU)."
  type        = string

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.node_size)
    error_message = "node_size must be small, medium, large or xlarge."
  }
}

variable "enable_autoscaling" {
  description = "Scale the node count between min_nodes and max_nodes. When false, it is fixed at min_nodes."
  type        = bool
}

variable "min_nodes" {
  description = "Lowest number of worker nodes."
  type        = number

  validation {
    condition     = var.min_nodes >= 1 && floor(var.min_nodes) == var.min_nodes
    error_message = "min_nodes must be a whole number of at least 1."
  }
}

variable "max_nodes" {
  description = "Highest number of worker nodes."
  type        = number

  validation {
    condition     = var.max_nodes >= var.min_nodes && floor(var.max_nodes) == var.max_nodes
    error_message = "max_nodes must be a whole number that is not below min_nodes."
  }
}

# -----------------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------------

variable "enable_database" {
  description = "Create a managed database that is reachable over a private endpoint only."
  type        = bool
}

variable "database_type" {
  description = "Database engine: postgresql, mysql, mongodb (Cosmos DB for MongoDB), redis (Azure Managed Redis) or cosmosdb (Cosmos DB for NoSQL)."
  type        = string

  validation {
    condition     = contains(["postgresql", "mysql", "mongodb", "redis", "cosmosdb"], var.database_type)
    error_message = "database_type must be postgresql, mysql, mongodb, redis or cosmosdb."
  }
}

variable "enable_storage" {
  description = "Create a private, versioned storage account for blobs."
  type        = bool
}

variable "enable_cdn" {
  description = "Put Azure Front Door in front of the storage account. Requires enable_storage."
  type        = bool
}

variable "enable_waf" {
  description = "Create a web application firewall policy with managed rules. It is attached to Front Door when enable_cdn is true, otherwise it is a regional policy for an Application Gateway."
  type        = bool
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "enable_secrets_manager" {
  description = "Create a Key Vault for secrets. Generated database credentials are stored in it."
  type        = bool
}

variable "enable_kms" {
  description = "Encrypt storage accounts and the database with a customer-managed key that rotates every year."
  type        = bool
}

variable "require_deletion_protection" {
  description = "Protect the database, the cluster and the vaults against deletion with management locks and purge protection."
  type        = bool
}

# -----------------------------------------------------------------------------
# Operations
# -----------------------------------------------------------------------------

variable "enable_backup" {
  description = "Create a backup vault with policies for the storage account and the database, and keep database backups for 35 days instead of 7."
  type        = bool
}

variable "enable_monitoring" {
  description = "Create a Log Analytics workspace, send the logs of the created components to it and add a workbook."
  type        = bool
}

variable "enable_managed_prometheus" {
  description = "Create an Azure Monitor workspace for Prometheus metrics and an Azure Managed Grafana instance, both wired to the cluster when there is one."
  type        = bool
}

variable "enable_alerting" {
  description = "Create an action group and metric alerts for the created components."
  type        = bool
}

variable "alert_email" {
  description = "Email address that receives alerts. Null creates the action group without a receiver."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Days to keep logs, up to 4383 (12 years). Flow logs and archived resource logs in the log storage account are deleted after exactly this many days. The Log Analytics workspace keeps between 30 and 730 days available for queries: a smaller value still keeps 30 days there, and for a larger value the resource logs are also archived in the log storage account and the container log tables get long-term retention for the next whole number of years."
  type        = number

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 4383
    error_message = "log_retention_days must be between 1 and 4383."
  }
}

variable "enable_disaster_recovery" {
  description = "Protect data across regions: geo-redundant storage, geo-redundant database backups or a second Cosmos DB region, and a registry replica."
  type        = bool

  validation {
    condition     = !var.enable_disaster_recovery || var.secondary_region != null
    error_message = "secondary_region must be set when enable_disaster_recovery is true."
  }
}

variable "enable_cost_optimization" {
  description = "Tier storage to cooler access tiers over time. Outside production also use spot worker nodes, a single NAT gateway and the smallest database tier."
  type        = bool
}

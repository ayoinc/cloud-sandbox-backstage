variable "project_id" {
  description = "ID of the Google Cloud project that receives every resource."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names: 3 to 24 lowercase letters, digits and hyphens, starting with a letter."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3 to 24 characters of lowercase letters, digits and hyphens, start with a letter and not end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment: development, staging or production."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be development, staging or production."
  }
}

variable "region" {
  description = "Primary Google Cloud region, for example europe-west2."
  type        = string
}

variable "secondary_region" {
  description = "Second region used for disaster recovery. Required when enable_disaster_recovery is true."
  type        = string
  default     = null

  validation {
    condition     = !var.enable_disaster_recovery || (var.secondary_region != null && var.secondary_region != var.region)
    error_message = "secondary_region must be set to a region other than region when enable_disaster_recovery is true."
  }
}

variable "tags" {
  description = "Tags for every resource. They are converted to Google Cloud labels: lowercased, unsupported characters replaced by hyphens, cut to 63 characters."
  type        = map(string)
}

variable "infrastructure_type" {
  description = "Kind of platform: adds a container registry (container-platform, ml-platform, serverless-platform), data-lake buckets (data-platform, ml-platform) or a private DNS zone (networking-foundation)."
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
  description = "Create the VPC network, two public and two private subnets, Cloud Router and Cloud NAT. When false, existing_network is used."
  type        = bool
}

variable "network_cidr" {
  description = "Address range of the created network, /20 or larger. It is cut into 16 equal blocks: 0-1 public subnets, 8-9 private subnets, 12-15 private services access (Cloud SQL, Memorystore)."
  type        = string

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && try(tonumber(split("/", var.network_cidr)[1]), 32) <= 20
    error_message = "network_cidr must be a valid IPv4 CIDR block with a prefix of /20 or larger, for example 10.0.0.0/16."
  }
}

variable "existing_network" {
  description = "Network to use when enable_networking is false: the network ID (projects/PROJECT/global/networks/NAME) and the IDs of its subnets in region."
  type = object({
    network_id         = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
  default = null
}

variable "create_private_services_access" {
  description = "Reserve an address range and create the private services access connection that Cloud SQL and Memorystore use. Set to false when existing_network already has one."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "Client CIDR blocks allowed to reach the web tier over HTTPS, next to the Google load balancer ranges."
  type        = list(string)
  default     = []
}

variable "enable_security_group_rules" {
  description = "Create tiered firewall rules (web, app, data) selected by network tag; managed data stores are reachable from the app tier and the cluster nodes only. When false, one rule allows traffic inside network_cidr."
  type        = bool
}

variable "app_port" {
  description = "TCP port the app tier listens on for traffic from the web tier."
  type        = number
  default     = 8080
}

variable "require_flow_logs" {
  description = "Record VPC flow logs and route them to the log bucket, which is created for them when enable_monitoring is false."
  type        = bool
}

# -----------------------------------------------------------------------------
# Kubernetes
# -----------------------------------------------------------------------------

variable "enable_kubernetes" {
  description = "Create a private GKE Standard cluster in the first private subnet."
  type        = bool
}

variable "kubernetes_version" {
  description = "Minimum Kubernetes version of the control plane. null uses the default of the REGULAR release channel."
  type        = string
  default     = null
}

variable "kubernetes_api_allowed_cidrs" {
  description = "CIDR blocks outside the network that may reach the Kubernetes API. Empty: the public endpoint is disabled and the API is reachable from the network only."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.kubernetes_api_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "kubernetes_api_allowed_cidrs must contain valid CIDR blocks."
  }
}

variable "kubernetes_control_plane_cidr" {
  description = "A /28 range for the GKE control plane. It must not overlap any range used in the network."
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(cidrhost(var.kubernetes_control_plane_cidr, 0)) && endswith(var.kubernetes_control_plane_cidr, "/28")
    error_message = "kubernetes_control_plane_cidr must be a /28 CIDR block."
  }
}

variable "node_size" {
  description = "Size of the worker nodes: small (2 vCPU/4 GB), medium (4/8), large (8/16) or xlarge (16/32)."
  type        = string

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.node_size)
    error_message = "node_size must be small, medium, large or xlarge."
  }
}

variable "enable_autoscaling" {
  description = "Scale the node pool between min_nodes and max_nodes. When false, the pool has a fixed size of min_nodes, rounded up to a whole number of nodes per zone."
  type        = bool
}

variable "min_nodes" {
  description = "Smallest number of worker nodes in the cluster."
  type        = number

  validation {
    condition     = var.min_nodes >= 1 && floor(var.min_nodes) == var.min_nodes
    error_message = "min_nodes must be a whole number of at least 1."
  }
}

variable "max_nodes" {
  description = "Largest number of worker nodes in the cluster when enable_autoscaling is true."
  type        = number

  validation {
    condition     = var.max_nodes >= var.min_nodes && floor(var.max_nodes) == var.max_nodes
    error_message = "max_nodes must be a whole number that is not smaller than min_nodes."
  }
}

# -----------------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------------

variable "enable_database" {
  description = "Create a private, encrypted managed database with generated credentials."
  type        = bool
}

variable "database_type" {
  description = "Database engine: postgresql or mysql (Cloud SQL), or redis (Memorystore). Only checked when enable_database is true."
  type        = string

  validation {
    condition     = !var.enable_database || contains(["postgresql", "mysql", "redis"], var.database_type)
    error_message = "database_type must be postgresql, mysql or redis on Google Cloud."
  }
}

variable "database_version" {
  description = "Cloud SQL database version such as POSTGRES_17 or MYSQL_8_4. null uses POSTGRES_17 or MYSQL_8_4. Memorystore always uses the service default."
  type        = string
  default     = null
}

variable "enable_storage" {
  description = "Create a private, versioned object storage bucket."
  type        = bool
}

variable "enable_cdn" {
  description = "Serve the storage bucket through Cloud CDN on a global HTTPS load balancer. The bucket stays private: the load balancer signs its requests with an HMAC key. Needs enable_storage."
  type        = bool

  validation {
    condition     = !var.enable_cdn || var.enable_storage
    error_message = "enable_cdn needs the storage bucket: set enable_storage = true."
  }
}

variable "cdn_domain" {
  description = "Domain name of the CDN endpoint. When set, a Google-managed certificate is issued once the domain resolves to the CDN address. When null, the endpoint serves HTTPS on its IP address with a self-signed certificate."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Create a Cloud Armor security policy with the preconfigured OWASP rules. It is attached to the CDN backend when enable_cdn is true, otherwise exposed as waf_id for your own backend services."
  type        = bool
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------

variable "enable_secrets_manager" {
  description = "Enable Secret Manager, store the generated database credentials in it and enable the Secret Manager add-on of the cluster."
  type        = bool
}

variable "enable_kms" {
  description = "Create a Cloud KMS key with 90-day rotation and use it for buckets, databases, secrets, logs, the container registry and the cluster. When false, Google-managed encryption is used."
  type        = bool
}

variable "require_deletion_protection" {
  description = "Protect the database, cluster, keys, secrets and backup vault against deletion and keep non-empty buckets on destroy."
  type        = bool
}

# -----------------------------------------------------------------------------
# Operations
# -----------------------------------------------------------------------------

variable "enable_backup" {
  description = "Create a Backup and DR vault with a backup plan for Cloud SQL, a Backup for GKE plan for the cluster and Redis snapshots, and keep 35 database backups instead of 7."
  type        = bool
}

variable "enable_monitoring" {
  description = "Create a log bucket with log_retention_days, a sink that routes the logs of the created components to it, and a monitoring dashboard."
  type        = bool
}

variable "enable_managed_prometheus" {
  description = "Enable Managed Service for Prometheus: managed collection on the cluster and a service account for querying. Google Cloud has no managed Grafana, so grafana_endpoint is always null."
  type        = bool
}

variable "enable_alerting" {
  description = "Create a Pub/Sub topic with notification channels and alert policies for the components that exist."
  type        = bool
}

variable "alert_email" {
  description = "Email address that receives alerts. null creates no email channel."
  type        = string
  default     = null

  validation {
    condition     = var.alert_email == null || can(regex("^[^@\\s]+@[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be an email address."
  }
}

variable "log_retention_days" {
  description = "Days the log bucket keeps logs. Cloud Logging buckets hold 1 to 3650 days natively, so every value, including the 2192 and 2557 days of compliance profiles, is applied as is to the bucket; no archive tier or export is involved."
  type        = number

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "log_retention_days must be between 1 and 3650."
  }
}

variable "enable_disaster_recovery" {
  description = "Protect data in secondary_region: replicated buckets, database backups stored there, a cross-region read replica in production, replicated secrets and cross-region GKE backups."
  type        = bool
}

variable "enable_cost_optimization" {
  description = "Autoclass and deeper lifecycle tiering for buckets, registry cleanup and GKE cost allocation; outside production also Spot nodes and the smallest database tier. Cloud NAT is one regional gateway in every case."
  type        = bool
}

variable "private_dns_domain" {
  description = "Domain of the private DNS zone created for networking-foundation. null uses NAME_PREFIX.internal."
  type        = string
  default     = null
}

# =============================================================================
# Project
# =============================================================================

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,19}$", var.project_name))
    error_message = "project_name must start with a letter, contain only lowercase letters, digits and hyphens, and be at most 20 characters long."
  }
}

variable "component_name" {
  description = "Name of the infrastructure component, applied as a label"
  type        = string
}

variable "description" {
  description = "Description of the infrastructure component"
  type        = string
  default     = ""
}

variable "project_id" {
  description = "GCP project ID where the resources are deployed"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod or dr)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "dr"], var.environment)
    error_message = "environment must be one of dev, staging, prod or dr."
  }
}

variable "region" {
  description = "Primary GCP region"
  type        = string
}

variable "labels" {
  description = "Additional labels applied to every resource that supports labels"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Resource categories
# =============================================================================
# Every switch defaults to on so that static analysis covers the whole
# configuration. environments/*.tfvars sets each switch explicitly.

variable "enable_networking" {
  description = "Create the VPC network, subnets, Cloud NAT and firewall rules"
  type        = bool
  default     = true
}

variable "enable_compute" {
  description = "Create the Compute Engine instance template and managed instance group"
  type        = bool
  default     = true
}

variable "enable_containers" {
  description = "Create the GKE cluster, node pool and Artifact Registry repository"
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Create the Cloud Storage buckets and, if enable_filestore is set, the Filestore instance"
  type        = bool
  default     = true
}

variable "enable_database" {
  description = "Create the Cloud SQL instance and, if enabled, Firestore and Memorystore Redis"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Create the Cloud KMS key, the application service account and the Secret Manager secret"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Create the log-based error metric, the alert policy and the notification channel"
  type        = bool
  default     = true
}

variable "enable_analytics" {
  description = "Create the BigQuery dataset and the Pub/Sub topic and subscription"
  type        = bool
  default     = true
}

variable "enable_ai_ml" {
  description = "Enable Vertex AI and create its service account and artifact bucket"
  type        = bool
  default     = true
}

variable "enable_serverless" {
  description = "Create the Cloud Run service"
  type        = bool
  default     = true
}

# =============================================================================
# Networking
# =============================================================================

variable "network_cidr" {
  description = "CIDR block of the VPC network. Firewall rules allow traffic inside it and the GKE subnet is carved out of it"
  type        = string

  validation {
    condition     = can(cidrhost(var.network_cidr, 0)) && try(tonumber(split("/", var.network_cidr)[1]), 32) <= 20
    error_message = "network_cidr must be a valid IPv4 CIDR block with a prefix of /20 or larger (for example 10.0.0.0/16)."
  }
}

variable "subnets" {
  description = "Subnets of the VPC network"
  type = list(object({
    name   = string
    cidr   = string
    region = string
  }))
  default = []
}

variable "existing_network" {
  description = "Name of an existing VPC network to use when enable_networking is false"
  type        = string
  default     = "default"
}

variable "existing_subnetwork" {
  description = "Name of an existing subnetwork in the primary region to use when enable_networking is false"
  type        = string
  default     = "default"
}

variable "create_private_service_access" {
  description = "Reserve a range and peer the network with Google services. Cloud SQL and Memorystore Redis need it; set to false if the existing network is already peered"
  type        = bool
  default     = true
}

variable "private_service_access_prefix_length" {
  description = "Prefix length of the range reserved for Google services"
  type        = number
  default     = 20
}

# =============================================================================
# Compute
# =============================================================================

variable "machine_type" {
  description = "Machine type of the Compute Engine instances"
  type        = string
}

variable "boot_disk_size" {
  description = "Boot disk size of the Compute Engine instances in GB"
  type        = number
}

variable "boot_disk_type" {
  description = "Boot disk type of the Compute Engine instances"
  type        = string
}

variable "instance_image" {
  description = "Boot image of the Compute Engine instances"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "instance_count" {
  description = "Number of instances in the managed instance group"
  type        = number
  default     = 1
}

# =============================================================================
# Containers
# =============================================================================

variable "gke_version" {
  description = "Minimum Kubernetes version of the GKE control plane"
  type        = string
}

variable "gke_node_machine_type" {
  description = "Machine type of the GKE nodes"
  type        = string
}

variable "gke_node_locations" {
  description = "Zones of the GKE nodes. All zones of the region are used when empty"
  type        = list(string)
  default     = []
}

variable "gke_initial_node_count" {
  description = "Initial number of GKE nodes per zone"
  type        = number
}

variable "gke_min_node_count" {
  description = "Minimum number of GKE nodes per zone"
  type        = number
}

variable "gke_max_node_count" {
  description = "Maximum number of GKE nodes per zone"
  type        = number
}

variable "gke_subnet_cidr" {
  description = "CIDR block of the GKE node subnet. The last /20 of network_cidr is used when null"
  type        = string
  default     = null
}

variable "gke_pods_cidr" {
  description = "Secondary CIDR block for GKE pods"
  type        = string
  default     = "10.100.0.0/16"
}

variable "gke_services_cidr" {
  description = "Secondary CIDR block for GKE services"
  type        = string
  default     = "10.101.0.0/20"
}

variable "gke_master_cidr" {
  description = "CIDR block of the GKE control plane"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_master_authorized_networks" {
  description = "CIDR blocks allowed to reach the GKE control plane. The VPC network range is always allowed"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "gke_rbac_security_group" {
  description = "Google Workspace group (gke-security-groups@your-domain) used for Kubernetes RBAC. Google Groups for RBAC is off when null"
  type        = string
  default     = null
}

# =============================================================================
# Storage
# =============================================================================

variable "storage_class" {
  description = "Storage class of the Cloud Storage buckets"
  type        = string
}

variable "enable_versioning" {
  description = "Keep previous versions of objects in the data bucket"
  type        = bool
  default     = true
}

variable "enable_filestore" {
  description = "Create a Filestore NFS instance. Needs enable_storage"
  type        = bool
  default     = true
}

variable "filestore_capacity_gb" {
  description = "Capacity of the Filestore share in GB"
  type        = number
  default     = 1024
}

# =============================================================================
# Database
# =============================================================================

variable "cloudsql_database_version" {
  description = "Cloud SQL database version, for example POSTGRES_15 or MYSQL_8_0"
  type        = string
}

variable "cloudsql_tier" {
  description = "Cloud SQL machine tier"
  type        = string
}

variable "cloudsql_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
}

variable "cloudsql_backup_retention" {
  description = "Number of Cloud SQL backups to keep"
  type        = number
}

variable "cloudsql_ssl_mode" {
  description = "SSL mode of Cloud SQL connections: ENCRYPTED_ONLY, or TRUSTED_CLIENT_CERTIFICATE_REQUIRED to also require client certificates"
  type        = string
  default     = "ENCRYPTED_ONLY"
}

variable "enable_firestore" {
  description = "Create a Firestore database. Needs enable_database"
  type        = bool
  default     = true
}

variable "firestore_location" {
  description = "Location of the Firestore database. The primary region is used when null"
  type        = string
  default     = null
}

variable "enable_redis" {
  description = "Create a Memorystore Redis instance. Needs enable_database"
  type        = bool
  default     = true
}

variable "redis_memory_size_gb" {
  description = "Memory size of the Memorystore Redis instance in GB"
  type        = number
  default     = 1
}

# =============================================================================
# Monitoring
# =============================================================================

variable "alert_email" {
  description = "Email address that receives alerts. No notification channel is created when empty"
  type        = string
  default     = ""
}

variable "error_log_threshold" {
  description = "Number of error log entries per minute that opens an alert"
  type        = number
  default     = 10
}

# =============================================================================
# Serverless
# =============================================================================

variable "cloud_run_image" {
  description = "Container image of the Cloud Run service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest"
}

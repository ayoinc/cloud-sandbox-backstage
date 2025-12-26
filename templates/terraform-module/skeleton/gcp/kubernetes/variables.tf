# -----------------------------------------------------------------------------
# GCP Kubernetes (GKE) Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project and Environment
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_self_link" {
  description = "Self link of the VPC network"
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of the subnetwork"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------

variable "cluster_version" {
  description = "Kubernetes version for the GKE cluster (minimum master version)"
  type        = string
  default     = null # Uses default version based on release channel
}

variable "release_channel" {
  description = "Release channel for GKE cluster (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["UNSPECIFIED", "RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be one of: UNSPECIFIED, RAPID, REGULAR, STABLE."
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Private Cluster Configuration
# -----------------------------------------------------------------------------

variable "enable_private_cluster" {
  description = "Enable private cluster (nodes have internal IP addresses only)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (master is only accessible via internal IP)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master's private IP address (must be /28)"
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/28$", var.master_ipv4_cidr_block))
    error_message = "Master CIDR block must be a valid /28 CIDR range."
  }
}

variable "enable_master_global_access" {
  description = "Enable global access to the master's private endpoint"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Master Authorized Networks
# -----------------------------------------------------------------------------

variable "master_authorized_networks" {
  description = "List of CIDR blocks authorized to access the Kubernetes master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Network Policy
# -----------------------------------------------------------------------------

variable "enable_network_policy" {
  description = "Enable network policy (Calico) for the cluster"
  type        = bool
  default     = true
}

variable "datapath_provider" {
  description = "Datapath provider (LEGACY_DATAPATH, ADVANCED_DATAPATH for Dataplane V2)"
  type        = string
  default     = "ADVANCED_DATAPATH"

  validation {
    condition     = contains(["LEGACY_DATAPATH", "ADVANCED_DATAPATH"], var.datapath_provider)
    error_message = "Datapath provider must be LEGACY_DATAPATH or ADVANCED_DATAPATH."
  }
}

# -----------------------------------------------------------------------------
# Workload Identity
# -----------------------------------------------------------------------------

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the cluster"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Logging and Monitoring
# -----------------------------------------------------------------------------

variable "logging_service" {
  description = "Logging service to use (logging.googleapis.com/kubernetes or none)"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service to use (monitoring.googleapis.com/kubernetes or none)"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}

variable "logging_components" {
  description = "Logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]

  validation {
    condition     = alltrue([for c in var.logging_components : contains(["SYSTEM_COMPONENTS", "WORKLOADS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"], c)])
    error_message = "Logging components must be from: SYSTEM_COMPONENTS, WORKLOADS, APISERVER, CONTROLLER_MANAGER, SCHEDULER."
  }
}

variable "monitoring_components" {
  description = "Monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]

  validation {
    condition     = alltrue([for c in var.monitoring_components : contains(["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER", "DAEMONSET", "DEPLOYMENT", "HPA", "POD", "STATEFULSET", "STORAGE"], c)])
    error_message = "Invalid monitoring component specified."
  }
}

variable "enable_managed_prometheus" {
  description = "Enable Google Cloud Managed Service for Prometheus"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Addons Configuration
# -----------------------------------------------------------------------------

variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing addon"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "enable_gce_persistent_disk_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver"
  type        = bool
  default     = true
}

variable "enable_filestore_csi_driver" {
  description = "Enable Filestore CSI driver"
  type        = bool
  default     = false
}

variable "enable_gcs_fuse_csi_driver" {
  description = "Enable GCS Fuse CSI driver"
  type        = bool
  default     = false
}

variable "enable_dns_cache" {
  description = "Enable NodeLocal DNSCache"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Enable Vertical Pod Autoscaling"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Node Auto-Provisioning
# -----------------------------------------------------------------------------

variable "enable_node_auto_provisioning" {
  description = "Enable node auto-provisioning for cluster autoscaler"
  type        = bool
  default     = false
}

variable "node_auto_provisioning_cpu_min" {
  description = "Minimum CPU cores for node auto-provisioning"
  type        = number
  default     = 0
}

variable "node_auto_provisioning_cpu_max" {
  description = "Maximum CPU cores for node auto-provisioning"
  type        = number
  default     = 100
}

variable "node_auto_provisioning_memory_min" {
  description = "Minimum memory (GB) for node auto-provisioning"
  type        = number
  default     = 0
}

variable "node_auto_provisioning_memory_max" {
  description = "Maximum memory (GB) for node auto-provisioning"
  type        = number
  default     = 400
}

variable "node_auto_provisioning_disk_size" {
  description = "Disk size (GB) for auto-provisioned nodes"
  type        = number
  default     = 100
}

variable "node_auto_provisioning_disk_type" {
  description = "Disk type for auto-provisioned nodes"
  type        = string
  default     = "pd-standard"
}

# -----------------------------------------------------------------------------
# Node Pools Configuration
# -----------------------------------------------------------------------------

variable "node_pools" {
  description = "List of node pool configurations"
  type = list(object({
    name                    = string
    machine_type            = optional(string, "e2-medium")
    disk_size_gb            = optional(number, 100)
    disk_type               = optional(string, "pd-standard")
    image_type              = optional(string, "COS_CONTAINERD")
    initial_node_count      = optional(number, 1)
    min_count               = optional(number, 1)
    max_count               = optional(number, 3)
    enable_autoscaling      = optional(bool, true)
    location_policy         = optional(string, "BALANCED")
    total_min_count         = optional(number, null)
    total_max_count         = optional(number, null)
    preemptible             = optional(bool, false)
    spot                    = optional(bool, false)
    auto_repair             = optional(bool, true)
    auto_upgrade            = optional(bool, true)
    max_surge               = optional(number, 1)
    max_unavailable         = optional(number, 0)
    upgrade_strategy        = optional(string, "SURGE")
    node_pool_soak_duration = optional(string, "0s")
    batch_percentage        = optional(number, null)
    batch_node_count        = optional(number, null)
    batch_soak_duration     = optional(string, null)
    labels                  = optional(map(string), {})
    tags                    = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    metadata                    = optional(map(string), {})
    oauth_scopes                = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    enable_secure_boot          = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
    accelerator_type            = optional(string, "")
    accelerator_count           = optional(number, 0)
    gpu_driver_version          = optional(string, "DEFAULT")
    sysctls                     = optional(map(string), {})
    enable_gcfs                 = optional(bool, false)
    enable_gvnic                = optional(bool, false)
    node_locations              = optional(list(string), [])
  }))
  default = [
    {
      name               = "primary"
      machine_type       = "e2-medium"
      disk_size_gb       = 100
      min_count          = 1
      max_count          = 3
      enable_autoscaling = true
    }
  ]
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for the cluster"
  type        = bool
  default     = false
}

variable "security_posture_mode" {
  description = "Security posture mode (DISABLED, BASIC, ENTERPRISE)"
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["DISABLED", "BASIC", "ENTERPRISE"], var.security_posture_mode)
    error_message = "Security posture mode must be DISABLED, BASIC, or ENTERPRISE."
  }
}

variable "vulnerability_mode" {
  description = "Vulnerability scanning mode (VULNERABILITY_DISABLED, VULNERABILITY_BASIC, VULNERABILITY_ENTERPRISE)"
  type        = string
  default     = "VULNERABILITY_BASIC"

  validation {
    condition     = contains(["VULNERABILITY_DISABLED", "VULNERABILITY_BASIC", "VULNERABILITY_ENTERPRISE"], var.vulnerability_mode)
    error_message = "Vulnerability mode must be VULNERABILITY_DISABLED, VULNERABILITY_BASIC, or VULNERABILITY_ENTERPRISE."
  }
}

# -----------------------------------------------------------------------------
# DNS Configuration
# -----------------------------------------------------------------------------

variable "cluster_dns" {
  description = "Which in-cluster DNS provider to use (PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT, CLOUD_DNS)"
  type        = string
  default     = "CLOUD_DNS"

  validation {
    condition     = contains(["PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS"], var.cluster_dns)
    error_message = "Cluster DNS must be PROVIDER_UNSPECIFIED, PLATFORM_DEFAULT, or CLOUD_DNS."
  }
}

variable "cluster_dns_scope" {
  description = "Scope of the cluster DNS (DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE, VPC_SCOPE)"
  type        = string
  default     = "CLUSTER_SCOPE"

  validation {
    condition     = contains(["DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"], var.cluster_dns_scope)
    error_message = "Cluster DNS scope must be DNS_SCOPE_UNSPECIFIED, CLUSTER_SCOPE, or VPC_SCOPE."
  }
}

variable "cluster_dns_domain" {
  description = "Custom domain for cluster DNS"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Maintenance Window
# -----------------------------------------------------------------------------

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    start_time = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Default SNAT
# -----------------------------------------------------------------------------

variable "disable_default_snat" {
  description = "Disable default SNAT for private clusters"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Container Registry (Legacy)
# -----------------------------------------------------------------------------

variable "enable_container_registry" {
  description = "Enable Container Registry (Legacy - use Artifact Registry instead)"
  type        = bool
  default     = false
}

variable "container_registry_location" {
  description = "Location for Container Registry (US, EU, ASIA)"
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU", "ASIA"], var.container_registry_location)
    error_message = "Container Registry location must be US, EU, or ASIA."
  }
}

# -----------------------------------------------------------------------------
# Artifact Registry
# -----------------------------------------------------------------------------

variable "enable_artifact_registry" {
  description = "Enable Artifact Registry for container images"
  type        = bool
  default     = true
}

variable "artifact_registry_cleanup_dry_run" {
  description = "Run cleanup policies in dry-run mode"
  type        = bool
  default     = false
}

variable "artifact_registry_cleanup_policies" {
  description = "Cleanup policies for Artifact Registry"
  type = list(object({
    id     = string
    action = optional(string, "DELETE")
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      version_name_prefixes = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
    }))
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    }))
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels for all resources"
  type        = map(string)
  default     = {}
}

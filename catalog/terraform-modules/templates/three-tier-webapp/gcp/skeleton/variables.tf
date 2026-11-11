# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the project, used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "gcp_project_id" {
  description = "ID of the Google Cloud project the resources are created in"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "vpc_cidr" {
  description = "Address range the subnet, the GKE pod and service ranges and the database peering range are carved from"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && try(tonumber(split("/", var.vpc_cidr)[1]), 0) >= 16 && try(tonumber(split("/", var.vpc_cidr)[1]), 32) <= 20
    error_message = "vpc_cidr must be an IPv4 range with a prefix length between 16 and 20."
  }
}

# --- Application tier ---------------------------------------------------------

variable "compute_type" {
  description = "How the application runs: gke-autopilot, gke-standard or mig"
  type        = string

  validation {
    condition     = contains(["gke-autopilot", "gke-standard", "mig"], var.compute_type)
    error_message = "compute_type must be gke-autopilot, gke-standard or mig."
  }
}

variable "machine_type" {
  description = "Compute Engine machine type of the GKE nodes (gke-standard) or the instances (mig)"
  type        = string
  default     = "e2-medium"
}

variable "min_nodes" {
  description = "Lower bound of the autoscaler: GKE nodes (gke-standard) or instances (mig)"
  type        = number
  default     = 2

  validation {
    condition     = var.min_nodes >= 1
    error_message = "min_nodes must be at least 1."
  }
}

variable "max_nodes" {
  description = "Upper bound of the autoscaler: GKE nodes (gke-standard) or instances (mig). When it is lower than min_nodes, min_nodes is used."
  type        = number
  default     = 10
}

variable "cpu_target" {
  description = "Average CPU utilisation, in percent, that the instance group autoscaler keeps the instances at (mig)"
  type        = number
  default     = 60
}

variable "container_image" {
  description = "Container image the instances run (mig)"
  type        = string
  default     = "mirror.gcr.io/library/nginx:stable"
}

variable "container_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path the load balancer requests to check the application"
  type        = string
  default     = "/"
}

variable "instance_image" {
  description = "Boot image of the instances (mig). The startup script expects Container-Optimized OS."
  type        = string
  default     = "cos-cloud/cos-stable"
}

variable "gke_release_channel" {
  description = "Release channel of the GKE cluster: RAPID, REGULAR or STABLE"
  type        = string
  default     = "REGULAR"
}

variable "gke_master_ipv4_cidr_block" {
  description = "A /28 range for the GKE control plane. It must not overlap vpc_cidr."
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_master_authorized_networks" {
  description = "Address ranges outside the VPC that may reach the GKE control plane"
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default = []
}

variable "gke_neg_zones" {
  description = "Zones in which GKE has created the network endpoint group of the application's Service. The load balancer sends traffic to the group in each zone listed."
  type        = list(string)
  default     = []
}

variable "kubernetes_namespace" {
  description = "Namespace of the Kubernetes service account that may act as the application's Google service account"
  type        = string
  default     = "default"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account that may act as the application's Google service account"
  type        = string
  default     = "app"
}

# --- Data tier ----------------------------------------------------------------

variable "database_engine" {
  description = "Database engine: POSTGRES or MYSQL"
  type        = string

  validation {
    condition     = contains(["POSTGRES", "MYSQL"], var.database_engine)
    error_message = "database_engine must be POSTGRES or MYSQL."
  }
}

variable "database_version" {
  description = "Cloud SQL database version, for example POSTGRES_16. Defaults to a current major version of the chosen engine."
  type        = string
  default     = null
}

variable "database_tier" {
  description = "Cloud SQL machine tier"
  type        = string
}

variable "high_availability" {
  description = "Keep a standby database instance in a second zone"
  type        = bool
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "Name of the database user the application connects as"
  type        = string
  default     = "app"
}

variable "database_disk_size" {
  description = "Initial database storage in GB. Storage grows automatically."
  type        = number
  default     = 20
}

# --- Edge ---------------------------------------------------------------------

variable "domains" {
  description = "Domain names for a Google-managed certificate. A self-signed certificate is used while this is empty."
  type        = list(string)
  default     = []
}

variable "enable_cloud_armor" {
  description = "Attach a Cloud Armor security policy to the load balancer"
  type        = bool
}

variable "rate_limit_per_minute" {
  description = "Requests per minute from one address before Cloud Armor throttles it"
  type        = number
  default     = 600
}

variable "enable_cloud_cdn" {
  description = "Serve cacheable responses from Cloud CDN"
  type        = bool
}

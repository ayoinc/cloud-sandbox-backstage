variable "project_id" {
  description = "ID of the Google Cloud project to deploy to."
  type        = string
}

variable "project_name" {
  description = "Name of the store. Used in the names of all resources."
  type        = string
  default     = "${{ values.projectName }}"
}

variable "environment" {
  description = "Deployment environment: dev, stg or prod."
  type        = string
  default     = "${{ values.environment }}"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "The environment must be dev, stg or prod."
  }
}

variable "business_unit" {
  description = "Business unit that owns the store. Used to tag the resources."
  type        = string
  default     = "${{ values.businessUnit }}"
}

variable "backend_image" {
  description = "Container image of the API."
  type        = string
  default     = "ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}/backend:latest"
}

variable "frontend_image" {
  description = "Container image of the storefront."
  type        = string
  default     = "ghcr.io/${{ values.destination.owner | lower }}/${{ values.destination.repo | lower }}/frontend:latest"
}

variable "enable_cache" {
  description = "Create a Redis cache for the API."
  type        = bool
  default     = ${{ 'true' if values.enableCaching else 'false' }}
}

variable "enable_cdn" {
  description = "Put a content delivery network in front of the storefront."
  type        = bool
  default     = ${{ 'true' if values.enableCDN else 'false' }}
}

variable "enable_autoscaling" {
  description = "Scale the API and the storefront between min_replicas and max_replicas with the load. When false, both run min_replicas instances."
  type        = bool
  default     = ${{ 'true' if values.autoScaling else 'false' }}
}

variable "min_replicas" {
  description = "Smallest number of instances of the API and of the storefront."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Largest number of instances when autoscaling is on."
  type        = number
  default     = 4
}

variable "region" {
  description = "Google Cloud region of all resources."
  type        = string
  default     = "${{ values.region }}"
}

variable "database_tier" {
  description = "Machine type of the Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

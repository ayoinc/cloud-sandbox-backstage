variable "project_name" {
  description = "The name of the project for labeling purposes"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region where the function will be deployed"
  type        = string
}

variable "function_name" {
  description = "The name of the Cloud Function"
  type        = string
}

variable "description" {
  description = "Description of the Cloud Function"
  type        = string
  default     = null
}

variable "runtime" {
  description = "The runtime environment for the function (e.g., nodejs20, python311, go121, java17, dotnet6)"
  type        = string

  validation {
    condition     = can(regex("^(nodejs|python|go|java|dotnet|ruby|php)", var.runtime))
    error_message = "Runtime must be a valid Cloud Functions runtime (e.g., nodejs20, python311, go121)."
  }
}

variable "entry_point" {
  description = "The name of the function entry point in the source code"
  type        = string
}

variable "source_bucket" {
  description = "The GCS bucket containing the function source code. If not provided and source_dir is set, a bucket will be created."
  type        = string
  default     = null
}

variable "source_archive_object" {
  description = "The name of the archive object in the source bucket"
  type        = string
  default     = null
}

variable "source_dir" {
  description = "Local path to the directory containing the function source code"
  type        = string
  default     = null
}

variable "available_memory" {
  description = "The amount of memory available for the function (e.g., 128M, 256M, 512M, 1G, 2G, 4G, 8G, 16G, 32G)"
  type        = string
  default     = "256M"

  validation {
    condition     = can(regex("^[0-9]+(M|G)$", var.available_memory))
    error_message = "Available memory must be specified with M or G suffix (e.g., 256M, 1G)."
  }
}

variable "available_cpu" {
  description = "The number of CPUs available for the function"
  type        = string
  default     = "1"
}

variable "timeout_seconds" {
  description = "The function execution timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 3600
    error_message = "Timeout must be between 1 and 3600 seconds."
  }
}

variable "max_instance_count" {
  description = "The maximum number of concurrent instances for the function"
  type        = number
  default     = 100

  validation {
    condition     = var.max_instance_count >= 1
    error_message = "Max instance count must be at least 1."
  }
}

variable "min_instance_count" {
  description = "The minimum number of instances to keep warm"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instance_count >= 0
    error_message = "Min instance count must be 0 or greater."
  }
}

variable "service_account_email" {
  description = "The service account email to use for the function. If not provided, the default compute service account will be used."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables to set for the function"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables from Secret Manager"
  type = list(object({
    key        = string
    project_id = string
    secret     = string
    version    = string
  }))
  default = []
}

variable "vpc_connector" {
  description = "The VPC connector to use for the function (format: projects/PROJECT/locations/REGION/connectors/CONNECTOR)"
  type        = string
  default     = null
}

variable "vpc_connector_egress_settings" {
  description = "The egress settings for the VPC connector (PRIVATE_RANGES_ONLY or ALL_TRAFFIC)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], var.vpc_connector_egress_settings)
    error_message = "VPC connector egress settings must be either PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  }
}

variable "ingress_settings" {
  description = "The ingress settings for the function (ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB)"
  type        = string
  default     = "ALLOW_ALL"

  validation {
    condition     = contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], var.ingress_settings)
    error_message = "Ingress settings must be one of: ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB."
  }
}

variable "trigger_type" {
  description = "The type of trigger for the function (http, pubsub, storage)"
  type        = string
  default     = "http"

  validation {
    condition     = contains(["http", "pubsub", "storage"], var.trigger_type)
    error_message = "Trigger type must be one of: http, pubsub, storage."
  }
}

variable "pubsub_topic" {
  description = "The Pub/Sub topic to trigger the function (required if trigger_type is pubsub)"
  type        = string
  default     = null
}

variable "storage_bucket_trigger" {
  description = "The GCS bucket to trigger the function (required if trigger_type is storage)"
  type        = string
  default     = null
}

variable "event_type" {
  description = "The event type for storage triggers (e.g., google.cloud.storage.object.v1.finalized, google.cloud.storage.object.v1.deleted)"
  type        = string
  default     = null
}

variable "allow_unauthenticated" {
  description = "Whether to allow unauthenticated invocations of the function"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Additional labels to apply to the function and related resources"
  type        = map(string)
  default     = {}
}

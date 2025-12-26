# -----------------------------------------------------------------------------
# GCP Serverless Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project and Environment
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
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
# Function/Service Configuration
# -----------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the function or service"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.function_name))
    error_message = "Function name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "description" {
  description = "Description of the function or service"
  type        = string
  default     = ""
}

variable "deploy_type" {
  description = "Deployment type: 'function' for Cloud Functions, 'run' for Cloud Run"
  type        = string
  default     = "function"

  validation {
    condition     = contains(["function", "run"], var.deploy_type)
    error_message = "Deploy type must be 'function' or 'run'."
  }
}

variable "runtime" {
  description = "Runtime for Cloud Functions (e.g., python311, nodejs20, go121)"
  type        = string
  default     = "python311"

  validation {
    condition     = can(regex("^(python3(8|9|10|11|12)|nodejs(16|18|20)|go1(19|20|21|22)|java(11|17|21)|ruby3(0|2)|dotnet(6|8)|php8(1|2))$", var.runtime))
    error_message = "Runtime must be a valid Cloud Functions runtime."
  }
}

variable "entry_point" {
  description = "Entry point function name for Cloud Functions"
  type        = string
  default     = "main"
}

variable "container_image" {
  description = "Container image for Cloud Run (required when deploy_type is 'run')"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Container port for Cloud Run"
  type        = number
  default     = 8080
}

# -----------------------------------------------------------------------------
# Source Configuration
# -----------------------------------------------------------------------------

variable "source_archive_path" {
  description = "Local path to the source archive (zip file)"
  type        = string
  default     = ""
}

variable "source_archive_hash" {
  description = "Hash of the source archive for versioning"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Resource Limits
# -----------------------------------------------------------------------------

variable "memory" {
  description = "Memory allocation (e.g., 256Mi, 512Mi, 1Gi, 2Gi)"
  type        = string
  default     = "256Mi"

  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi)$", var.memory))
    error_message = "Memory must be specified in Mi or Gi (e.g., 256Mi, 1Gi)."
  }
}

variable "cpu" {
  description = "CPU allocation (e.g., 1, 2, 4)"
  type        = string
  default     = "1"
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 3600
    error_message = "Timeout must be between 1 and 3600 seconds."
  }
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0

  validation {
    condition     = var.min_instances >= 0
    error_message = "Minimum instances must be at least 0."
  }
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100

  validation {
    condition     = var.max_instances >= 1
    error_message = "Maximum instances must be at least 1."
  }
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per instance (Cloud Run only)"
  type        = number
  default     = 80

  validation {
    condition     = var.max_concurrency >= 1 && var.max_concurrency <= 1000
    error_message = "Max concurrency must be between 1 and 1000."
  }
}

variable "cpu_idle" {
  description = "Whether CPU should be throttled when no requests are being served"
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "Whether to allocate extra CPU during startup"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Environment Variables
# -----------------------------------------------------------------------------

variable "environment_variables" {
  description = "Environment variables for the function/service"
  type        = map(string)
  default     = {}
}

variable "build_environment_variables" {
  description = "Environment variables for the build process (Cloud Functions only)"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables from Secret Manager"
  type = list(object({
    key         = string
    secret_name = string
    version     = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vpc_connector" {
  description = "VPC connector for private network access"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting (ALL_TRAFFIC or PRIVATE_RANGES_ONLY)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "VPC egress must be ALL_TRAFFIC or PRIVATE_RANGES_ONLY."
  }
}

variable "ingress_settings" {
  description = "Ingress settings (ALLOW_ALL, ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB)"
  type        = string
  default     = "ALLOW_ALL"

  validation {
    condition     = contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], var.ingress_settings)
    error_message = "Ingress settings must be ALLOW_ALL, ALLOW_INTERNAL_ONLY, or ALLOW_INTERNAL_AND_GCLB."
  }
}

# -----------------------------------------------------------------------------
# Event Trigger Configuration
# -----------------------------------------------------------------------------

variable "event_trigger" {
  description = "Event trigger configuration for Cloud Functions"
  type = object({
    event_type   = string
    pubsub_topic = optional(string)
    retry_policy = optional(string, "RETRY_POLICY_RETRY")
    event_filters = optional(list(object({
      attribute = string
      value     = string
      operator  = optional(string)
    })))
  })
  default = null
}

# -----------------------------------------------------------------------------
# Health Probes (Cloud Run only)
# -----------------------------------------------------------------------------

variable "startup_probe" {
  description = "Startup probe configuration for Cloud Run"
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 3)
    failure_threshold     = optional(number, 3)
    http_get = optional(object({
      path = string
      port = optional(number, 8080)
    }))
    tcp_socket = optional(object({
      port = number
    }))
  })
  default = null
}

variable "liveness_probe" {
  description = "Liveness probe configuration for Cloud Run"
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 3)
    failure_threshold     = optional(number, 3)
    http_get = optional(object({
      path = string
      port = optional(number, 8080)
    }))
  })
  default = null
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to the function/service"
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "List of IAM members that can invoke the function/service"
  type        = list(string)
  default     = []
}

variable "service_account_roles" {
  description = "IAM roles to assign to the service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ]
}

# -----------------------------------------------------------------------------
# API Gateway Configuration
# -----------------------------------------------------------------------------

variable "enable_api_gateway" {
  description = "Enable API Gateway"
  type        = bool
  default     = false
}

variable "api_gateway_openapi_spec" {
  description = "OpenAPI specification for API Gateway"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Pub/Sub Configuration
# -----------------------------------------------------------------------------

variable "enable_pubsub" {
  description = "Enable Pub/Sub topic and subscription"
  type        = bool
  default     = false
}

variable "pubsub_message_retention_duration" {
  description = "Message retention duration for the topic"
  type        = string
  default     = "604800s" # 7 days
}

variable "pubsub_schema" {
  description = "Schema settings for the Pub/Sub topic"
  type = object({
    schema   = string
    encoding = string
  })
  default = null
}

variable "pubsub_ack_deadline_seconds" {
  description = "Acknowledgement deadline in seconds"
  type        = number
  default     = 20
}

variable "pubsub_subscription_retention_duration" {
  description = "Message retention duration for the subscription"
  type        = string
  default     = "604800s" # 7 days
}

variable "pubsub_retain_acked_messages" {
  description = "Retain acknowledged messages"
  type        = bool
  default     = false
}

variable "pubsub_enable_message_ordering" {
  description = "Enable message ordering"
  type        = bool
  default     = false
}

variable "pubsub_subscription_expiration_ttl" {
  description = "Subscription expiration TTL (empty string for never expire)"
  type        = string
  default     = "" # Never expire
}

variable "pubsub_retry_minimum_backoff" {
  description = "Minimum backoff for retry policy"
  type        = string
  default     = "10s"
}

variable "pubsub_retry_maximum_backoff" {
  description = "Maximum backoff for retry policy"
  type        = string
  default     = "600s"
}

variable "pubsub_push_endpoint" {
  description = "Push endpoint URL for the subscription"
  type        = string
  default     = ""
}

variable "pubsub_push_attributes" {
  description = "Push attributes for the subscription"
  type        = map(string)
  default     = {}
}

variable "pubsub_dead_letter_topic" {
  description = "Dead letter topic for failed messages"
  type        = string
  default     = ""
}

variable "pubsub_max_delivery_attempts" {
  description = "Maximum delivery attempts before sending to dead letter topic"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Cloud Scheduler Configuration
# -----------------------------------------------------------------------------

variable "schedule_cron" {
  description = "Cron schedule expression (empty to disable)"
  type        = string
  default     = ""
}

variable "schedule_timezone" {
  description = "Timezone for the schedule"
  type        = string
  default     = "UTC"
}

variable "schedule_attempt_deadline" {
  description = "Attempt deadline for scheduled jobs"
  type        = string
  default     = "320s"
}

variable "schedule_retry_count" {
  description = "Number of retry attempts for scheduled jobs"
  type        = number
  default     = 3
}

variable "schedule_max_retry_duration" {
  description = "Maximum retry duration for scheduled jobs"
  type        = string
  default     = "0s"
}

variable "schedule_min_backoff_duration" {
  description = "Minimum backoff duration for scheduled jobs"
  type        = string
  default     = "5s"
}

variable "schedule_max_backoff_duration" {
  description = "Maximum backoff duration for scheduled jobs"
  type        = string
  default     = "3600s"
}

variable "schedule_max_doublings" {
  description = "Maximum doublings for exponential backoff"
  type        = number
  default     = 5
}

variable "schedule_http_method" {
  description = "HTTP method for scheduled HTTP target"
  type        = string
  default     = "POST"

  validation {
    condition     = contains(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"], var.schedule_http_method)
    error_message = "HTTP method must be a valid HTTP method."
  }
}

variable "schedule_http_body" {
  description = "HTTP body for scheduled HTTP target"
  type        = string
  default     = ""
}

variable "schedule_http_headers" {
  description = "HTTP headers for scheduled HTTP target"
  type        = map(string)
  default     = {}
}

variable "schedule_use_pubsub" {
  description = "Use Pub/Sub target instead of HTTP target for scheduler"
  type        = bool
  default     = false
}

variable "schedule_pubsub_data" {
  description = "Pub/Sub message data for scheduled jobs"
  type        = string
  default     = ""
}

variable "schedule_pubsub_attributes" {
  description = "Pub/Sub message attributes for scheduled jobs"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels for all resources"
  type        = map(string)
  default     = {}
}

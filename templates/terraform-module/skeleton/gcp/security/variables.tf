# -----------------------------------------------------------------------------
# GCP Security Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Project and Environment
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources (e.g., KMS key ring)"
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
# KMS Configuration
# -----------------------------------------------------------------------------

variable "kms_key_rotation_period" {
  description = "Rotation period for KMS crypto key (default 90 days = 7776000s)"
  type        = string
  default     = "7776000s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.kms_key_rotation_period))
    error_message = "KMS key rotation period must be specified in seconds (e.g., '7776000s')."
  }
}

variable "kms_key_algorithm" {
  description = "Algorithm for KMS crypto key"
  type        = string
  default     = "GOOGLE_SYMMETRIC_ENCRYPTION"

  validation {
    condition = contains([
      "GOOGLE_SYMMETRIC_ENCRYPTION",
      "RSA_SIGN_PSS_2048_SHA256",
      "RSA_SIGN_PSS_3072_SHA256",
      "RSA_SIGN_PSS_4096_SHA256",
      "RSA_SIGN_PKCS1_2048_SHA256",
      "RSA_SIGN_PKCS1_3072_SHA256",
      "RSA_SIGN_PKCS1_4096_SHA256",
      "RSA_DECRYPT_OAEP_2048_SHA256",
      "RSA_DECRYPT_OAEP_3072_SHA256",
      "RSA_DECRYPT_OAEP_4096_SHA256",
      "EC_SIGN_P256_SHA256",
      "EC_SIGN_P384_SHA384"
    ], var.kms_key_algorithm)
    error_message = "Invalid KMS key algorithm specified."
  }
}

variable "kms_key_protection_level" {
  description = "Protection level for KMS crypto key (SOFTWARE or HSM)"
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.kms_key_protection_level)
    error_message = "KMS key protection level must be SOFTWARE or HSM."
  }
}

variable "kms_encrypter_decrypters" {
  description = "List of IAM members to grant encrypter/decrypter access to the KMS key"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Service Account Configuration
# -----------------------------------------------------------------------------

variable "service_account_roles" {
  description = "IAM roles to assign to the application service account"
  type        = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/cloudtrace.agent"
  ]
}

variable "create_service_account_key" {
  description = "Create and store a service account key in Secret Manager (use with caution)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Secret Manager Configuration
# -----------------------------------------------------------------------------

variable "secret_accessors" {
  description = "List of IAM members to grant access to the main application secret"
  type        = list(string)
  default     = []
}

variable "secret_data" {
  description = "Initial secret data for the main application secret (JSON object)"
  type        = map(string)
  default = {
    API_KEY     = "replace-me"
    JWT_SECRET  = "replace-me"
    APP_SECRET  = "replace-me"
    DB_PASSWORD = "replace-me"
  }
  sensitive = true
}

variable "additional_secrets" {
  description = "Map of additional secrets to create"
  type = map(object({
    secret_data = string
    accessors   = list(string)
    labels      = map(string)
  }))
  default   = {}
  sensitive = true
}

# -----------------------------------------------------------------------------
# Organization Policy Configuration
# -----------------------------------------------------------------------------

variable "enable_org_policies" {
  description = "Enable organization policies for the project"
  type        = bool
  default     = false
}

variable "allowed_policy_member_domains" {
  description = "List of allowed domains for IAM policy members (requires org policy admin)"
  type        = list(string)
  default     = null
}

variable "require_os_login" {
  description = "Require OS Login for compute instances"
  type        = bool
  default     = true
}

variable "restrict_vm_external_ips" {
  description = "Restrict external IPs on VMs"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Audit Configuration
# -----------------------------------------------------------------------------

variable "enable_audit_logs" {
  description = "Enable Cloud Audit Logs for all services"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

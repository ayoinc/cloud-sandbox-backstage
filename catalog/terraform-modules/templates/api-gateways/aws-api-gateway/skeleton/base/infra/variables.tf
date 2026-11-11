variable "api_name" {
  description = "Name of the API. Used as the name or name prefix of every resource."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.api_name)) && length(var.api_name) <= 40
    error_message = "The API name must be 2 to 40 lowercase letters, digits or hyphens and start with a letter."
  }
}

variable "description" {
  description = "Description of the API."
  type        = string
}

variable "api_version" {
  description = "Semantic version of the API. The major version names the stage (1.0.0 is served under /v1)."
  type        = string
  default     = "1.0.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.api_version))
    error_message = "The API version must look like 1.0.0."
  }
}

variable "aws_region" {
  description = "Region the API is deployed to."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags added to every resource, on top of the default ones."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Authentication and protection
# -----------------------------------------------------------------------------

variable "enable_auth" {
  description = "Require callers to authenticate with auth_type. When false the API is public."
  type        = bool
  default     = true
}

variable "auth_type" {
  description = "How callers authenticate: jwt (tokens of an external issuer, checked by a Lambda authorizer), apikey (API keys and a usage plan), cognito (a Cognito user pool created here) or none."
  type        = string
  default     = "jwt"

  validation {
    condition     = contains(["jwt", "apikey", "cognito", "none"], var.auth_type)
    error_message = "auth_type must be jwt, apikey, cognito or none."
  }
}

variable "jwt_issuer" {
  description = "Issuer (iss claim) of accepted tokens, for example https://login.example.com/. Required when auth_type is jwt."
  type        = string
  default     = ""
}

variable "jwt_audience" {
  description = "Audience (aud claim) accepted tokens must carry. Required when auth_type is jwt."
  type        = string
  default     = ""
}

variable "jwt_jwks_uri" {
  description = "URL of the issuer's JSON Web Key Set. Defaults to <jwt_issuer>/.well-known/jwks.json."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Put an AWS WAF web ACL with the AWS managed rule groups in front of the API."
  type        = bool
  default     = true
}

variable "enable_rate_limiting" {
  description = "Throttle requests to requests_per_second."
  type        = bool
  default     = true
}

variable "requests_per_second" {
  description = "Steady-state request rate allowed per client. The burst allowance is twice this value."
  type        = number
  default     = 100

  validation {
    condition     = var.requests_per_second >= 1 && var.requests_per_second <= 10000 && floor(var.requests_per_second) == var.requests_per_second
    error_message = "requests_per_second must be a whole number between 1 and 10000."
  }
}

# -----------------------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------------------

variable "lambda_runtime" {
  description = "Lambda runtime identifier of the function behind the API."
  type        = string
}

variable "lambda_handler" {
  description = "Entry point of the function in the deployment package."
  type        = string
}

variable "lambda_memory_size" {
  description = "Memory of the function in MB."
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout of the function in seconds. API Gateway itself waits at most 29 seconds."
  type        = number
  default     = 30
}

variable "lambda_package" {
  description = "Path of the deployment package, relative to this directory. The build-lambda action writes it."
  type        = string
  default     = "../build/lambda.zip"
}

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------

variable "enable_crud" {
  description = "Expose create, read, update and delete endpoints under /items, stored in a DynamoDB table."
  type        = bool
  default     = true
}

variable "endpoints" {
  description = "Additional endpoints routed to the function. Path parameters are written as {name}."
  type = list(object({
    path        = string
    method      = string
    description = optional(string, "")
  }))
  default = []

  validation {
    condition = alltrue([
      for e in var.endpoints :
      can(regex("^(/([a-zA-Z0-9._-]+|\\{[a-zA-Z0-9_]+\\}))+$", e.path)) && contains(["GET", "POST", "PUT", "DELETE"], upper(e.method))
    ])
    error_message = "Each endpoint needs a path such as /users or /users/{id} and one of the methods GET, POST, PUT, DELETE."
  }

  validation {
    condition     = length(distinct([for e in var.endpoints : "${upper(e.method)} ${e.path}"])) == length(var.endpoints)
    error_message = "Two endpoints have the same method and path."
  }

  validation {
    condition = alltrue([
      for e in var.endpoints :
      e.path != "/health" && !(var.enable_crud && (e.path == "/items" || startswith(e.path, "/items/")))
    ])
    error_message = "The paths /health and, with enable_crud, /items are already defined by this configuration."
  }
}

# -----------------------------------------------------------------------------
# Monitoring and logging
# -----------------------------------------------------------------------------

variable "enable_monitoring" {
  description = "Access logs, detailed metrics, alarms and a dashboard for the API."
  type        = bool
  default     = true
}

variable "enable_xray" {
  description = "Trace requests through API Gateway and the function with AWS X-Ray."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Days CloudWatch keeps the logs of the function and the API."
  type        = number
  default     = 30
}

variable "alarm_topic_arn" {
  description = "SNS topic notified when an alarm changes state. Leave empty to only show alarms in CloudWatch."
  type        = string
  default     = ""
}

variable "manage_account_logging_role" {
  description = "Create the IAM role API Gateway uses to write to CloudWatch Logs and set it in the account settings of this region. Set to false when the account already has one."
  type        = bool
  default     = true
}

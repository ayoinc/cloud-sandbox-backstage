variable "name" {
  description = "Lambda function name"
  type        = string
  default     = "${{ values.name }}"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "${{ values.aws_region }}"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "${{ values.environment }}"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "${{ values.runtime }}"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "main.handler"
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = ${{ values.memory_size }}
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = ${{ values.timeout }}
}

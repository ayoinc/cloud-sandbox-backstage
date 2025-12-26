# Common Module Variables

variable "enable_database" {
  description = "Whether to generate database password"
  type        = bool
  default     = false
}

variable "password_length" {
  description = "Length of the generated password"
  type        = number
  default     = 16
}

variable "password_special_chars" {
  description = "Include special characters in password"
  type        = bool
  default     = true
}

variable "suffix_byte_length" {
  description = "Byte length for random suffix"
  type        = number
  default     = 4
}

variable "generate_uuid" {
  description = "Whether to generate a UUID"
  type        = bool
  default     = false
}

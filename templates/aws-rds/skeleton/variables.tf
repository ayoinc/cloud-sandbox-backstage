variable "name" {
  description = "Name of the RDS instance"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the database purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "${{ values.region }}"
}

variable "engine" {
  description = "Database engine (postgres or mysql)"
  type        = string
  default     = "${{ values.engine }}"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "${{ values.engineVersion }}"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "${{ values.instanceClass }}"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = ${{ values.allocatedStorage }}
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = ${{ values.multiAz }}
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

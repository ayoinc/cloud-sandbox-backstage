# Common Module - Shared Resources
# This module contains common resources used across all cloud providers

# Random password for databases and secrets
resource "random_password" "database_password" {
  count   = var.enable_database ? 1 : 0
  length  = var.password_length
  special = var.password_special_chars
}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = var.suffix_byte_length
}

# Random UUID for resource tagging
resource "random_uuid" "resource_id" {
  count = var.generate_uuid ? 1 : 0
}

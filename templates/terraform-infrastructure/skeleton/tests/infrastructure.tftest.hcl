# =============================================================================
# Terraform Infrastructure Tests
# =============================================================================
# These tests validate the infrastructure configuration and ensure
# compliance with multi-cloud, security, and operational best practices.
#
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Test Variables - Base Configuration
# -----------------------------------------------------------------------------
variables {
  environment    = "staging"
  cloud_provider = "aws"
}

# =============================================================================
# ENVIRONMENT VALIDATION TESTS
# =============================================================================

run "environment_validation" {
  command = plan

  assert {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production"
  }
}

run "staging_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  assert {
    condition     = var.environment == "staging"
    error_message = "Staging environment should be accepted"
  }
}

run "production_environment" {
  command = plan

  variables {
    environment = "production"
  }

  assert {
    condition     = var.environment == "production"
    error_message = "Production environment should be accepted"
  }
}

# =============================================================================
# CLOUD PROVIDER VALIDATION TESTS
# =============================================================================

run "cloud_provider_aws" {
  command = plan

  variables {
    cloud_provider = "aws"
  }

  assert {
    condition     = contains(["aws", "azure", "gcp", "multi-cloud"], var.cloud_provider)
    error_message = "Cloud provider must be aws, azure, gcp, or multi-cloud"
  }
}

run "cloud_provider_azure" {
  command = plan

  variables {
    cloud_provider = "azure"
  }

  assert {
    condition     = var.cloud_provider == "azure"
    error_message = "Azure provider should be accepted"
  }
}

run "cloud_provider_gcp" {
  command = plan

  variables {
    cloud_provider = "gcp"
  }

  assert {
    condition     = var.cloud_provider == "gcp"
    error_message = "GCP provider should be accepted"
  }
}

run "cloud_provider_multicloud" {
  command = plan

  variables {
    cloud_provider = "multi-cloud"
  }

  assert {
    condition     = var.cloud_provider == "multi-cloud"
    error_message = "Multi-cloud provider should be accepted"
  }
}

# =============================================================================
# NETWORKING VALIDATION TESTS
# =============================================================================

run "vpc_cidr_validation" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/16"
  }

  assert {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

run "allowed_cidr_blocks_private" {
  command = plan

  assert {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All allowed CIDR blocks must be valid"
  }
}

# =============================================================================
# DATABASE VALIDATION TESTS
# =============================================================================

run "database_type_postgresql" {
  command = plan

  variables {
    database_type = "postgresql"
  }

  assert {
    condition     = contains(["postgresql", "mysql", "mongodb", "redis", "dynamodb", "cosmosdb"], var.database_type)
    error_message = "Database type must be a supported type"
  }
}

run "database_type_mysql" {
  command = plan

  variables {
    database_type = "mysql"
  }

  assert {
    condition     = var.database_type == "mysql"
    error_message = "MySQL database type should be accepted"
  }
}

# =============================================================================
# KUBERNETES VALIDATION TESTS
# =============================================================================

run "min_nodes_validation" {
  command = plan

  variables {
    min_nodes = 2
  }

  assert {
    condition     = var.min_nodes >= 1 && var.min_nodes <= 100
    error_message = "Min nodes must be between 1 and 100"
  }
}

run "max_nodes_validation" {
  command = plan

  variables {
    max_nodes = 10
  }

  assert {
    condition     = var.max_nodes >= 1 && var.max_nodes <= 1000
    error_message = "Max nodes must be between 1 and 1000"
  }
}

run "nodes_min_less_than_max" {
  command = plan

  variables {
    min_nodes = 2
    max_nodes = 10
  }

  assert {
    condition     = var.min_nodes <= var.max_nodes
    error_message = "Min nodes must be less than or equal to max nodes"
  }
}

# =============================================================================
# COMPLIANCE VALIDATION TESTS
# =============================================================================

run "compliance_framework_none" {
  command = plan

  variables {
    compliance_framework = "none"
  }

  assert {
    condition     = contains(["none", "cis", "pci-dss", "hipaa", "sox", "gdpr"], var.compliance_framework)
    error_message = "Compliance framework must be a supported framework"
  }
}

run "compliance_framework_pci" {
  command = plan

  variables {
    compliance_framework = "pci-dss"
  }

  assert {
    condition     = var.compliance_framework == "pci-dss"
    error_message = "PCI-DSS compliance framework should be accepted"
  }
}

run "compliance_framework_hipaa" {
  command = plan

  variables {
    compliance_framework = "hipaa"
  }

  assert {
    condition     = var.compliance_framework == "hipaa"
    error_message = "HIPAA compliance framework should be accepted"
  }
}

# =============================================================================
# MONITORING VALIDATION TESTS
# =============================================================================

run "monitoring_solution_native" {
  command = plan

  variables {
    monitoring_solution = "native"
  }

  assert {
    condition     = contains(["native", "prometheus-grafana", "elastic-stack", "datadog", "new-relic"], var.monitoring_solution)
    error_message = "Monitoring solution must be a supported platform"
  }
}

run "monitoring_solution_prometheus" {
  command = plan

  variables {
    monitoring_solution = "prometheus-grafana"
  }

  assert {
    condition     = var.monitoring_solution == "prometheus-grafana"
    error_message = "Prometheus-Grafana monitoring should be accepted"
  }
}

run "log_retention_validation" {
  command = plan

  variables {
    log_retention_days = 30
  }

  assert {
    condition     = contains([7, 30, 90, 365], var.log_retention_days)
    error_message = "Log retention must be 7, 30, 90, or 365 days"
  }
}

# =============================================================================
# SECURITY FEATURE TESTS
# =============================================================================

run "security_features_enabled_prod" {
  command = plan

  variables {
    environment              = "production"
    enable_kms               = true
    enable_secrets_manager   = true
    enable_backup            = true
    enable_waf               = true
  }

  assert {
    condition     = var.enable_kms == true
    error_message = "KMS should be enabled for production"
  }

  assert {
    condition     = var.enable_secrets_manager == true
    error_message = "Secrets Manager should be enabled for production"
  }

  assert {
    condition     = var.enable_backup == true
    error_message = "Backup should be enabled for production"
  }
}

# =============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATION TESTS
# =============================================================================

run "environment_configs_structure" {
  command = plan

  assert {
    condition     = can(var.environment_configs["development"])
    error_message = "Environment configs must include development"
  }

  assert {
    condition     = can(var.environment_configs["staging"])
    error_message = "Environment configs must include staging"
  }

  assert {
    condition     = can(var.environment_configs["production"])
    error_message = "Environment configs must include production"
  }
}

run "production_config_has_higher_resources" {
  command = plan

  assert {
    condition     = var.environment_configs["production"].node_count >= var.environment_configs["development"].node_count
    error_message = "Production should have more nodes than development"
  }

  assert {
    condition     = var.environment_configs["production"].backup_retention >= var.environment_configs["development"].backup_retention
    error_message = "Production should have longer backup retention than development"
  }
}

# =============================================================================
# OUTPUT VALIDATION TESTS
# =============================================================================

run "outputs_are_defined" {
  command = plan

  assert {
    condition     = output.infrastructure_name != null
    error_message = "Infrastructure name output must be defined"
  }

  assert {
    condition     = output.environment != null
    error_message = "Environment output must be defined"
  }

  assert {
    condition     = output.cloud_provider != null
    error_message = "Cloud provider output must be defined"
  }

  assert {
    condition     = output.compliance_framework != null
    error_message = "Compliance framework output must be defined"
  }
}

# =============================================================================
# COST OPTIMIZATION TESTS
# =============================================================================

run "cost_optimization_dev" {
  command = plan

  variables {
    environment              = "development"
    enable_cost_optimization = true
  }

  assert {
    condition     = var.enable_cost_optimization == true
    error_message = "Cost optimization should be enabled for development"
  }
}

# =============================================================================
# DISASTER RECOVERY TESTS
# =============================================================================

run "disaster_recovery_prod" {
  command = plan

  variables {
    environment               = "production"
    enable_disaster_recovery  = true
  }

  assert {
    condition     = var.enable_disaster_recovery == true
    error_message = "Disaster recovery should be enabled for production"
  }
}

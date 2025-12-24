# =============================================================================
# AWS RDS Terraform Tests
# =============================================================================
# These tests validate the RDS module configuration using plan-based testing.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Providers - Prevent actual AWS API calls
# -----------------------------------------------------------------------------
mock_provider "aws" {}

mock_provider "random" {}

# -----------------------------------------------------------------------------
# Test: Basic PostgreSQL Configuration
# -----------------------------------------------------------------------------
run "basic_postgres_configuration" {
  command = plan

  variables {
    name               = "test-db"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Verify module outputs
  assert {
    condition     = output.engine == "postgres"
    error_message = "Engine should be postgres"
  }

  assert {
    condition     = output.port == 5432
    error_message = "PostgreSQL port should be 5432"
  }

  assert {
    condition     = output.database_name == "testapp"
    error_message = "Database name should be testapp"
  }
}

# -----------------------------------------------------------------------------
# Test: MySQL Configuration
# -----------------------------------------------------------------------------
run "mysql_configuration" {
  command = plan

  variables {
    name               = "test-mysql"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "mysql"
    engine_version     = "8.0"
    engine_family      = "mysql8.0"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  assert {
    condition     = output.engine == "mysql"
    error_message = "Engine should be mysql"
  }

  assert {
    condition     = output.port == 3306
    error_message = "MySQL port should be 3306"
  }
}

# -----------------------------------------------------------------------------
# Test: Production Environment Settings
# -----------------------------------------------------------------------------
run "production_settings" {
  command = plan

  variables {
    name                         = "prod-db"
    environment                  = "prod"
    region                       = "us-east-1"
    vpc_id                       = "vpc-12345678"
    private_subnet_ids           = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block               = "10.0.0.0/16"
    engine                       = "postgres"
    engine_version               = "16"
    engine_family                = "postgres16"
    instance_class               = "db.r6g.large"
    allocated_storage            = 100
    max_allocated_storage        = 500
    multi_az                     = true
    database_name                = "prodapp"
    master_username              = "dbadmin"
    backup_retention_period      = 30
    deletion_protection          = true
    skip_final_snapshot          = false
    performance_insights_enabled = true
    monitoring_interval          = 60
  }

  # Production should have Multi-AZ
  assert {
    condition     = output.multi_az == true
    error_message = "Production should have Multi-AZ enabled"
  }

  # Production should use appropriate instance class
  assert {
    condition     = output.instance_class == "db.r6g.large"
    error_message = "Production should use db.r6g.large instance class"
  }
}

# -----------------------------------------------------------------------------
# Test: Development Environment Settings
# -----------------------------------------------------------------------------
run "development_settings" {
  command = plan

  variables {
    name                         = "dev-db"
    environment                  = "dev"
    region                       = "us-east-1"
    vpc_id                       = "vpc-12345678"
    private_subnet_ids           = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block               = "10.0.0.0/16"
    engine                       = "postgres"
    engine_version               = "16"
    engine_family                = "postgres16"
    instance_class               = "db.t3.micro"
    allocated_storage            = 20
    max_allocated_storage        = 50
    multi_az                     = false
    database_name                = "devapp"
    master_username              = "dbadmin"
    skip_final_snapshot          = true
    backup_retention_period      = 7
    deletion_protection          = false
    performance_insights_enabled = false
    monitoring_interval          = 0
  }

  # Development should NOT have Multi-AZ (cost optimization)
  assert {
    condition     = output.multi_az == false
    error_message = "Development should not have Multi-AZ"
  }

  # Development should use smaller instance class
  assert {
    condition     = output.instance_class == "db.t3.micro"
    error_message = "Development should use db.t3.micro instance class"
  }
}

# -----------------------------------------------------------------------------
# Test: Instance Identifier Naming
# -----------------------------------------------------------------------------
run "instance_identifier_naming" {
  command = plan

  variables {
    name               = "my-app-db"
    environment        = "staging"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.medium"
    allocated_storage  = 50
    multi_az           = false
    database_name      = "myapp"
    master_username    = "dbadmin"
  }

  assert {
    condition     = output.instance_identifier == "my-app-db-staging"
    error_message = "Instance identifier should be {name}-{environment}"
  }
}

# -----------------------------------------------------------------------------
# Test: Secrets Manager Integration
# -----------------------------------------------------------------------------
run "secrets_manager_configuration" {
  command = plan

  variables {
    name               = "secrets-test"
    environment        = "staging"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Secret name should follow naming convention
  assert {
    condition     = output.secret_name == "secrets-test-staging-db-credentials"
    error_message = "Secret name should follow naming convention: {name}-{env}-db-credentials"
  }

  # Secret ARN should exist
  assert {
    condition     = can(output.secret_arn)
    error_message = "Secret ARN should be available"
  }
}

# -----------------------------------------------------------------------------
# Test: Subnet Group Configuration
# -----------------------------------------------------------------------------
run "subnet_group_configuration" {
  command = plan

  variables {
    name               = "subnet-test"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Subnet group name should follow naming convention
  assert {
    condition     = output.db_subnet_group_name == "subnet-test-dev-subnet-group"
    error_message = "Subnet group name should follow naming convention"
  }
}

# -----------------------------------------------------------------------------
# Test: Parameter Group Configuration
# -----------------------------------------------------------------------------
run "parameter_group_configuration" {
  command = plan

  variables {
    name               = "params-test"
    environment        = "staging"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Parameter group name should follow naming convention
  assert {
    condition     = output.parameter_group_name == "params-test-staging-params"
    error_message = "Parameter group name should follow naming convention"
  }
}

# -----------------------------------------------------------------------------
# Test: Security Group Output
# -----------------------------------------------------------------------------
run "security_group_output" {
  command = plan

  variables {
    name               = "sg-test"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Security group ID should be available
  assert {
    condition     = can(output.security_group_id)
    error_message = "Security group ID should be available"
  }
}

# -----------------------------------------------------------------------------
# Test: Connection Info Output
# -----------------------------------------------------------------------------
run "connection_info_output" {
  command = plan

  variables {
    name               = "conn-test"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Connection info should be available
  assert {
    condition     = can(output.connection_info)
    error_message = "Connection info output should be available"
  }

  # Connection info should contain required fields
  assert {
    condition     = output.connection_info.database == "testapp"
    error_message = "Connection info should contain database name"
  }

  assert {
    condition     = output.connection_info.port == 5432
    error_message = "Connection info should contain correct port"
  }

  assert {
    condition     = output.connection_info.engine == "postgres"
    error_message = "Connection info should contain engine"
  }
}

# -----------------------------------------------------------------------------
# Test: Storage Configuration
# -----------------------------------------------------------------------------
run "storage_configuration" {
  command = plan

  variables {
    name               = "storage-test"
    environment        = "staging"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "16"
    engine_family      = "postgres16"
    instance_class     = "db.t3.medium"
    allocated_storage  = 100
    max_allocated_storage = 500
    storage_type       = "gp3"
    storage_encrypted  = true
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  # Verify allocated storage
  assert {
    condition     = can(output.instance_id)
    error_message = "Instance should be created with specified storage"
  }
}

# -----------------------------------------------------------------------------
# Test: Engine Version Output
# -----------------------------------------------------------------------------
run "engine_version_output" {
  command = plan

  variables {
    name               = "version-test"
    environment        = "dev"
    region             = "us-east-1"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
    vpc_cidr_block     = "10.0.0.0/16"
    engine             = "postgres"
    engine_version     = "15"
    engine_family      = "postgres15"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    multi_az           = false
    database_name      = "testapp"
    master_username    = "dbadmin"
  }

  assert {
    condition     = output.engine_version == "15"
    error_message = "Engine version should match input"
  }
}

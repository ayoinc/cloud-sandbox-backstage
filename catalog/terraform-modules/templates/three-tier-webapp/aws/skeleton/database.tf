# -----------------------------------------------------------------------------
# Data tier: RDS in the isolated database subnets, reachable only from the
# application tier. The master password is generated and kept in Secrets
# Manager by RDS.
# -----------------------------------------------------------------------------

locals {
  database_settings = {
    postgres = {
      engine_version = "17"
      family         = "postgres17"
      port           = 5432
      log_exports    = ["postgresql", "upgrade"]
    }
    mysql = {
      engine_version = "8.4"
      family         = "mysql8.4"
      port           = 3306
      log_exports    = ["error", "slowquery"]
    }
    mariadb = {
      engine_version = "11.4"
      family         = "mariadb11.4"
      port           = 3306
      log_exports    = ["error", "slowquery"]
    }
  }

  database = local.database_settings[var.database_engine]
}

#trivy:ignore:AVD-AWS-0104 The module's security group allows outbound traffic; the database subnets have no route to the internet.
module "rds" {
  source = "git::https://github.com/ayoinc/cloud-sandbox-backstage.git//catalog/terraform-modules/aws/resources/database/rds?ref=${{ values.moduleRef }}"

  name        = var.project_name
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.database_subnet_ids

  engine                          = var.database_engine
  engine_version                  = coalesce(var.database_engine_version, local.database.engine_version)
  parameter_group_family          = coalesce(var.database_parameter_group_family, local.database.family)
  port                            = local.database.port
  enabled_cloudwatch_logs_exports = local.database.log_exports

  instance_class        = var.database_instance_class
  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage
  multi_az              = var.multi_az

  database_name               = var.database_name
  master_username             = var.database_username
  manage_master_user_password = true

  allowed_security_group_ids = [aws_security_group.app.id]

  deletion_protection = local.is_production
  skip_final_snapshot = !local.is_production
}

# -----------------------------------------------------------------------------
# Data warehouse: an Amazon Redshift cluster in the private subnets, sized by
# warehouse_size. Redshift generates the admin password and keeps it in
# Secrets Manager.
# -----------------------------------------------------------------------------

locals {
  warehouse_nodes = {
    small  = 2
    medium = 4
    large  = 8
  }

  warehouse_identifier = "${local.name_prefix}-warehouse"
  warehouse_arn        = "arn:${local.partition}:redshift:${var.region}:${local.account_id}:cluster:${local.warehouse_identifier}"

  # The warehouse reads the curated zone through an external schema that the
  # pipeline creates from the zone's Glue database.
  publishes_to_warehouse  = var.enable_data_warehouse && var.enable_data_lake && var.enable_data_catalog
  warehouse_lake_schema   = "lake_curated"
  warehouse_role_attached = var.enable_data_warehouse && var.enable_data_lake
}

resource "aws_redshift_subnet_group" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  name        = local.warehouse_identifier
  description = "Private subnets of the ${local.name_prefix} data warehouse"
  subnet_ids  = module.vpc[0].private_subnet_ids
}

resource "aws_security_group" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  name        = local.warehouse_identifier
  description = "Access to the ${local.name_prefix} data warehouse"
  vpc_id      = module.vpc[0].vpc_id

  tags = {
    Name = local.warehouse_identifier
  }
}

resource "aws_vpc_security_group_ingress_rule" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  security_group_id = aws_security_group.warehouse[0].id
  description       = "Redshift from inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 5439
  to_port           = 5439
  ip_protocol       = "tcp"
}

resource "aws_redshift_parameter_group" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  name        = local.warehouse_identifier
  description = "Parameters of the ${local.name_prefix} data warehouse"
  family      = "redshift-2.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }
}

resource "aws_redshift_cluster" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  cluster_identifier = local.warehouse_identifier
  database_name      = var.warehouse_database_name

  node_type       = var.warehouse_node_type
  cluster_type    = "multi-node"
  number_of_nodes = local.warehouse_nodes[var.warehouse_size]

  master_username                   = var.warehouse_admin_username
  manage_master_password            = true
  master_password_secret_kms_key_id = local.kms_key_arn

  cluster_subnet_group_name    = aws_redshift_subnet_group.warehouse[0].name
  vpc_security_group_ids       = [aws_security_group.warehouse[0].id]
  cluster_parameter_group_name = aws_redshift_parameter_group.warehouse[0].name
  publicly_accessible          = false

  # Without the customer managed key Redshift encrypts with a key it owns.
  encrypted  = true
  kms_key_id = local.kms_key_arn

  iam_roles            = local.warehouse_role_attached ? [module.role["warehouse"].role_arn] : []
  default_iam_role_arn = local.warehouse_role_attached ? module.role["warehouse"].role_arn : null

  automated_snapshot_retention_period = local.is_production ? 14 : 1
  skip_final_snapshot                 = !local.is_production
  final_snapshot_identifier           = local.is_production ? "${local.warehouse_identifier}-final" : null
}

resource "aws_redshift_logging" "warehouse" {
  count = var.enable_data_warehouse ? 1 : 0

  cluster_identifier   = aws_redshift_cluster.warehouse[0].id
  log_destination_type = "cloudwatch"
  log_exports          = ["connectionlog", "userlog", "useractivitylog"]
}

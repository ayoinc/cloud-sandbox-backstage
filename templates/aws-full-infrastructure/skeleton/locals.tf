data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394: Zones are taken in name order, so a zone added by AWS does not move existing subnets
  state = "available"

  # Only zones every account has, so the list does not change when an opt-in
  # zone or Local Zone is enabled.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  azs        = slice(data.aws_availability_zones.available.names, 0, min(3, length(data.aws_availability_zones.available.names)))

  tags = merge(var.tags, {
    Project     = var.project_name
    Component   = var.component_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  })

  # Subnet names grouped by type, in name order. A subnet goes to the
  # availability zone at its position within its type, so "public-a" and
  # "public-b" land in different zones.
  subnet_names = {
    for type in ["public", "private", "isolated"] :
    type => sort([for subnet in var.subnet_configurations : subnet.name if subnet.type == type])
  }

  subnets = var.enable_networking ? {
    for subnet in var.subnet_configurations : subnet.name => {
      cidr = subnet.cidr
      type = subnet.type
      az   = local.azs[index(local.subnet_names[subnet.type], subnet.name) % length(local.azs)]
    }
  } : {}

  has_public_subnets = var.enable_networking && length(local.subnet_names["public"]) > 0
  create_nat_gateway = local.has_public_subnets && var.enable_nat_gateway

  # The network every other category deploys into: the VPC created here, or an
  # existing one when the networking category is disabled.
  vpc_id             = var.enable_networking ? aws_vpc.main[0].id : var.existing_vpc_id
  private_subnet_ids = var.enable_networking ? [for name in local.subnet_names["private"] : aws_subnet.main[name].id] : var.existing_private_subnet_ids

  # One private subnet per availability zone, as a transit gateway attachment requires.
  private_subnet_names_by_az = {
    for name in local.subnet_names["private"] : local.subnets[name].az => name... if var.enable_networking
  }
}

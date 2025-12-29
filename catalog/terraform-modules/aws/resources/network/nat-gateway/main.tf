terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  create_eip       = var.connectivity_type == "public" && var.create_eip
  use_existing_eip = var.connectivity_type == "public" && !var.create_eip && length(var.allocation_ids) > 0
}

resource "aws_eip" "this" {
  count = local.create_eip ? length(var.subnet_ids) : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
      Project     = var.project_name
      Environment = var.environment
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = length(var.subnet_ids)

  subnet_id         = var.subnet_ids[count.index]
  connectivity_type = var.connectivity_type

  allocation_id = var.connectivity_type == "public" ? (
    local.create_eip ? aws_eip.this[count.index].id : (
      local.use_existing_eip ? var.allocation_ids[count.index] : null
    )
  ) : null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-nat-gw-${count.index + 1}"
      Project     = var.project_name
      Environment = var.environment
    }
  )

  depends_on = [aws_eip.this]
}

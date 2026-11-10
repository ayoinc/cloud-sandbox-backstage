# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  count = var.enable_networking ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name
  }
}

# The default security group has no rules, so nothing can use it by accident.
resource "aws_default_security_group" "main" {
  count = var.enable_networking ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${local.name}-default"
  }
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.name}-${each.key}"
    Type = each.value.type
  }
}

# -----------------------------------------------------------------------------
# Internet and NAT gateways
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = local.name
  }
}

resource "aws_eip" "nat" {
  count = local.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${local.name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = local.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.main[local.subnet_names["public"][0]].id

  tags = {
    Name = local.name
  }

  depends_on = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# Route tables: one per subnet type
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  count = local.has_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route" "public_internet" {
  count = local.has_public_subnets ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id
}

resource "aws_route_table" "private" {
  count = var.enable_networking ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${local.name}-private"
  }
}

resource "aws_route" "private_nat" {
  count = local.create_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table" "isolated" {
  count = var.enable_networking ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${local.name}-isolated"
  }
}

resource "aws_route_table_association" "main" {
  for_each = local.subnets

  subnet_id = aws_subnet.main[each.key].id
  route_table_id = (
    each.value.type == "public" ? aws_route_table.public[0].id :
    each.value.type == "private" ? aws_route_table.private[0].id :
    aws_route_table.isolated[0].id
  )
}

# -----------------------------------------------------------------------------
# VPN gateway (optional)
# -----------------------------------------------------------------------------
resource "aws_vpn_gateway" "main" {
  count = var.enable_networking && var.enable_vpn_gateway ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = local.name
  }
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.enable_networking && var.enable_vpn_gateway ? 1 : 0

  vpn_gateway_id = aws_vpn_gateway.main[0].id
  route_table_id = aws_route_table.private[0].id
}

# -----------------------------------------------------------------------------
# Transit gateway (optional)
# -----------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "main" {
  count = var.enable_networking && var.enable_transit_gateway ? 1 : 0

  description                     = "Transit gateway of ${local.name}"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  auto_accept_shared_attachments  = "disable"

  tags = {
    Name = local.name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  count = var.enable_networking && var.enable_transit_gateway && length(local.private_subnet_names_by_az) > 0 ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main[0].id
  vpc_id             = aws_vpc.main[0].id
  subnet_ids         = [for names in values(local.private_subnet_names_by_az) : aws_subnet.main[names[0]].id]

  tags = {
    Name = local.name
  }
}

# -----------------------------------------------------------------------------
# VPC flow logs
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_networking ? 1 : 0

  name              = "/aws/vpc/${local.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_networking ? 1 : 0

  name = "${local.name}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_networking ? 1 : 0

  name = "${local.name}-flow-logs"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count = var.enable_networking ? 1 : 0

  vpc_id          = aws_vpc.main[0].id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = {
    Name = local.name
  }
}

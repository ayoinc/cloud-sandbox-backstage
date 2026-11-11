{%- if values.cloud == 'aws' -%}
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)
}

resource "aws_vpc" "main" {
  cidr_block           = var.network_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.prefix
  }
}

resource "aws_subnet" "private" {
  for_each = { for index, zone in local.availability_zones : zone => index }

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.network_cidr, 4, each.value)
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-private-${each.key}"
    tier = "private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Adopting the default security group with no rules closes it.
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-default"
  }
}

# The `enabled` meta-argument switches the resource off without turning it
# into a list the way `count` does.
resource "aws_flow_log" "main" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination_type     = "s3"
  log_destination          = "${local.log_bucket_arn}/vpc-flow-logs/"
  max_aggregation_interval = 600

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = {
    Name = local.prefix
  }

  depends_on = [aws_s3_bucket_policy.logs]

  lifecycle {
    enabled = var.enable_flow_logs
  }
}
{%- elif values.cloud == 'azure' -%}
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.network_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "private" {
  name                            = "snet-private"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = [cidrsubnet(var.network_cidr, 4, 0)]
  default_outbound_access_enabled = false

  service_endpoint {
    service = "Microsoft.Storage"
  }
}

# A network security group without rules keeps the Azure defaults: traffic
# inside the virtual network is allowed, inbound traffic from the internet is
# denied.
resource "azurerm_network_security_group" "private" {
  name                = "nsg-${local.prefix}-private"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}
{%- else -%}
resource "google_compute_network" "main" {
  name                    = local.prefix
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "private" {
  name                     = "${local.prefix}-private"
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = cidrsubnet(var.network_cidr, 4, 0)
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# The `enabled` meta-argument switches the resources off without turning them
# into lists the way `count` does.
resource "google_compute_router" "main" {
  name    = local.prefix
  region  = var.region
  network = google_compute_network.main.id

  lifecycle {
    enabled = var.enable_nat
  }
}

resource "google_compute_router_nat" "main" {
  name                               = local.prefix
  region                             = var.region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  lifecycle {
    enabled = var.enable_nat
  }
}
{%- endif %}

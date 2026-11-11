{%- set aws = values.provider == 'aws' or values.provider == 'multi-cloud' -%}
{%- set azure = values.provider == 'azure' or values.provider == 'multi-cloud' -%}
{%- set gcp = values.provider == 'gcp' or values.provider == 'multi-cloud' -%}
# ${{ values.name }}
#
# Each building block is a submodule switched on by an enable_* variable.
{%- if aws %}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

module "aws_security" {
  count  = var.enable_security ? 1 : 0
  source = "./aws/security"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}

module "aws_network" {
  count  = var.enable_network ? 1 : 0
  source = "./aws/network"

  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr           = var.aws_vpc_cidr
  availability_zones = var.aws_availability_zones
  kms_key_arn        = one(module.aws_security[*].kms_key_arn)
  tags               = local.common_tags
}

module "aws_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./aws/storage"

  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = one(module.aws_security[*].kms_key_arn)
  tags         = local.common_tags
}

module "aws_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./aws/compute"

  environment  = var.environment
  project_name = var.project_name
  vpc_id       = one(module.aws_network[*].vpc_id)
  subnet_ids   = flatten(module.aws_network[*].private_subnet_ids)
  tags         = local.common_tags
}

module "aws_database" {
  count  = var.enable_database ? 1 : 0
  source = "./aws/database"

  environment             = var.environment
  project_name            = var.project_name
  vpc_id                  = one(module.aws_network[*].vpc_id)
  subnet_ids              = flatten(module.aws_network[*].database_subnet_ids)
  allowed_security_groups = module.aws_compute[*].security_group_id
  kms_key_arn             = one(module.aws_security[*].kms_key_arn)
  tags                    = local.common_tags
}

module "aws_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./aws/kubernetes"

  environment  = var.environment
  project_name = var.project_name
  vpc_id       = one(module.aws_network[*].vpc_id)
  subnet_ids   = flatten(module.aws_network[*].private_subnet_ids)
  kms_key_arn  = one(module.aws_security[*].kms_key_arn)
  tags         = local.common_tags
}

module "aws_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./aws/serverless"

  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = one(module.aws_security[*].kms_key_arn)
  tags         = local.common_tags
}

module "aws_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./aws/observability"

  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = one(module.aws_security[*].kms_key_arn)
  tags         = local.common_tags
}
{%- endif %}
{%- if azure %}

# -----------------------------------------------------------------------------
# Azure
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = local.azure_resource_group_name
  location = var.azure_location
  tags     = local.common_tags
}

module "azure_network" {
  count  = var.enable_network ? 1 : 0
  source = "./azure/network"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_cidr           = var.azure_vnet_cidr
  tags                = local.common_tags
}

module "azure_security" {
  count  = var.enable_security ? 1 : 0
  source = "./azure/security"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "azure_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./azure/storage"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "azure_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./azure/compute"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = one(module.azure_network[*].subnet_ids["private"])
  tags                = local.common_tags
}

module "azure_database" {
  count  = var.enable_database ? 1 : 0
  source = "./azure/database"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = one(module.azure_network[*].subnet_ids["database"])
  tags                = local.common_tags
}

module "azure_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./azure/kubernetes"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  subnet_id           = one(module.azure_network[*].subnet_ids["kubernetes"])
  tags                = local.common_tags

  # The network module attaches a NAT gateway to the Kubernetes subnet.
  outbound_type = "userAssignedNATGateway"
}

module "azure_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./azure/serverless"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

module "azure_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./azure/observability"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}
{%- endif %}
{%- if gcp %}

# -----------------------------------------------------------------------------
# Google Cloud
# -----------------------------------------------------------------------------

locals {
  gcp_zone = coalesce(var.gcp_zone, "${var.gcp_region}-a")

  # APIs needed by the features that are switched on.
  gcp_apis = var.gcp_enable_apis ? toset(concat(
    ["cloudresourcemanager.googleapis.com", "iam.googleapis.com"],
    var.enable_network || var.enable_compute ? ["compute.googleapis.com", "dns.googleapis.com", "servicenetworking.googleapis.com"] : [],
    var.enable_security ? ["cloudkms.googleapis.com", "secretmanager.googleapis.com"] : [],
    var.enable_storage ? ["storage.googleapis.com", "file.googleapis.com"] : [],
    var.enable_database ? ["sqladmin.googleapis.com", "redis.googleapis.com", "secretmanager.googleapis.com"] : [],
    var.enable_kubernetes ? ["container.googleapis.com", "artifactregistry.googleapis.com"] : [],
    var.enable_serverless ? ["run.googleapis.com", "cloudfunctions.googleapis.com", "cloudbuild.googleapis.com", "pubsub.googleapis.com", "cloudscheduler.googleapis.com"] : [],
    var.enable_observability ? ["logging.googleapis.com", "monitoring.googleapis.com"] : [],
  )) : toset([])
}

# The APIs stay enabled when the module is destroyed, because other workloads
# in the project may rely on them.
resource "google_project_service" "this" {
  for_each = local.gcp_apis

  project            = var.gcp_project_id
  service            = each.value
  disable_on_destroy = false
}

module "gcp_security" {
  count  = var.enable_security ? 1 : 0
  source = "./gcp/security"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_network" {
  count  = var.enable_network ? 1 : 0
  source = "./gcp/network"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  network_cidr = var.gcp_network_cidr
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./gcp/storage"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  kms_key_id   = one(module.gcp_security[*].kms_key_id)
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./gcp/compute"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  zone         = local.gcp_zone
  network_name = one(module.gcp_network[*].network_name)
  subnet_name  = one(module.gcp_network[*].subnet_names[0])
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_database" {
  count  = var.enable_database ? 1 : 0
  source = "./gcp/database"

  environment      = var.environment
  project_name     = var.project_name
  project_id       = var.gcp_project_id
  region           = var.gcp_region
  network_id       = one(module.gcp_network[*].network_id)
  private_ip_range = one(module.gcp_network[*].private_ip_range)
  labels           = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./gcp/kubernetes"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  network_name = one(module.gcp_network[*].network_name)
  subnet_name  = one(module.gcp_network[*].subnet_names[0])
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./gcp/serverless"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}

module "gcp_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./gcp/observability"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels

  depends_on = [google_project_service.this]
}
{%- endif %}

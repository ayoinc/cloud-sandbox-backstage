# ==============================================================================
# ${{ values.name }}
# ${{ values.description }}
# ==============================================================================

{%- if values.provider == 'aws' or values.provider == 'multi-cloud' %}

# ==============================================================================
# AWS Modules
# ==============================================================================

module "aws_network" {
  count  = var.enable_network ? 1 : 0
  source = "./aws/network"

  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr           = var.aws_vpc_cidr
  availability_zones = var.aws_availability_zones
  tags               = local.common_tags
}

module "aws_security" {
  count  = var.enable_security ? 1 : 0
  source = "./aws/security"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}

module "aws_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./aws/storage"

  environment  = var.environment
  project_name = var.project_name
  kms_key_arn  = var.enable_security ? module.aws_security[0].kms_key_arn : null
  tags         = local.common_tags
}

module "aws_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./aws/compute"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = var.enable_network ? module.aws_network[0].vpc_id : null
  subnet_ids         = var.enable_network ? module.aws_network[0].private_subnet_ids : []
  tags               = local.common_tags

  depends_on = [module.aws_network]
}

module "aws_database" {
  count  = var.enable_database ? 1 : 0
  source = "./aws/database"

  environment   = var.environment
  project_name  = var.project_name
  vpc_id        = var.enable_network ? module.aws_network[0].vpc_id : null
  subnet_ids    = var.enable_network ? module.aws_network[0].private_subnet_ids : []
  kms_key_arn   = var.enable_security ? module.aws_security[0].kms_key_arn : null
  tags          = local.common_tags

  depends_on = [module.aws_network, module.aws_security]
}

module "aws_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./aws/observability"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}

module "aws_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./aws/kubernetes"

  environment  = var.environment
  project_name = var.project_name
  vpc_id       = var.enable_network ? module.aws_network[0].vpc_id : null
  subnet_ids   = var.enable_network ? module.aws_network[0].private_subnet_ids : []
  tags         = local.common_tags

  depends_on = [module.aws_network]
}

module "aws_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./aws/serverless"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags
}
{%- endif %}

{%- if values.provider == 'azure' or values.provider == 'multi-cloud' %}

# ==============================================================================
# Azure Modules
# ==============================================================================

resource "azurerm_resource_group" "main" {
  count    = var.enable_network ? 1 : 0
  name     = local.azure_resource_group_name
  location = var.azure_location
  tags     = local.common_tags
}

module "azure_network" {
  count  = var.enable_network ? 1 : 0
  source = "./azure/network"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  vnet_cidr           = var.azure_vnet_cidr
  tags                = local.common_tags
}

module "azure_security" {
  count  = var.enable_security ? 1 : 0
  source = "./azure/security"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

module "azure_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./azure/storage"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

module "azure_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./azure/compute"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  subnet_id           = var.enable_network ? module.azure_network[0].subnet_ids["private"] : null
  tags                = local.common_tags

  depends_on = [module.azure_network]
}

module "azure_database" {
  count  = var.enable_database ? 1 : 0
  source = "./azure/database"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  subnet_id           = var.enable_network ? module.azure_network[0].subnet_ids["database"] : null
  tags                = local.common_tags

  depends_on = [module.azure_network]
}

module "azure_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./azure/observability"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

module "azure_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./azure/kubernetes"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  subnet_id           = var.enable_network ? module.azure_network[0].subnet_ids["kubernetes"] : null
  tags                = local.common_tags

  depends_on = [module.azure_network]
}

module "azure_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./azure/serverless"

  environment         = var.environment
  project_name        = var.project_name
  resource_group_name = azurerm_resource_group.main[0].name
  location            = var.azure_location
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.main]
}
{%- endif %}

{%- if values.provider == 'gcp' or values.provider == 'multi-cloud' %}

# ==============================================================================
# GCP Modules
# ==============================================================================

module "gcp_network" {
  count  = var.enable_network ? 1 : 0
  source = "./gcp/network"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  network_cidr = var.gcp_network_cidr
  labels       = local.gcp_labels
}

module "gcp_security" {
  count  = var.enable_security ? 1 : 0
  source = "./gcp/security"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels
}

module "gcp_storage" {
  count  = var.enable_storage ? 1 : 0
  source = "./gcp/storage"

  environment    = var.environment
  project_name   = var.project_name
  project_id     = var.gcp_project_id
  region         = var.gcp_region
  kms_key_id     = var.enable_security ? module.gcp_security[0].kms_key_id : null
  labels         = local.gcp_labels

  depends_on = [module.gcp_security]
}

module "gcp_compute" {
  count  = var.enable_compute ? 1 : 0
  source = "./gcp/compute"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  zone         = var.gcp_zone
  network_name = var.enable_network ? module.gcp_network[0].network_name : null
  subnet_name  = var.enable_network ? module.gcp_network[0].subnet_names[0] : null
  labels       = local.gcp_labels

  depends_on = [module.gcp_network]
}

module "gcp_database" {
  count  = var.enable_database ? 1 : 0
  source = "./gcp/database"

  environment         = var.environment
  project_name        = var.project_name
  project_id          = var.gcp_project_id
  region              = var.gcp_region
  network_id          = var.enable_network ? module.gcp_network[0].network_id : null
  private_ip_range    = var.enable_network ? module.gcp_network[0].private_ip_range : null
  labels              = local.gcp_labels

  depends_on = [module.gcp_network]
}

module "gcp_observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./gcp/observability"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels
}

module "gcp_kubernetes" {
  count  = var.enable_kubernetes ? 1 : 0
  source = "./gcp/kubernetes"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  network_name = var.enable_network ? module.gcp_network[0].network_name : null
  subnet_name  = var.enable_network ? module.gcp_network[0].subnet_names[0] : null
  labels       = local.gcp_labels

  depends_on = [module.gcp_network]
}

module "gcp_serverless" {
  count  = var.enable_serverless ? 1 : 0
  source = "./gcp/serverless"

  environment  = var.environment
  project_name = var.project_name
  project_id   = var.gcp_project_id
  region       = var.gcp_region
  labels       = local.gcp_labels
}
{%- endif %}

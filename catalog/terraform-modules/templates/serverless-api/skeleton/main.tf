terraform {
  required_version = ">= 1.0"

  required_providers {
    {%- if values.cloudProvider == "aws" %}
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    {%- endif %}
    {%- if values.cloudProvider == "azure" %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    {%- endif %}
    {%- if values.cloudProvider == "gcp" %}
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    {%- endif %}
  }

  {%- if values.cloudProvider == "aws" %}
  backend "s3" {
    bucket = "${{ values.projectName }}-terraform-state"
    key    = "${{ values.environment }}/serverless-api/terraform.tfstate"
    region = "${{ values.awsRegion }}"
  }
  {%- endif %}
  {%- if values.cloudProvider == "azure" %}
  backend "azurerm" {
    resource_group_name  = "${{ values.projectName }}-terraform-state-rg"
    storage_account_name = "${{ values.projectName | replace("-", "") }}tfstate"
    container_name       = "tfstate"
    key                  = "${{ values.environment }}/serverless-api/terraform.tfstate"
  }
  {%- endif %}
  {%- if values.cloudProvider == "gcp" %}
  backend "gcs" {
    bucket = "${{ values.projectName }}-terraform-state"
    prefix = "${{ values.environment }}/serverless-api"
  }
  {%- endif %}
}

{%- if values.cloudProvider == "aws" %}
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
provider "google" {
  project = var.gcp_project_id
  region  = var.region
}
{%- endif %}

locals {
  name_prefix = "${{ values.projectName }}-${{ values.environment }}"
  
  common_tags = {
    Project     = "${{ values.projectName }}"
    Environment = "${{ values.environment }}"
    ManagedBy   = "terraform"
    Platform    = "serverless"
  }

  runtime_mapping = {
    {%- if values.cloudProvider == "aws" %}
    nodejs20  = "nodejs20.x"
    python312 = "python3.12"
    go121     = "provided.al2023"
    dotnet8   = "dotnet8"
    java21    = "java21"
    {%- endif %}
    {%- if values.cloudProvider == "azure" %}
    nodejs20  = "node"
    python312 = "python"
    go121     = "custom"
    dotnet8   = "dotnet-isolated"
    java21    = "java"
    {%- endif %}
    {%- if values.cloudProvider == "gcp" %}
    nodejs20  = "nodejs20"
    python312 = "python312"
    go121     = "go121"
    dotnet8   = "dotnet8"
    java21    = "java21"
    {%- endif %}
  }
}

# =============================================================================
# AWS SERVERLESS API
# =============================================================================

{%- if values.cloudProvider == "aws" %}

# Lambda Function
module "lambda" {
  source = "../../aws/resources/compute/lambda"

  project_name = var.project_name
  environment  = var.environment

  function_name = "${local.name_prefix}-api"
  description   = "Serverless API for ${{ values.projectName }}"
  
  runtime     = local.runtime_mapping["${{ values.runtime }}"]
  handler     = var.handler
  memory_size = ${{ values.memorySize }}
  timeout     = ${{ values.timeout }}

  filename         = var.deployment_package
  source_code_hash = var.source_code_hash

  environment_variables = merge(var.environment_variables, {
    ENVIRONMENT = var.environment
  })

  {%- if values.enableTracing %}
  tracing_mode = "Active"
  {%- endif %}

  tags = local.common_tags
}

# API Gateway
{%- if values.apiType == "http" %}
module "api_gateway" {
  source = "../../aws/resources/network/api-gateway-v2"

  project_name = var.project_name
  environment  = var.environment

  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  
  cors_configuration = ${{ values.enableCors }} ? {
    allow_origins = var.cors_allowed_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Api-Key"]
    max_age       = 300
  } : null

  integrations = {
    "ANY /{proxy+}" = {
      integration_type       = "AWS_PROXY"
      integration_uri        = module.lambda.invoke_arn
      payload_format_version = "2.0"
    }
  }

  {%- if values.enableThrottling %}
  default_route_settings = {
    throttling_burst_limit = ${{ values.throttleBurstLimit }}
    throttling_rate_limit  = ${{ values.throttleRateLimit }}
  }
  {%- endif %}

  tags = local.common_tags
}
{%- elif values.apiType == "rest" %}
module "api_gateway" {
  source = "../../aws/resources/network/api-gateway"

  project_name = var.project_name
  environment  = var.environment

  name        = "${local.name_prefix}-api"
  description = "REST API for ${{ values.projectName }}"
  
  endpoint_type = "REGIONAL"

  {%- if values.enableThrottling %}
  throttling_burst_limit = ${{ values.throttleBurstLimit }}
  throttling_rate_limit  = ${{ values.throttleRateLimit }}
  {%- endif %}

  tags = local.common_tags
}
{%- else %}
# AppSync GraphQL API
module "appsync" {
  source = "../../aws/resources/compute/appsync"

  project_name = var.project_name
  environment  = var.environment

  name = "${local.name_prefix}-graphql"
  
  schema = var.graphql_schema

  authentication_type = "${{ values.authType == "jwt" and "AMAZON_COGNITO_USER_POOLS" or (values.authType == "api-key" and "API_KEY" or "AWS_IAM") }}"

  {%- if values.authType == "jwt" %}
  user_pool_config = {
    user_pool_id   = var.cognito_user_pool_id
    aws_region     = var.region
    default_action = "ALLOW"
  }
  {%- endif %}

  datasources = {
    lambda = {
      type             = "AWS_LAMBDA"
      function_arn     = module.lambda.arn
    }
  }

  {%- if values.enableTracing %}
  xray_enabled = true
  {%- endif %}

  tags = local.common_tags
}
{%- endif %}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*"
}

{%- if values.authType == "jwt" %}
# Cognito User Pool
module "cognito" {
  source = "../../aws/resources/security/cognito"

  project_name = var.project_name
  environment  = var.environment

  user_pool_name = "${local.name_prefix}-users"
  
  password_policy = {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  auto_verified_attributes = ["email"]
  
  app_clients = {
    web = {
      name                = "${local.name_prefix}-web-client"
      generate_secret     = false
      explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
    }
  }

  tags = local.common_tags
}
{%- endif %}

{%- if values.enableWaf %}
# WAF Web ACL
module "waf" {
  source = "../../aws/resources/security/waf"

  project_name = var.project_name
  environment  = var.environment
  
  name  = "${local.name_prefix}-waf"
  scope = "REGIONAL"

  managed_rule_groups = [
    {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
      priority    = 10
    },
    {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
      priority    = 20
    }
  ]

  {%- if values.enableThrottling %}
  rate_limit_rule = {
    name     = "rate-limit"
    priority = 1
    limit    = ${{ values.throttleRateLimit * 60 }}  # Per 5 minute period
  }
  {%- endif %}

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = module.api_gateway.stage_arn
  web_acl_arn  = module.waf.web_acl_arn
}
{%- endif %}

{%- endif %}

# =============================================================================
# AZURE SERVERLESS API
# =============================================================================

{%- if values.cloudProvider == "azure" %}

module "resource_group" {
  source = "../../azure/resources/core/resource-group"

  name     = "${local.name_prefix}-rg"
  location = var.region

  tags = local.common_tags
}

# Storage Account for Functions
module "storage_account" {
  source = "../../azure/resources/storage/storage-account"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name                     = "${replace(local.name_prefix, "-", "")}func"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# App Service Plan (Consumption)
resource "azurerm_service_plan" "functions" {
  name                = "${local.name_prefix}-plan"
  resource_group_name = module.resource_group.name
  location            = var.region
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan

  tags = local.common_tags
}

# Function App
module "function_app" {
  source = "../../azure/resources/compute/function-app"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name                       = "${local.name_prefix}-func"
  service_plan_id            = azurerm_service_plan.functions.id
  storage_account_name       = module.storage_account.name
  storage_account_access_key = module.storage_account.primary_access_key

  runtime_name    = local.runtime_mapping["${{ values.runtime }}"]
  runtime_version = {%- if values.runtime == "nodejs20" %}"20"{%- elif values.runtime == "python312" %}"3.12"{%- elif values.runtime == "dotnet8" %}"8.0"{%- elif values.runtime == "java21" %}"21"{%- else %}""{%- endif %}

  app_settings = merge(var.environment_variables, {
    FUNCTIONS_WORKER_RUNTIME = local.runtime_mapping["${{ values.runtime }}"]
    WEBSITE_RUN_FROM_PACKAGE = "1"
  })

  {%- if values.enableTracing %}
  application_insights_connection_string = module.app_insights.connection_string
  {%- endif %}

  {%- if values.enableCors %}
  cors = {
    allowed_origins = var.cors_allowed_origins
  }
  {%- endif %}

  tags = local.common_tags
}

# API Management
{%- if values.apiType == "rest" or values.apiType == "graphql" %}
module "api_management" {
  source = "../../azure/resources/network/api-management"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name          = "${local.name_prefix}-apim"
  publisher_name  = var.api_publisher_name
  publisher_email = var.api_publisher_email
  sku_name        = var.environment == "production" ? "Standard_1" : "Consumption_0"

  apis = {
    main = {
      name         = "${local.name_prefix}-api"
      display_name = "${{ values.projectName }} API"
      path         = "api"
      protocols    = ["https"]
      
      import = {
        content_format = "openapi+json"
        content_value  = var.openapi_spec
      }
    }
  }

  {%- if values.enableThrottling %}
  policies = {
    rate_limit = {
      calls       = ${{ values.throttleRateLimit }}
      renewal_period = 1
    }
  }
  {%- endif %}

  tags = local.common_tags
}
{%- endif %}

{%- if values.authType == "jwt" %}
# Azure AD B2C (or AAD)
data "azurerm_client_config" "current" {}
{%- endif %}

{%- if values.enableTracing %}
module "app_insights" {
  source = "../../azure/resources/monitoring/application-insights"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name             = "${local.name_prefix}-insights"
  application_type = "web"

  tags = local.common_tags
}
{%- endif %}

{%- endif %}

# =============================================================================
# GCP SERVERLESS API
# =============================================================================

{%- if values.cloudProvider == "gcp" %}

# Cloud Functions
module "cloud_function" {
  source = "../../gcp/resources/compute/cloud-functions"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name        = "${local.name_prefix}-api"
  description = "Serverless API for ${{ values.projectName }}"
  region      = var.region

  runtime             = local.runtime_mapping["${{ values.runtime }}"]
  entry_point         = var.entry_point
  available_memory_mb = ${{ values.memorySize }}
  timeout             = ${{ values.timeout }}

  source_archive_bucket = var.source_bucket
  source_archive_object = var.source_object

  environment_variables = merge(var.environment_variables, {
    ENVIRONMENT = var.environment
  })

  trigger_http = true

  {%- if values.authType == "none" %}
  allow_unauthenticated = true
  {%- else %}
  allow_unauthenticated = false
  {%- endif %}

  labels = local.common_tags
}

# API Gateway
{%- if values.apiType == "rest" or values.apiType == "http" %}
module "api_gateway" {
  source = "../../gcp/resources/network/api-gateway"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  api_id     = "${local.name_prefix}-api"
  gateway_id = "${local.name_prefix}-gateway"
  region     = var.region

  openapi_spec = var.openapi_spec

  backend_url = module.cloud_function.https_trigger_url

  labels = local.common_tags
}
{%- endif %}

{%- if values.authType == "jwt" %}
# Firebase Auth (for JWT)
resource "google_identity_platform_config" "default" {
  project = var.gcp_project_id
  
  sign_in {
    allow_duplicate_emails = false
    
    email {
      enabled           = true
      password_required = true
    }
  }
}
{%- endif %}

{%- if values.enableWaf %}
# Cloud Armor
module "cloud_armor" {
  source = "../../gcp/resources/security/cloud-armor"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name = "${local.name_prefix}-armor"

  default_rule_action = "allow"

  rules = [
    {
      action      = "deny(403)"
      priority    = 1000
      expression  = "evaluatePreconfiguredExpr('xss-stable')"
      description = "Block XSS attacks"
    },
    {
      action      = "deny(403)"
      priority    = 1001
      expression  = "evaluatePreconfiguredExpr('sqli-stable')"
      description = "Block SQL injection"
    }
    {%- if values.enableThrottling %},
    {
      action          = "throttle"
      priority        = 2000
      expression      = "true"
      description     = "Rate limiting"
      rate_limit_options = {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        rate_limit_threshold = {
          count        = ${{ values.throttleRateLimit }}
          interval_sec = 60
        }
      }
    }
    {%- endif %}
  ]
}
{%- endif %}

{%- if values.enableTracing %}
# Cloud Trace is automatically enabled for Cloud Functions
{%- endif %}

{%- endif %}

# =============================================================================
# DATABASE
# =============================================================================

{%- if values.enableDatabase %}
{%- if values.cloudProvider == "aws" %}
{%- if values.databaseType == "dynamodb" %}
module "dynamodb" {
  source = "../../aws/resources/database/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  table_name   = "${local.name_prefix}-table"
  billing_mode = var.environment == "production" ? "PROVISIONED" : "PAY_PER_REQUEST"
  
  hash_key  = var.dynamodb_hash_key
  range_key = var.dynamodb_range_key

  attributes = var.dynamodb_attributes

  {%- if var.environment == "production" %}
  read_capacity  = 5
  write_capacity = 5
  
  autoscaling = {
    read_min_capacity  = 5
    read_max_capacity  = 100
    write_min_capacity = 5
    write_max_capacity = 100
    target_value       = 70
  }
  {%- endif %}

  point_in_time_recovery = var.environment == "production"
  
  tags = local.common_tags
}
{%- elif values.databaseType == "aurora-serverless" %}
module "aurora_serverless" {
  source = "../../aws/resources/database/rds"

  project_name = var.project_name
  environment  = var.environment

  engine         = "aurora-postgresql"
  engine_mode    = "serverless"
  engine_version = "15.4"
  
  database_name   = replace(var.project_name, "-", "_")
  master_username = var.database_username
  master_password = var.database_password

  scaling_configuration = {
    min_capacity             = 2
    max_capacity             = var.environment == "production" ? 64 : 16
    auto_pause               = var.environment != "production"
    seconds_until_auto_pause = 300
  }

  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.database[0].id]

  tags = local.common_tags
}

resource "aws_security_group" "database" {
  count = 1

  name        = "${local.name_prefix}-db-sg"
  description = "Security group for Aurora Serverless"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.lambda.security_group_id]
  }

  tags = local.common_tags
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
{%- if values.databaseType == "cosmosdb" %}
module "cosmosdb" {
  source = "../../azure/resources/database/cosmos-db"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  account_name = "${local.name_prefix}-cosmos"
  
  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  consistency_policy = {
    consistency_level = var.environment == "production" ? "Session" : "Eventual"
  }

  geo_locations = [
    {
      location          = var.region
      failover_priority = 0
    }
  ]

  databases = {
    main = {
      name       = replace(var.project_name, "-", "_")
      throughput = var.environment == "production" ? 400 : null  # null = serverless
    }
  }

  tags = local.common_tags
}
{%- elif values.databaseType == "sql-serverless" %}
module "sql_serverless" {
  source = "../../azure/resources/database/sql-database"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  server_name           = "${local.name_prefix}-sql"
  administrator_login   = var.database_username
  administrator_password = var.database_password

  databases = {
    main = {
      name     = replace(var.project_name, "-", "_")
      sku_name = "GP_S_Gen5_1"  # Serverless
      
      auto_pause_delay_in_minutes = var.environment == "production" ? -1 : 60
      min_capacity               = 0.5
    }
  }

  tags = local.common_tags
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
{%- if values.databaseType == "firestore" %}
resource "google_firestore_database" "main" {
  project     = var.gcp_project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
}
{%- elif values.databaseType == "spanner" %}
module "spanner" {
  source = "../../gcp/resources/database/spanner"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  instance_name    = "${local.name_prefix}-spanner"
  config           = "regional-${var.region}"
  processing_units = var.environment == "production" ? 1000 : 100

  databases = {
    main = {
      name = replace(var.project_name, "-", "_")
    }
  }

  labels = local.common_tags
}
{%- endif %}
{%- endif %}
{%- endif %}

# =============================================================================
# MONITORING & LOGGING
# =============================================================================

{%- if values.enableAlarms %}
{%- if values.cloudProvider == "aws" %}
module "cloudwatch_alarms" {
  source = "../../aws/resources/monitoring/cloudwatch"

  project_name = var.project_name
  environment  = var.environment

  alarms = {
    lambda_errors = {
      alarm_name          = "${local.name_prefix}-lambda-errors"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 60
      statistic           = "Sum"
      threshold           = 5
      alarm_description   = "Lambda function errors exceeded threshold"
      dimensions = {
        FunctionName = module.lambda.function_name
      }
    }
    api_5xx_errors = {
      alarm_name          = "${local.name_prefix}-api-5xx-errors"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "5XXError"
      namespace           = "AWS/ApiGateway"
      period              = 60
      statistic           = "Sum"
      threshold           = 10
      alarm_description   = "API Gateway 5XX errors exceeded threshold"
      dimensions = {
        ApiName = module.api_gateway.name
      }
    }
  }

  sns_topic_arn = var.alarm_sns_topic_arn

  tags = local.common_tags
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "aws" %}
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${module.lambda.function_name}"
  retention_in_days = ${{ values.logRetentionDays }}

  tags = local.common_tags
}
{%- endif %}

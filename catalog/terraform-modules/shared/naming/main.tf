# =============================================================================
# SHARED NAMING MODULE
# =============================================================================
# Industry-standard naming conventions for Azure, AWS, and GCP resources
# Follows: Azure CAF, AWS Well-Architected, GCP Best Practices
# =============================================================================

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "cloud_provider" {
  description = "Cloud provider: azure, aws, or gcp"
  type        = string
  validation {
    condition     = contains(["azure", "aws", "gcp"], var.cloud_provider)
    error_message = "Provider must be one of: azure, aws, gcp"
  }
}

variable "project" {
  description = "Project or application name"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "Project must be lowercase alphanumeric with hyphens, 2-21 chars, start with letter"
  }
}

variable "environment" {
  description = "Environment: dev, staging, prod, sandbox"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox", "test", "uat"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, sandbox, test, uat"
  }
}

variable "component" {
  description = "Component or service name"
  type        = string
  default     = ""
}

variable "resource_type" {
  description = "Resource type abbreviation"
  type        = string
}

variable "region" {
  description = "Cloud region"
  type        = string
}

variable "instance" {
  description = "Instance number for multiple resources of same type"
  type        = number
  default     = 1
}

variable "layer" {
  description = "Infrastructure layer: platform, application, data, network, security, monitoring"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["platform", "application", "data", "network", "security", "monitoring"], var.layer)
    error_message = "Layer must be one of: platform, application, data, network, security, monitoring"
  }
}

variable "custom_suffix" {
  description = "Optional custom suffix"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Locals - Provider-Specific Naming Rules
# -----------------------------------------------------------------------------

locals {
  # Environment abbreviations
  env_abbrev = {
    dev     = "d"
    staging = "s"
    prod    = "p"
    sandbox = "sb"
    test    = "t"
    uat     = "u"
  }

  # Region abbreviations
  region_abbrev = {
    # Azure regions
    eastus             = "eus"
    eastus2            = "eus2"
    westus             = "wus"
    westus2            = "wus2"
    westus3            = "wus3"
    centralus          = "cus"
    northcentralus     = "ncus"
    southcentralus     = "scus"
    westcentralus      = "wcus"
    canadacentral      = "cac"
    canadaeast         = "cae"
    brazilsouth        = "brs"
    northeurope        = "neu"
    westeurope         = "weu"
    uksouth            = "uks"
    ukwest             = "ukw"
    francecentral      = "frc"
    francesouth        = "frs"
    germanywestcentral = "gwc"
    norwayeast         = "noe"
    switzerlandnorth   = "chn"
    australiaeast      = "aue"
    australiasoutheast = "ause"
    eastasia           = "ea"
    southeastasia      = "sea"
    japaneast          = "jpe"
    japanwest          = "jpw"
    koreacentral       = "krc"
    koreasouth         = "krs"
    centralindia       = "inc"
    southindia         = "ins"
    westindia          = "inw"
    uaenorth           = "uan"
    uaecentral         = "uac"
    southafricanorth   = "san"
    # AWS regions
    "us-east-1"      = "use1"
    "us-east-2"      = "use2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "ca-central-1"   = "cac1"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-central-1"   = "euc1"
    "eu-north-1"     = "eun1"
    "eu-south-1"     = "eus1"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ap-south-1"     = "aps1"
    "sa-east-1"      = "sae1"
    "me-south-1"     = "mes1"
    "af-south-1"     = "afs1"
    # GCP regions
    "us-central1"             = "usc1"
    "us-east1"                = "use1"
    "us-east4"                = "use4"
    "us-west1"                = "usw1"
    "us-west2"                = "usw2"
    "us-west3"                = "usw3"
    "us-west4"                = "usw4"
    "northamerica-northeast1" = "nane1"
    "northamerica-northeast2" = "nane2"
    "southamerica-east1"      = "sae1"
    "europe-west1"            = "euw1"
    "europe-west2"            = "euw2"
    "europe-west3"            = "euw3"
    "europe-west4"            = "euw4"
    "europe-west6"            = "euw6"
    "europe-north1"           = "eun1"
    "europe-central2"         = "euc2"
    "asia-east1"              = "ase1"
    "asia-east2"              = "ase2"
    "asia-northeast1"         = "asne1"
    "asia-northeast2"         = "asne2"
    "asia-northeast3"         = "asne3"
    "asia-south1"             = "ass1"
    "asia-south2"             = "ass2"
    "asia-southeast1"         = "asse1"
    "asia-southeast2"         = "asse2"
    "australia-southeast1"    = "ause1"
    "australia-southeast2"    = "ause2"
  }

  # Azure resource type prefixes (following CAF)
  azure_resource_prefixes = {
    # Compute
    virtual_machine           = "vm"
    virtual_machine_scale_set = "vmss"
    availability_set          = "avail"
    app_service               = "app"
    app_service_plan          = "asp"
    function_app              = "func"
    container_app             = "ca"
    container_instance        = "ci"
    batch_account             = "ba"
    # Containers
    kubernetes_cluster = "aks"
    container_registry = "acr"
    # Networking
    virtual_network            = "vnet"
    subnet                     = "snet"
    network_security_group     = "nsg"
    application_security_group = "asg"
    route_table                = "rt"
    nat_gateway                = "ng"
    load_balancer              = "lb"
    public_ip                  = "pip"
    application_gateway        = "agw"
    front_door                 = "fd"
    traffic_manager            = "tm"
    vpn_gateway                = "vpng"
    express_route              = "er"
    firewall                   = "afw"
    bastion                    = "bas"
    private_endpoint           = "pe"
    private_link_service       = "pls"
    dns_zone                   = "dns"
    virtual_wan                = "vwan"
    # Storage
    storage_account = "st"
    data_lake       = "dls"
    managed_disk    = "disk"
    netapp          = "anf"
    # Database
    sql_server           = "sql"
    sql_database         = "sqldb"
    sql_managed_instance = "sqlmi"
    cosmos_db            = "cosmos"
    postgresql           = "psql"
    mysql                = "mysql"
    mariadb              = "maria"
    redis_cache          = "redis"
    synapse              = "syn"
    # Security
    key_vault        = "kv"
    managed_identity = "id"
    ddos_protection  = "ddos"
    waf_policy       = "waf"
    # Identity
    azure_ad_group   = "aadg"
    app_registration = "appreg"
    # Monitoring
    log_analytics        = "log"
    application_insights = "appi"
    action_group         = "ag"
    alert_rule           = "ar"
    # Integration
    service_bus    = "sb"
    event_grid     = "evg"
    event_hub      = "evh"
    logic_app      = "logic"
    api_management = "apim"
    # AI/ML
    cognitive_services = "cog"
    machine_learning   = "mlw"
    openai             = "oai"
    bot_service        = "bot"
    # Governance
    policy           = "pol"
    blueprint        = "bp"
    management_group = "mg"
    resource_group   = "rg"
  }

  # AWS resource type prefixes
  aws_resource_prefixes = {
    # Compute
    ec2_instance       = "ec2"
    auto_scaling_group = "asg"
    launch_template    = "lt"
    lambda_function    = "lambda"
    elastic_beanstalk  = "eb"
    batch              = "batch"
    # Containers
    ecs_cluster    = "ecs"
    ecs_service    = "svc"
    ecs_task       = "task"
    eks_cluster    = "eks"
    ecr_repository = "ecr"
    fargate        = "fg"
    app_runner     = "ar"
    # Networking
    vpc                = "vpc"
    subnet             = "sn"
    security_group     = "sg"
    nacl               = "nacl"
    route_table        = "rt"
    internet_gateway   = "igw"
    nat_gateway        = "nat"
    transit_gateway    = "tgw"
    vpn_gateway        = "vgw"
    vpn_connection     = "vpn"
    direct_connect     = "dx"
    route53_zone       = "r53"
    cloudfront         = "cf"
    global_accelerator = "ga"
    alb                = "alb"
    nlb                = "nlb"
    target_group       = "tg"
    api_gateway        = "apigw"
    privatelink        = "pl"
    # Storage
    s3_bucket    = "s3"
    ebs_volume   = "ebs"
    efs          = "efs"
    fsx          = "fsx"
    backup_vault = "bkp"
    # Database
    rds_instance = "rds"
    rds_cluster  = "rdsc"
    aurora       = "aur"
    dynamodb     = "ddb"
    elasticache  = "ec"
    redshift     = "rs"
    neptune      = "nep"
    documentdb   = "docdb"
    timestream   = "ts"
    qldb         = "qldb"
    keyspaces    = "ks"
    # Security
    iam_role        = "role"
    iam_policy      = "pol"
    iam_user        = "usr"
    iam_group       = "grp"
    kms_key         = "kms"
    secrets_manager = "sm"
    acm_certificate = "acm"
    waf             = "waf"
    shield          = "shld"
    security_hub    = "sh"
    guardduty       = "gd"
    inspector       = "insp"
    macie           = "mac"
    detective       = "det"
    # Monitoring
    cloudwatch_alarm     = "cwa"
    cloudwatch_log_group = "cwl"
    cloudtrail           = "ct"
    xray                 = "xr"
    config               = "cfg"
    ssm_parameter        = "ssm"
    # Integration
    sns_topic      = "sns"
    sqs_queue      = "sqs"
    eventbridge    = "eb"
    step_functions = "sf"
    mq             = "mq"
    appsync        = "as"
    # AI/ML
    sagemaker   = "sm"
    rekognition = "rek"
    comprehend  = "comp"
    lex         = "lex"
    polly       = "pol"
    transcribe  = "tr"
    bedrock     = "br"
    # DevOps
    codecommit   = "cc"
    codebuild    = "cb"
    codedeploy   = "cd"
    codepipeline = "cp"
    codeartifact = "ca"
  }

  # GCP resource type prefixes
  gcp_resource_prefixes = {
    # Compute
    compute_instance  = "vm"
    instance_group    = "ig"
    instance_template = "it"
    cloud_function    = "gcf"
    cloud_run         = "run"
    app_engine        = "gae"
    batch             = "batch"
    # Containers
    gke_cluster       = "gke"
    artifact_registry = "ar"
    # Networking
    vpc                     = "vpc"
    subnet                  = "sn"
    firewall_rule           = "fw"
    route                   = "rt"
    cloud_nat               = "nat"
    cloud_router            = "rtr"
    load_balancer           = "lb"
    backend_service         = "bes"
    health_check            = "hc"
    cloud_cdn               = "cdn"
    cloud_armor             = "ca"
    cloud_dns               = "dns"
    cloud_interconnect      = "ic"
    cloud_vpn               = "vpn"
    private_service_connect = "psc"
    # Storage
    cloud_storage   = "gcs"
    persistent_disk = "pd"
    filestore       = "fs"
    # Database
    cloud_sql     = "sql"
    cloud_spanner = "spn"
    firestore     = "fst"
    bigtable      = "bt"
    memorystore   = "mem"
    bigquery      = "bq"
    alloydb       = "adb"
    # Security
    iam_role        = "role"
    service_account = "sa"
    secret          = "sec"
    kms_key         = "kms"
    kms_keyring     = "kr"
    security_policy = "sp"
    certificate     = "cert"
    # Monitoring
    monitoring_dashboard = "dash"
    log_sink             = "sink"
    alert_policy         = "alert"
    uptime_check         = "up"
    # Integration
    pubsub_topic        = "ps"
    pubsub_subscription = "pss"
    cloud_tasks         = "task"
    cloud_scheduler     = "sched"
    workflows           = "wf"
    eventarc            = "ea"
    # AI/ML
    vertex_ai       = "vai"
    automl          = "aml"
    vision_api      = "vis"
    speech_api      = "stt"
    language_api    = "nlp"
    translation_api = "tr"
    dialogflow      = "df"
  }

  # Get the appropriate prefix map based on provider
  resource_prefixes = {
    azure = local.azure_resource_prefixes
    aws   = local.aws_resource_prefixes
    gcp   = local.gcp_resource_prefixes
  }

  # Get prefix for the resource type
  prefix = lookup(local.resource_prefixes[var.cloud_provider], var.resource_type, var.resource_type)

  # Get abbreviated values
  env_short    = lookup(local.env_abbrev, var.environment, substr(var.environment, 0, 1))
  region_short = lookup(local.region_abbrev, var.region, substr(replace(var.region, "-", ""), 0, 4))

  # Maximum lengths per provider
  max_lengths = {
    azure = 80
    aws   = 63
    gcp   = 63
  }

  # Build name components
  component_part = var.component != "" ? "-${var.component}" : ""
  instance_part  = var.instance > 1 ? format("-%02d", var.instance) : ""
  suffix_part    = var.custom_suffix != "" ? "-${var.custom_suffix}" : ""

  # Standard name format: {prefix}-{project}-{component}-{env}-{region}-{instance}
  standard_name = join("-", compact([
    local.prefix,
    var.project,
    var.component,
    local.env_short,
    local.region_short,
    var.instance > 1 ? format("%02d", var.instance) : ""
  ]))

  # Truncate if necessary
  max_length = local.max_lengths[var.cloud_provider]
  final_name = substr(local.standard_name, 0, local.max_length)

  # Special handling for resources that don't allow hyphens (e.g., storage accounts)
  name_no_hyphens = replace(local.final_name, "-", "")
  name_no_special = lower(replace(local.final_name, "/[^a-zA-Z0-9]/", ""))

  # Unique suffix for globally unique names
  unique_suffix = substr(md5("${var.project}-${var.environment}-${var.region}"), 0, 6)
  unique_name   = "${substr(local.final_name, 0, local.max_length - 7)}-${local.unique_suffix}"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "name" {
  description = "Standard resource name with hyphens"
  value       = local.final_name
}

output "name_no_hyphens" {
  description = "Resource name without hyphens (for storage accounts, etc.)"
  value       = local.name_no_hyphens
}

output "name_no_special" {
  description = "Resource name with only alphanumeric characters"
  value       = local.name_no_special
}

output "unique_name" {
  description = "Globally unique resource name with hash suffix"
  value       = local.unique_name
}

output "prefix" {
  description = "Resource type prefix used"
  value       = local.prefix
}

output "environment_short" {
  description = "Abbreviated environment name"
  value       = local.env_short
}

output "region_short" {
  description = "Abbreviated region name"
  value       = local.region_short
}

output "naming_convention" {
  description = "Full naming convention metadata"
  value = {
    provider      = var.cloud_provider
    project       = var.project
    environment   = var.environment
    component     = var.component
    resource_type = var.resource_type
    region        = var.region
    layer         = var.layer
    instance      = var.instance
    name          = local.final_name
    unique_name   = local.unique_name
  }
}

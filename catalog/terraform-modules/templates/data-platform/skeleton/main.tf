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
    key    = "${{ values.environment }}/data-platform/terraform.tfstate"
    region = "${{ values.awsRegion }}"
  }
  {%- endif %}
  {%- if values.cloudProvider == "azure" %}
  backend "azurerm" {
    resource_group_name  = "${{ values.projectName }}-terraform-state-rg"
    storage_account_name = "${{ values.projectName | replace("-", "") }}tfstate"
    container_name       = "tfstate"
    key                  = "${{ values.environment }}/data-platform/terraform.tfstate"
  }
  {%- endif %}
  {%- if values.cloudProvider == "gcp" %}
  backend "gcs" {
    bucket = "${{ values.projectName }}-terraform-state"
    prefix = "${{ values.environment }}/data-platform"
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
    Platform    = "data"
  }
}

# =============================================================================
# DATA LAKE STORAGE
# =============================================================================

{%- if values.enableDataLake %}
{%- if values.cloudProvider == "aws" %}
module "data_lake" {
  source = "../../aws/resources/storage/s3"

  project_name = var.project_name
  environment  = var.environment

  buckets = {
    raw = {
      name = "${local.name_prefix}-data-lake-raw"
      versioning = true
      lifecycle_rules = [
        {
          id      = "transition-to-ia"
          enabled = true
          transition = {
            days          = 30
            storage_class = "${{ values.dataLakeStorageClass == "infrequent" and "STANDARD_IA" or (values.dataLakeStorageClass == "archive" and "GLACIER" or "STANDARD") }}"
          }
        }
      ]
    }
    processed = {
      name = "${local.name_prefix}-data-lake-processed"
      versioning = true
    }
    curated = {
      name = "${local.name_prefix}-data-lake-curated"
      versioning = true
    }
  }

  enable_encryption = ${{ values.enableEncryption }}
  
  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "resource_group" {
  source = "../../azure/resources/core/resource-group"

  name     = "${local.name_prefix}-data-rg"
  location = var.region

  tags = local.common_tags
}

module "data_lake" {
  source = "../../azure/resources/storage/storage-account"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name                     = "${replace(local.name_prefix, "-", "")}datalake"
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Enable hierarchical namespace for Data Lake Gen2

  containers = {
    raw       = { access_type = "private" }
    processed = { access_type = "private" }
    curated   = { access_type = "private" }
  }

  enable_encryption = ${{ values.enableEncryption }}

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "data_lake" {
  source = "../../gcp/resources/storage/gcs"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  buckets = {
    raw = {
      name          = "${local.name_prefix}-data-lake-raw"
      location      = var.region
      storage_class = "${{ values.dataLakeStorageClass == "infrequent" and "NEARLINE" or (values.dataLakeStorageClass == "archive" and "COLDLINE" or "STANDARD") }}"
      versioning    = true
    }
    processed = {
      name          = "${local.name_prefix}-data-lake-processed"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = true
    }
    curated = {
      name          = "${local.name_prefix}-data-lake-curated"
      location      = var.region
      storage_class = "STANDARD"
      versioning    = true
    }
  }

  enable_encryption = ${{ values.enableEncryption }}

  labels = local.common_tags
}
{%- endif %}
{%- endif %}

# =============================================================================
# DATA CATALOG
# =============================================================================

{%- if values.enableDataCatalog %}
{%- if values.cloudProvider == "aws" %}
module "glue_catalog" {
  source = "../../aws/resources/analytics/glue"

  project_name = var.project_name
  environment  = var.environment

  catalog_database_name = "${replace(local.name_prefix, "-", "_")}_catalog"
  
  create_crawler = true
  crawler_s3_targets = [
    module.data_lake.bucket_arns["raw"],
    module.data_lake.bucket_arns["processed"],
    module.data_lake.bucket_arns["curated"]
  ]

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "purview" {
  source = "../../azure/resources/analytics/purview"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name = "${local.name_prefix}-purview"

  managed_resource_group_name = "${local.name_prefix}-purview-managed-rg"

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "data_catalog" {
  source = "../../gcp/resources/analytics/data-catalog"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  entry_group_id = "${replace(local.name_prefix, "-", "_")}_catalog"
  location       = var.region

  labels = local.common_tags
}
{%- endif %}
{%- endif %}

# =============================================================================
# DATA WAREHOUSE
# =============================================================================

{%- if values.enableDataWarehouse %}
{%- if values.cloudProvider == "aws" %}
module "redshift" {
  source = "../../aws/resources/analytics/redshift"

  project_name = var.project_name
  environment  = var.environment

  cluster_identifier = "${local.name_prefix}-redshift"
  database_name      = replace(var.project_name, "-", "_")
  master_username    = var.warehouse_admin_username
  master_password    = var.warehouse_admin_password

  node_type       = {%- if values.warehouseSize == "small" %}"dc2.large"{%- elif values.warehouseSize == "medium" %}"dc2.8xlarge"{%- else %}"ra3.4xlarge"{%- endif %}
  number_of_nodes = {%- if values.warehouseSize == "small" %}2{%- elif values.warehouseSize == "medium" %}4{%- else %}8{%- endif %}

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  encrypted = ${{ values.enableEncryption }}

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "synapse" {
  source = "../../azure/resources/analytics/synapse"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  workspace_name = "${local.name_prefix}-synapse"
  
  storage_data_lake_gen2_filesystem_id = module.data_lake.primary_dfs_endpoint

  sql_administrator_login          = var.warehouse_admin_username
  sql_administrator_login_password = var.warehouse_admin_password

  sql_pools = {
    dedicated = {
      name     = "${replace(local.name_prefix, "-", "_")}_pool"
      sku_name = {%- if values.warehouseSize == "small" %}"DW100c"{%- elif values.warehouseSize == "medium" %}"DW500c"{%- else %}"DW1000c"{%- endif %}
    }
  }

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "bigquery" {
  source = "../../gcp/resources/analytics/bigquery"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  dataset_id = "${replace(local.name_prefix, "-", "_")}_warehouse"
  location   = var.region

  default_table_expiration_ms = null  # No expiration
  
  delete_contents_on_destroy = var.environment != "production"

  access = [
    {
      role          = "OWNER"
      special_group = "projectOwners"
    },
    {
      role          = "READER"
      special_group = "projectReaders"
    }
  ]

  labels = local.common_tags
}
{%- endif %}
{%- endif %}

# =============================================================================
# ETL/ELT PIPELINES
# =============================================================================

{%- if values.enableEtlPipelines %}
{%- if values.cloudProvider == "aws" %}
{%- if values.etlEngine == "spark" %}
module "emr" {
  source = "../../aws/resources/analytics/emr"

  project_name = var.project_name
  environment  = var.environment

  cluster_name = "${local.name_prefix}-emr"
  
  release_label = "emr-7.0.0"
  applications  = ["Spark", "Hive", "Presto"]

  master_instance_type = {%- if values.warehouseSize == "small" %}"m5.xlarge"{%- elif values.warehouseSize == "medium" %}"m5.2xlarge"{%- else %}"m5.4xlarge"{%- endif %}
  core_instance_type   = {%- if values.warehouseSize == "small" %}"m5.xlarge"{%- elif values.warehouseSize == "medium" %}"m5.2xlarge"{%- else %}"m5.4xlarge"{%- endif %}
  core_instance_count  = {%- if values.warehouseSize == "small" %}2{%- elif values.warehouseSize == "medium" %}4{%- else %}8{%- endif %}

  vpc_id     = var.vpc_id
  subnet_id  = var.private_subnet_ids[0]

  log_uri = "s3://${module.data_lake.bucket_names["raw"]}/emr-logs/"

  tags = local.common_tags
}
{%- else %}
module "glue_jobs" {
  source = "../../aws/resources/analytics/glue"

  project_name = var.project_name
  environment  = var.environment

  jobs = {
    raw_to_processed = {
      name         = "${local.name_prefix}-raw-to-processed"
      role_arn     = aws_iam_role.glue_job.arn
      glue_version = "4.0"
      worker_type  = {%- if values.warehouseSize == "small" %}"G.1X"{%- elif values.warehouseSize == "medium" %}"G.2X"{%- else %}"G.4X"{%- endif %}
      number_of_workers = {%- if values.warehouseSize == "small" %}2{%- elif values.warehouseSize == "medium" %}5{%- else %}10{%- endif %}
      
      command = {
        script_location = "s3://${module.data_lake.bucket_names["raw"]}/scripts/raw_to_processed.py"
        python_version  = "3"
      }
    }
    processed_to_curated = {
      name         = "${local.name_prefix}-processed-to-curated"
      role_arn     = aws_iam_role.glue_job.arn
      glue_version = "4.0"
      worker_type  = "G.1X"
      number_of_workers = 2
      
      command = {
        script_location = "s3://${module.data_lake.bucket_names["raw"]}/scripts/processed_to_curated.py"
        python_version  = "3"
      }
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role" "glue_job" {
  name = "${local.name_prefix}-glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_job.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
{%- endif %}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "data_factory" {
  source = "../../azure/resources/analytics/data-factory"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  name = "${local.name_prefix}-adf"

  identity_type = "SystemAssigned"

  {%- if values.etlEngine == "spark" %}
  integration_runtimes = {
    spark = {
      type                    = "Managed"
      compute_type            = "General"
      core_count              = {%- if values.warehouseSize == "small" %}8{%- elif values.warehouseSize == "medium" %}16{%- else %}32{%- endif %}
      time_to_live_min        = 10
    }
  }
  {%- endif %}

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
{%- if values.etlEngine == "spark" %}
module "dataproc" {
  source = "../../gcp/resources/analytics/dataproc"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  cluster_name = "${local.name_prefix}-dataproc"
  region       = var.region

  master_config = {
    num_instances = 1
    machine_type  = {%- if values.warehouseSize == "small" %}"n2-standard-4"{%- elif values.warehouseSize == "medium" %}"n2-standard-8"{%- else %}"n2-standard-16"{%- endif %}
  }

  worker_config = {
    num_instances = {%- if values.warehouseSize == "small" %}2{%- elif values.warehouseSize == "medium" %}4{%- else %}8{%- endif %}
    machine_type  = {%- if values.warehouseSize == "small" %}"n2-standard-4"{%- elif values.warehouseSize == "medium" %}"n2-standard-8"{%- else %}"n2-standard-16"{%- endif %}
  }

  staging_bucket = module.data_lake.bucket_names["raw"]

  labels = local.common_tags
}
{%- else %}
module "dataflow" {
  source = "../../gcp/resources/analytics/dataflow"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  # Dataflow jobs will be created as needed
  # This module sets up the necessary IAM and networking

  service_account_email = google_service_account.dataflow.email
  network               = var.network_name
  subnetwork            = var.subnetwork_name
  region                = var.region

  labels = local.common_tags
}

resource "google_service_account" "dataflow" {
  account_id   = "${local.name_prefix}-dataflow"
  display_name = "Dataflow Service Account"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "dataflow_worker" {
  project = var.gcp_project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}
{%- endif %}
{%- endif %}
{%- endif %}

# =============================================================================
# WORKFLOW ORCHESTRATION
# =============================================================================

{%- if values.enableOrchestration %}
{%- if values.cloudProvider == "aws" %}
module "step_functions" {
  source = "../../aws/resources/compute/step-functions"

  project_name = var.project_name
  environment  = var.environment

  state_machine_name = "${local.name_prefix}-data-pipeline"
  
  definition = jsonencode({
    Comment = "Data Pipeline Orchestration"
    StartAt = "RawToProcessed"
    States = {
      RawToProcessed = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "${local.name_prefix}-raw-to-processed"
        }
        Next = "ProcessedToCurated"
      }
      ProcessedToCurated = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "${local.name_prefix}-processed-to-curated"
        }
        End = true
      }
    }
  })

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "composer" {
  source = "../../gcp/resources/analytics/composer"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  name     = "${local.name_prefix}-composer"
  region   = var.region
  
  environment_size = {%- if values.warehouseSize == "small" %}"ENVIRONMENT_SIZE_SMALL"{%- elif values.warehouseSize == "medium" %}"ENVIRONMENT_SIZE_MEDIUM"{%- else %}"ENVIRONMENT_SIZE_LARGE"{%- endif %}

  network    = var.network_name
  subnetwork = var.subnetwork_name

  labels = local.common_tags
}
{%- endif %}
{%- endif %}

# =============================================================================
# STREAMING
# =============================================================================

{%- if values.enableStreaming %}
{%- if values.cloudProvider == "aws" %}
module "kinesis" {
  source = "../../aws/resources/messaging/kinesis"

  project_name = var.project_name
  environment  = var.environment

  stream_name       = "${local.name_prefix}-data-stream"
  shard_count       = var.environment == "production" ? 4 : 2
  retention_period  = ${{ values.streamingRetention }}

  enable_enhanced_monitoring = var.environment == "production"

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "azure" %}
module "event_hubs" {
  source = "../../azure/resources/messaging/event-hubs"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = var.region

  namespace_name = "${local.name_prefix}-eventhubs"
  sku            = var.environment == "production" ? "Standard" : "Basic"
  capacity       = var.environment == "production" ? 2 : 1

  event_hubs = {
    data_stream = {
      name              = "data-stream"
      partition_count   = var.environment == "production" ? 4 : 2
      message_retention = {%- if values.streamingRetention <= 24 %}1{%- elif values.streamingRetention <= 168 %}7{%- else %}7{%- endif %}
    }
  }

  tags = local.common_tags
}
{%- endif %}

{%- if values.cloudProvider == "gcp" %}
module "pubsub" {
  source = "../../gcp/resources/messaging/pubsub"

  project_name = var.project_name
  environment  = var.environment
  project_id   = var.gcp_project_id

  topics = {
    data_stream = {
      name = "${local.name_prefix}-data-stream"
      message_retention_duration = "${${{ values.streamingRetention }} * 3600}s"
    }
  }

  subscriptions = {
    data_stream_sub = {
      name  = "${local.name_prefix}-data-stream-sub"
      topic = "${local.name_prefix}-data-stream"
      ack_deadline_seconds = 20
      retain_acked_messages = false
    }
  }

  labels = local.common_tags
}
{%- endif %}
{%- endif %}

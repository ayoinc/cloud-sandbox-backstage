# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the data platform, used as a prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC that holds the warehouse and the SageMaker domain"
  type        = string
  default     = "10.60.0.0/16"
}

# --- Data lake and catalog ----------------------------------------------------

variable "enable_data_lake" {
  description = "Create the S3 buckets of the data lake (raw, processed and curated zones)"
  type        = bool
}

variable "data_lake_storage_class" {
  description = "Lifecycle of the data lake objects: standard, infrequent or archive"
  type        = string

  validation {
    condition     = contains(["standard", "infrequent", "archive"], var.data_lake_storage_class)
    error_message = "data_lake_storage_class must be standard, infrequent or archive."
  }
}

variable "enable_data_catalog" {
  description = "Create Glue Data Catalog databases for the zones and crawlers over the data lake"
  type        = bool
}

variable "crawler_schedule" {
  description = "When the crawlers run while enable_orchestration is false. The pipeline starts them itself."
  type        = string
  default     = "cron(0 2 * * ? *)"
}

# --- Data warehouse -----------------------------------------------------------

variable "enable_data_warehouse" {
  description = "Create an Amazon Redshift cluster"
  type        = bool
}

variable "warehouse_size" {
  description = "Size of the Redshift cluster: small (2 nodes), medium (4 nodes) or large (8 nodes)"
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.warehouse_size)
    error_message = "warehouse_size must be small, medium or large."
  }
}

variable "warehouse_node_type" {
  description = "Node type of the Redshift cluster"
  type        = string
  default     = "ra3.xlplus"
}

variable "warehouse_database_name" {
  description = "Name of the first database of the Redshift cluster"
  type        = string
  default     = "analytics"
}

variable "warehouse_admin_username" {
  description = "Admin user of the Redshift cluster. Redshift generates the password and keeps it in Secrets Manager."
  type        = string
  default     = "dwadmin"
}

# --- ETL and orchestration ----------------------------------------------------

variable "enable_etl_pipelines" {
  description = "Create the ETL jobs that move data from zone to zone"
  type        = bool
}

variable "etl_engine" {
  description = "What runs the ETL jobs: native (AWS Glue jobs) or spark (EMR Serverless application)"
  type        = string

  validation {
    condition     = contains(["spark", "native"], var.etl_engine)
    error_message = "etl_engine must be spark or native."
  }
}

variable "raw_data_format" {
  description = "Format of the files in the raw zone, as a Spark data source name (json, csv, parquet, ...)"
  type        = string
  default     = "json"
}

variable "glue_version" {
  description = "AWS Glue version of the jobs (etl_engine = native). Data lineage needs 5.0 or later."
  type        = string
  default     = "5.0"
}

variable "glue_worker_type" {
  description = "Worker type of the Glue jobs"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Number of workers of each Glue job"
  type        = number
  default     = 2
}

variable "emr_release_label" {
  description = "Amazon EMR release of the EMR Serverless application (etl_engine = spark). Data lineage needs emr-7.5.0 or later."
  type        = string
  default     = "emr-7.10.0"
}

variable "emr_maximum_capacity" {
  description = "Upper limit of the resources all running jobs of the EMR Serverless application may use together"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "32 vCPU"
    memory = "128 GB"
  }
}

variable "enable_orchestration" {
  description = "Create a Step Functions state machine that runs the ETL jobs, the crawlers and the warehouse publication in order"
  type        = bool
}

# --- Streaming ----------------------------------------------------------------

variable "enable_streaming" {
  description = "Create a Kinesis data stream and, with the data lake, a Firehose stream that delivers its records to the raw zone"
  type        = bool
}

variable "streaming_retention_hours" {
  description = "Hours the Kinesis data stream keeps records. Kinesis accepts 24 to 8760; values outside are moved to the nearest limit."
  type        = number
}

# --- Analytics ----------------------------------------------------------------

variable "enable_bi_tools" {
  description = "Create an Athena workgroup and the IAM role a BI tool such as QuickSight uses to query the lake"
  type        = bool
}

variable "bi_trusted_principal_arns" {
  description = "IAM principals, besides the QuickSight service, that may assume the BI role"
  type        = list(string)
  default     = []
}

variable "athena_bytes_scanned_cutoff" {
  description = "Data one Athena query may scan before it is cancelled, in bytes"
  type        = number
  default     = 107374182400
}

variable "enable_ml_platform" {
  description = "Create a SageMaker domain whose users can read the processed and curated zones"
  type        = bool
}

variable "ml_user_profiles" {
  description = "User profiles created in the SageMaker domain"
  type        = list(string)
  default     = ["data-scientist"]
}

# --- Security and governance --------------------------------------------------

variable "enable_encryption" {
  description = "Encrypt every store with a customer managed KMS key. When false the stores use keys managed by AWS."
  type        = bool
}

variable "encrypt_catalog_metadata" {
  description = "With enable_encryption and enable_data_catalog, encrypt the Glue Data Catalog of this account and region with the key. Every reader of the catalog then needs access to the key."
  type        = bool
  default     = true
}

variable "enable_data_lineage" {
  description = "Create an Amazon DataZone domain and have the ETL jobs send OpenLineage events to it"
  type        = bool
}

variable "enable_access_control" {
  description = "Govern access to the lake tables with Lake Formation permissions instead of IAM policies on the buckets"
  type        = bool
}

variable "lake_formation_admin_arns" {
  description = "IAM users and roles that administer Lake Formation, besides the role that applies this stack. The list replaces the administrators already set in the account."
  type        = list(string)
  default     = []
}

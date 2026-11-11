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
  description = "Google Cloud region of every resource"
  type        = string
}

variable "gcp_project_id" {
  description = "ID of the Google Cloud project the resources are created in"
  type        = string
}

# --- Data lake ----------------------------------------------------------------

variable "enable_data_lake" {
  description = "Create the Cloud Storage buckets of the raw, processed and curated zones"
  type        = bool
}

variable "data_lake_storage_class" {
  description = "Class that objects of the raw and processed zones move to as they age: standard (stay in STANDARD), infrequent (NEARLINE) or archive (ARCHIVE)"
  type        = string

  validation {
    condition     = contains(["standard", "infrequent", "archive"], var.data_lake_storage_class)
    error_message = "data_lake_storage_class must be standard, infrequent or archive."
  }
}

variable "data_lake_transition_days" {
  description = "Age in days at which objects of the raw and processed zones move to the class of data_lake_storage_class"
  type        = number
  default     = 30
}

variable "enable_data_catalog" {
  description = "Organise the lake and the warehouse in a Dataplex lake with metadata discovery"
  type        = bool
}

variable "catalog_discovery_schedule" {
  description = "Cron schedule of Dataplex metadata discovery. Runs must be at least 60 minutes apart."
  type        = string
  default     = "0 */6 * * *"
}

# --- Data warehouse -----------------------------------------------------------

variable "enable_data_warehouse" {
  description = "Create the BigQuery datasets and the slot reservation"
  type        = bool
}

variable "warehouse_size" {
  description = "Query capacity of the warehouse: small (100 slots), medium (200) or large (400). Also sizes BI Engine."
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.warehouse_size)
    error_message = "warehouse_size must be small, medium or large."
  }
}

variable "warehouse_baseline_slots" {
  description = "Slots that are always allocated to the reservation. Autoscaling adds slots above this up to the size's maximum."
  type        = number
  default     = 0
}

variable "assign_project_to_reservation" {
  description = "Run the query jobs of this Google Cloud project on the reservation. Set to false when another stack already assigns the project."
  type        = bool
  default     = true
}

# --- ETL and orchestration ----------------------------------------------------

variable "enable_etl_pipelines" {
  description = "Create what batch and streaming pipelines need: worker identity, staging and temporary buckets and the engine's resources"
  type        = bool
}

variable "etl_engine" {
  description = "Pipeline engine: native (Dataflow) or spark (Dataproc)"
  type        = string

  validation {
    condition     = contains(["native", "spark"], var.etl_engine)
    error_message = "etl_engine must be native or spark."
  }
}

variable "dataflow_flex_template_gcs_path" {
  description = "Cloud Storage path of a Dataflow Flex Template spec (gs://...). When set and etl_engine is native, a job is launched from it."
  type        = string
  default     = null
}

variable "dataflow_flex_template_parameters" {
  description = "Parameters of the Flex Template in dataflow_flex_template_gcs_path"
  type        = map(string)
  default     = {}
}

variable "dataflow_max_workers" {
  description = "Upper limit of workers of the Dataflow job"
  type        = number
  default     = 5
}

variable "dataproc_image_version" {
  description = "Dataproc image of the cluster a workflow run creates (etl_engine spark)"
  type        = string
  default     = "2.2-debian12"
}

variable "spark_machine_type" {
  description = "Machine type of the Dataproc master and worker nodes"
  type        = string
  default     = "n2-standard-4"
}

variable "spark_max_workers" {
  description = "Upper limit of Dataproc worker nodes the autoscaling policy allows"
  type        = number
  default     = 10
}

variable "enable_orchestration" {
  description = "Create a Cloud Composer (Airflow) environment"
  type        = bool
}

variable "composer_image_version" {
  description = "Cloud Composer image. The default follows the latest Airflow 2 release of Composer 3."
  type        = string
  default     = "composer-3-airflow-2"
}

# --- Streaming ----------------------------------------------------------------

variable "enable_streaming" {
  description = "Create the Pub/Sub topic for events and its subscriptions"
  type        = bool
}

variable "streaming_retention_hours" {
  description = "Hours Pub/Sub keeps messages. Pub/Sub accepts 10 minutes to 31 days; values outside that range are capped."
  type        = number
}

# --- Analytics ----------------------------------------------------------------

variable "enable_bi_tools" {
  description = "Create a BI Engine reservation and a read-only identity for Looker or Looker Studio. Needs the warehouse."
  type        = bool
}

variable "enable_ml_platform" {
  description = "Create a Vertex AI Workbench instance with its identity and artifact bucket"
  type        = bool
}

variable "ml_machine_type" {
  description = "Machine type of the Workbench instance"
  type        = string
  default     = "e2-standard-4"
}

variable "ml_zone" {
  description = "Zone of the Workbench instance. Defaults to zone b of the region."
  type        = string
  default     = null
}

variable "ml_idle_shutdown_seconds" {
  description = "Idle time after which the Workbench instance shuts itself down"
  type        = number
  default     = 3600
}

# --- Security and governance --------------------------------------------------

variable "enable_encryption" {
  description = "Encrypt buckets, BigQuery datasets and Pub/Sub topics with customer-managed Cloud KMS keys instead of Google-managed keys"
  type        = bool
}

variable "enable_data_lineage" {
  description = "Record data lineage: enable the Data Lineage API and let the pipelines report to it"
  type        = bool
}

variable "enable_access_control" {
  description = "Grant access per bucket and per dataset and protect sensitive columns with policy tags, instead of project-wide roles"
  type        = bool
}

variable "data_engineers" {
  description = "IAM members (for example group:data-eng@example.com) that build pipelines: read and write access to the lake and the warehouse"
  type        = list(string)
  default     = []
}

variable "data_analysts" {
  description = "IAM members that analyse data: read access to the curated zone and the marts dataset"
  type        = list(string)
  default     = []
}

variable "data_scientists" {
  description = "IAM members that use the Workbench instance and Vertex AI"
  type        = list(string)
  default     = []
}

# --- Network ------------------------------------------------------------------

variable "subnet_cidr" {
  description = "IP range of the subnet that pipeline workers, Airflow and the Workbench instance run in"
  type        = string
  default     = "10.10.0.0/20"
}

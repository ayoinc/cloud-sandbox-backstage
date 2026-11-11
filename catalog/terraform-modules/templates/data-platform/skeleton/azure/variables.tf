# Values chosen when this repository was created are in terraform.tfvars.

variable "project_name" {
  description = "Name of the data platform, used as a prefix for resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name)) && length(var.project_name) <= 16
    error_message = "project_name must start with a letter, contain only lowercase letters, digits and hyphens, and be at most 16 characters long."
  }
}

variable "environment" {
  description = "Environment this stack belongs to"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging or production."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "subscription_id" {
  description = "Subscription the resources are created in. null uses the subscription of the credentials Terraform runs with."
  type        = string
  default     = null
}

variable "allowed_ip_ranges" {
  description = "Public IPv4 ranges (CIDR, /30 or larger) allowed through the firewalls of the storage accounts, the Key Vault and Synapse. While empty, the storage accounts and the Key Vault accept authenticated requests from any network. Include the address of the machine that runs Terraform."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for range in var.allowed_ip_ranges : can(cidrhost(range, 0)) && try(tonumber(split("/", range)[1]) <= 30, false)])
    error_message = "allowed_ip_ranges must be IPv4 CIDR ranges with a prefix length of 30 or less, for example 203.0.113.0/24."
  }
}

# --- Data lake ----------------------------------------------------------------

variable "enable_data_lake" {
  description = "Create the raw, processed and curated zones in an Azure Data Lake Storage Gen2 account"
  type        = bool
}

variable "data_lake_storage_class" {
  description = "Tiering of the data lake: standard keeps data hot and cools it with age, infrequent stores it cool and archives it with age, archive moves it to the archive tier after a month"
  type        = string

  validation {
    condition     = contains(["standard", "infrequent", "archive"], var.data_lake_storage_class)
    error_message = "data_lake_storage_class must be standard, infrequent or archive."
  }
}

variable "enable_data_catalog" {
  description = "Create a Microsoft Purview account as the data catalog"
  type        = bool
}

# --- Data warehouse -----------------------------------------------------------

variable "enable_data_warehouse" {
  description = "Create an Azure Synapse workspace with a dedicated SQL pool"
  type        = bool
}

variable "warehouse_size" {
  description = "Size of the dedicated SQL pool: small (DW100c), medium (DW500c) or large (DW1000c)"
  type        = string

  validation {
    condition     = contains(["small", "medium", "large"], var.warehouse_size)
    error_message = "warehouse_size must be small, medium or large."
  }
}

variable "warehouse_sql_admin_login" {
  description = "Login name of the SQL administrator of the Synapse workspace. Its password is generated and stored in the Key Vault."
  type        = string
  default     = "sqladmin"
}

variable "warehouse_entra_admin" {
  description = "Microsoft Entra user, group or service principal that administers the Synapse workspace. Defaults to the identity Terraform runs with."
  type = object({
    login     = string
    object_id = string
  })
  default = null
}

# --- Processing ---------------------------------------------------------------

variable "enable_etl_pipelines" {
  description = "Create the ETL engine chosen in etl_engine"
  type        = bool
}

variable "etl_engine" {
  description = "ETL engine: native (Azure Data Factory) or spark (Azure Databricks)"
  type        = string

  validation {
    condition     = contains(["spark", "native"], var.etl_engine)
    error_message = "etl_engine must be spark or native."
  }
}

variable "enable_orchestration" {
  description = "Create a Data Factory that runs the ETL on a schedule"
  type        = bool
}

variable "orchestration_hour_utc" {
  description = "Hour of the day (UTC) at which the schedule trigger runs the ETL"
  type        = number
  default     = 2

  validation {
    condition     = var.orchestration_hour_utc >= 0 && var.orchestration_hour_utc <= 23 && floor(var.orchestration_hour_utc) == var.orchestration_hour_utc
    error_message = "orchestration_hour_utc must be a whole number from 0 to 23."
  }
}

variable "orchestration_trigger_activated" {
  description = "Start the schedule trigger. It is created stopped, because a run fails until the raw zone holds data (native) or the notebook exists (spark)."
  type        = bool
  default     = false
}

variable "databricks_notebook_path" {
  description = "Workspace path of the notebook the Data Factory pipeline runs when etl_engine is spark"
  type        = string
  default     = "/Shared/etl/main"
}

variable "databricks_node_type" {
  description = "Virtual machine size of the job clusters Data Factory starts in Databricks"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "databricks_spark_version" {
  description = "Databricks runtime version of the job clusters Data Factory starts"
  type        = string
  default     = "15.4.x-scala2.12"
}

variable "databricks_max_workers" {
  description = "Upper limit of workers of the autoscaling job clusters Data Factory starts"
  type        = number
  default     = 4
}

# --- Streaming ----------------------------------------------------------------

variable "enable_streaming" {
  description = "Create an Event Hubs namespace with an event hub"
  type        = bool
}

variable "streaming_retention_hours" {
  description = "How long events are kept, in hours. Event Hubs Standard keeps events for whole days: the value is rounded up to days and limited to 1 to 7."
  type        = number
}

variable "streaming_partition_count" {
  description = "Partitions of the event hub. It cannot be changed after the event hub is created."
  type        = number
  default     = 4

  validation {
    condition     = var.streaming_partition_count >= 1 && var.streaming_partition_count <= 32
    error_message = "streaming_partition_count must be between 1 and 32."
  }
}

# --- Analytics ----------------------------------------------------------------

variable "enable_bi_tools" {
  description = "Let the Power BI service reach the dedicated SQL endpoint, and create a Power BI Embedded capacity when power_bi_capacity_administrators is set"
  type        = bool
}

variable "power_bi_capacity_administrators" {
  description = "User principal names or object IDs of the administrators of a Power BI Embedded capacity. The capacity is created when enable_bi_tools is true and this list is not empty."
  type        = list(string)
  default     = []
}

variable "power_bi_capacity_sku" {
  description = "Size of the Power BI Embedded capacity"
  type        = string
  default     = "A1"

  validation {
    condition     = contains(["A1", "A2", "A3", "A4", "A5", "A6"], var.power_bi_capacity_sku)
    error_message = "power_bi_capacity_sku must be one of A1 to A6."
  }
}

variable "enable_ml_platform" {
  description = "Create an Azure Machine Learning workspace with its storage account, Application Insights and Key Vault"
  type        = bool
}

# --- Security and governance --------------------------------------------------

variable "enable_encryption" {
  description = "Encrypt the storage accounts, the Synapse workspace and the Databricks root storage with a customer-managed key from the Key Vault. Microsoft-managed keys are used otherwise."
  type        = bool
}

variable "enable_data_lineage" {
  description = "Connect Data Factory and Synapse to the Purview account so that their pipeline runs report lineage. Needs enable_data_catalog."
  type        = bool
}

variable "enable_access_control" {
  description = "Fine-grained access: no account keys on the data lake, Microsoft Entra-only sign-in to Synapse and Event Hubs, role assignments per data lake zone and ACL entries for the groups below. Otherwise services get account-wide roles and key or SQL authentication stays available."
  type        = bool
}

variable "data_engineer_group_object_id" {
  description = "Object ID of the Microsoft Entra group of data engineers. With access control it gets read and write ACL entries on every zone, otherwise Storage Blob Data Contributor on the data lake."
  type        = string
  default     = null
}

variable "data_analyst_group_object_id" {
  description = "Object ID of the Microsoft Entra group of analysts and report authors. With access control it gets a read ACL entry on the curated zone only, otherwise Storage Blob Data Reader on the data lake."
  type        = string
  default     = null
}

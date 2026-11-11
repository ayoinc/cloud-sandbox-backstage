# Plans the stack against mocked providers, so the tests need no AWS account.
# The first run uses the values of terraform.tfvars. Every other run sets all
# the choices of the portal form itself, so it tests one combination whatever
# terraform.tfvars contains.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:role/terraform"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      issuer_arn = "arn:aws:iam::123456789012:role/terraform"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

run "configured_values" {
  command = plan

  assert {
    condition     = length(module.lake) == (var.enable_data_lake ? 3 : 0)
    error_message = "The data lake has one bucket per zone exactly when enable_data_lake is true."
  }

  assert {
    condition     = length(aws_glue_catalog_database.zone) == (var.enable_data_catalog ? 3 : 0)
    error_message = "The data catalog has one database per zone exactly when enable_data_catalog is true."
  }

  assert {
    condition     = length(aws_redshift_cluster.warehouse) == (var.enable_data_warehouse ? 1 : 0)
    error_message = "A Redshift cluster exists exactly when enable_data_warehouse is true."
  }

  assert {
    condition     = length(aws_glue_job.etl) + 2 * length(aws_emrserverless_application.etl) == (var.enable_etl_pipelines ? 2 : 0)
    error_message = "ETL runs as two Glue jobs or on one EMR Serverless application exactly when enable_etl_pipelines is true."
  }

  assert {
    condition     = aws_redshift_cluster.warehouse[*].number_of_nodes == [for nodes in [local.warehouse_nodes[var.warehouse_size]] : nodes if var.enable_data_warehouse]
    error_message = "The cluster has the number of nodes of the chosen warehouse_size."
  }

  assert {
    condition     = length(aws_sfn_state_machine.pipeline) == (var.enable_orchestration && (var.enable_etl_pipelines || (var.enable_data_catalog && var.enable_data_lake)) ? 1 : 0)
    error_message = "The state machine exists exactly when enable_orchestration is true and there is a step to run."
  }

  assert {
    condition     = aws_kinesis_stream.events[*].retention_period == [for hours in [var.streaming_retention_hours] : hours if var.enable_streaming]
    error_message = "The stream keeps records for streaming_retention_hours."
  }

  assert {
    condition     = contains(keys(aws_athena_workgroup.consumer), "bi") == var.enable_bi_tools
    error_message = "The BI workgroup exists exactly when enable_bi_tools is true."
  }

  assert {
    condition     = length(aws_sagemaker_domain.ml) == (var.enable_ml_platform ? 1 : 0)
    error_message = "The SageMaker domain exists exactly when enable_ml_platform is true."
  }

  assert {
    condition     = length(aws_kinesis_stream.events) == (var.enable_streaming ? 1 : 0)
    error_message = "A Kinesis data stream exists exactly when enable_streaming is true."
  }

  assert {
    condition     = length(module.data_key) == (var.enable_encryption ? 1 : 0)
    error_message = "The customer managed key exists exactly when enable_encryption is true."
  }

  assert {
    condition     = length(aws_datazone_domain.lineage) == (var.enable_data_lineage ? 1 : 0)
    error_message = "The DataZone domain exists exactly when enable_data_lineage is true."
  }

  assert {
    condition     = length(aws_lakeformation_data_lake_settings.this) == (var.enable_access_control ? 1 : 0)
    error_message = "Lake Formation is configured exactly when enable_access_control is true."
  }
}

run "everything_with_glue_jobs" {
  command = plan

  variables {
    environment               = "staging"
    region                    = "us-west-2"
    enable_data_lake          = true
    data_lake_storage_class   = "infrequent"
    enable_data_catalog       = true
    enable_data_warehouse     = true
    warehouse_size            = "medium"
    enable_etl_pipelines      = true
    etl_engine                = "native"
    enable_orchestration      = true
    enable_streaming          = true
    streaming_retention_hours = 72
    enable_bi_tools           = true
    enable_ml_platform        = true
    enable_encryption         = true
    enable_data_lineage       = true
    enable_access_control     = true
  }

  assert {
    condition     = length(aws_glue_job.etl) == 2 && length(aws_emrserverless_application.etl) == 0
    error_message = "etl_engine = native runs the two ETL stages as Glue jobs."
  }

  assert {
    condition     = local.role_definitions.etl.services == ["glue.amazonaws.com"]
    error_message = "The ETL role is assumed by Glue."
  }

  assert {
    condition = (
      output.pipeline_steps == tolist([
        "RawToProcessed",
        "ProcessedToCurated",
        "CrawlRawZone",
        "CrawlProcessedZone",
        "CrawlCuratedZone",
        "PublishToWarehouse",
      ])
    )
    error_message = "The pipeline runs the ETL jobs, then the crawlers, then the publication to the warehouse."
  }

  assert {
    condition     = length(aws_sfn_state_machine.pipeline) == 1
    error_message = "enable_orchestration creates the state machine."
  }

  assert {
    condition     = alltrue([for crawler in aws_glue_crawler.zone : crawler.schedule == null])
    error_message = "Crawlers started by the pipeline have no schedule of their own."
  }

  assert {
    condition     = length(aws_glue_crawler.zone) == 3 && length(aws_glue_catalog_database.zone) == 3
    error_message = "Every zone has a database and a crawler."
  }

  assert {
    condition     = aws_redshift_cluster.warehouse[0].number_of_nodes == 4
    error_message = "warehouse_size = medium is a cluster of four nodes."
  }

  assert {
    condition     = local.lake_transitions[var.data_lake_storage_class][*].storage_class == ["STANDARD_IA"]
    error_message = "data_lake_storage_class = infrequent moves objects to STANDARD_IA."
  }

  assert {
    condition     = aws_kinesis_stream.events[0].retention_period == 72 && length(aws_kinesis_firehose_delivery_stream.lake) == 1
    error_message = "The stream keeps records for streaming_retention_hours and Firehose delivers them to the lake."
  }

  assert {
    condition     = sort(keys(aws_athena_workgroup.consumer)) == tolist(["bi", "ml"]) && length(aws_sagemaker_domain.ml) == 1
    error_message = "BI and ML each get an Athena workgroup, and ML a SageMaker domain."
  }

  assert {
    condition     = length(module.vpc) == 1 && length(module.vpc[0].nat_gateway_ids) == 0
    error_message = "The warehouse and the SageMaker domain run in a VPC without a NAT gateway."
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.use_data_key) == length(module.role) && length(module.role) == 9
    error_message = "Every component has a role and every role may use the customer managed key."
  }

  assert {
    condition     = length(aws_glue_security_configuration.this) == 1 && length(aws_glue_data_catalog_encryption_settings.this) == 1
    error_message = "Glue encrypts job data, logs and the catalog with the customer managed key."
  }

  assert {
    condition     = contains(keys(aws_glue_job.etl["raw_to_processed"].default_arguments), "--conf")
    error_message = "With data lineage the Glue jobs load the OpenLineage listener."
  }

  assert {
    condition = (
      sort(keys(aws_lakeformation_permissions.reader_tables)) == tolist([
        "bi/curated",
        "ml/curated",
        "ml/processed",
        "warehouse/curated",
      ])
    )
    error_message = "Lake Formation grants each consumer the tables of its zones."
  }

  assert {
    condition     = length(aws_lakeformation_resource.lake) == 3 && length(aws_lakeformation_permissions.writer_location) == 6
    error_message = "The lake buckets are registered with Lake Formation and the crawler and ETL roles may write to them."
  }
}

run "everything_with_emr_serverless_in_production" {
  command = plan

  variables {
    environment               = "production"
    region                    = "eu-west-1"
    enable_data_lake          = true
    data_lake_storage_class   = "archive"
    enable_data_catalog       = true
    enable_data_warehouse     = true
    warehouse_size            = "large"
    enable_etl_pipelines      = true
    etl_engine                = "spark"
    enable_orchestration      = true
    enable_streaming          = true
    streaming_retention_hours = 168
    enable_bi_tools           = true
    enable_ml_platform        = true
    enable_encryption         = true
    enable_data_lineage       = true
    enable_access_control     = true
  }

  assert {
    condition     = length(aws_emrserverless_application.etl) == 1 && length(aws_glue_job.etl) == 0
    error_message = "etl_engine = spark runs the ETL stages on an EMR Serverless application."
  }

  assert {
    condition     = local.role_definitions.etl.services == ["emr-serverless.amazonaws.com"]
    error_message = "The ETL role is assumed by EMR Serverless."
  }

  assert {
    condition     = length(aws_emrserverless_application.etl[0].network_configuration) == 1 && length(module.vpc[0].nat_gateway_ids) == 3
    error_message = "Spark jobs that report lineage run in the VPC, which has a NAT gateway per zone in production."
  }

  assert {
    condition     = aws_emrserverless_application.etl[0].runtime_configuration[0].classification == "spark-defaults"
    error_message = "With data lineage the application loads the OpenLineage listener."
  }

  assert {
    condition     = length(output.pipeline_steps) == 6 && length(aws_sfn_state_machine.pipeline) == 1
    error_message = "The pipeline has the same steps as with Glue jobs."
  }

  assert {
    condition     = aws_redshift_cluster.warehouse[0].number_of_nodes == 8
    error_message = "warehouse_size = large is a cluster of eight nodes."
  }

  assert {
    condition     = aws_redshift_cluster.warehouse[0].skip_final_snapshot == false && aws_redshift_cluster.warehouse[0].automated_snapshot_retention_period == 14
    error_message = "Production keeps a final snapshot and two weeks of automated snapshots of the warehouse."
  }

  assert {
    condition     = local.lake_transitions[var.data_lake_storage_class][*].storage_class == ["STANDARD_IA", "GLACIER_IR"]
    error_message = "data_lake_storage_class = archive moves objects to STANDARD_IA and then to GLACIER_IR."
  }

  assert {
    condition     = aws_kinesis_stream.events[0].retention_period == 168
    error_message = "The stream keeps records for streaming_retention_hours."
  }

  assert {
    condition     = aws_sagemaker_domain.ml[0].retention_policy[0].home_efs_file_system == "Retain"
    error_message = "Production keeps the home directories of a deleted SageMaker domain."
  }

  assert {
    condition     = local.catalog_arn == "arn:aws:glue:eu-west-1:123456789012:catalog"
    error_message = "Resource names follow the chosen region."
  }
}

run "data_lake_only" {
  command = plan

  variables {
    region                  = "eu-central-1"
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_catalog     = false
    enable_data_warehouse   = false
    warehouse_size          = "small"
    enable_etl_pipelines    = false
    etl_engine              = "native"
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = false
    enable_encryption       = false
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = sort(keys(module.lake)) == tolist(["curated", "processed", "raw"])
    error_message = "The data lake has a raw, a processed and a curated bucket."
  }

  assert {
    condition     = length(local.lake_transitions[var.data_lake_storage_class]) == 0
    error_message = "data_lake_storage_class = standard keeps objects in the standard storage class."
  }

  assert {
    condition     = length(module.role) == 0 && length(module.data_key) == 0 && length(module.artifacts) == 0 && length(module.vpc) == 0
    error_message = "Nothing but the data lake is created."
  }

  assert {
    condition     = length(aws_glue_catalog_database.zone) + length(aws_redshift_cluster.warehouse) + length(aws_glue_job.etl) + length(aws_sfn_state_machine.pipeline) + length(aws_kinesis_stream.events) + length(aws_athena_workgroup.consumer) + length(aws_sagemaker_domain.ml) + length(aws_datazone_domain.lineage) + length(aws_lakeformation_data_lake_settings.this) == 0
    error_message = "Disabled components create no resources."
  }
}

run "nothing_enabled" {
  command = plan

  variables {
    enable_data_lake        = false
    data_lake_storage_class = "standard"
    enable_data_catalog     = false
    enable_data_warehouse   = false
    warehouse_size          = "small"
    enable_etl_pipelines    = false
    etl_engine              = "native"
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = false
    enable_encryption       = false
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = length(module.lake) == 0 && length(module.role) == 0 && length(module.artifacts) == 0 && length(module.vpc) == 0 && length(module.data_key) == 0
    error_message = "With every component disabled the stack is empty."
  }
}

run "components_without_data_lake" {
  command = plan

  variables {
    environment               = "staging"
    enable_data_lake          = false
    data_lake_storage_class   = "standard"
    enable_data_catalog       = true
    enable_data_warehouse     = true
    warehouse_size            = "small"
    enable_etl_pipelines      = true
    etl_engine                = "spark"
    enable_orchestration      = true
    enable_streaming          = true
    streaming_retention_hours = 48
    enable_bi_tools           = true
    enable_ml_platform        = true
    enable_encryption         = false
    enable_data_lineage       = false
    enable_access_control     = true
  }

  assert {
    condition     = length(module.lake) == 0 && length(module.artifacts) == 1
    error_message = "Without the data lake only the artifacts bucket exists."
  }

  assert {
    condition     = length(aws_glue_catalog_database.zone) == 3 && length(aws_glue_crawler.zone) == 0
    error_message = "The catalog keeps its databases but has nothing to crawl."
  }

  assert {
    condition     = alltrue([for uri in values(local.zone_uris) : startswith(uri, "s3://${local.artifacts_bucket}/zones/")])
    error_message = "The ETL jobs work in the staging area of the artifacts bucket."
  }

  assert {
    condition     = length(aws_emrserverless_application.etl[0].network_configuration) == 0 && length(module.vpc[0].nat_gateway_ids) == 0
    error_message = "Spark jobs that do not report lineage need no VPC."
  }

  assert {
    condition     = output.pipeline_steps == tolist(["RawToProcessed", "ProcessedToCurated"])
    error_message = "The pipeline runs the ETL jobs only."
  }

  assert {
    condition     = length(aws_kinesis_stream.events) == 1 && length(aws_kinesis_firehose_delivery_stream.lake) == 0
    error_message = "The stream exists without a delivery to the lake."
  }

  assert {
    condition     = aws_kinesis_stream.events[0].kms_key_id == "alias/aws/kinesis"
    error_message = "Without the customer managed key the stream uses the AWS managed key."
  }

  assert {
    condition     = length(aws_redshift_cluster.warehouse) == 1 && !contains(keys(module.role), "warehouse")
    error_message = "The warehouse has no role for the lake."
  }

  assert {
    condition     = length(aws_lakeformation_data_lake_settings.this) == 1 && length(aws_lakeformation_resource.lake) == 0 && !local.lake_formation_governs
    error_message = "Lake Formation is configured but has no buckets or tables to govern."
  }

  assert {
    condition     = length(aws_iam_role_policy.lake_read) == 0 && length(aws_athena_workgroup.consumer) == 2
    error_message = "BI and ML keep their workgroups but get no access to a lake."
  }
}

run "etl_without_warehouse_or_catalog" {
  command = plan

  variables {
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_catalog     = false
    enable_data_warehouse   = false
    warehouse_size          = "small"
    enable_etl_pipelines    = true
    etl_engine              = "native"
    enable_orchestration    = true
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = false
    enable_encryption       = true
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = output.pipeline_steps == tolist(["RawToProcessed", "ProcessedToCurated"]) && length(aws_glue_job.etl) == 2
    error_message = "The pipeline runs the ETL jobs and has no crawler or warehouse step."
  }

  assert {
    condition     = length(module.vpc) == 0 && length(aws_redshift_cluster.warehouse) == 0
    error_message = "Glue jobs need no VPC."
  }

  assert {
    condition     = !contains(keys(aws_glue_job.etl["raw_to_processed"].default_arguments), "--conf")
    error_message = "Without data lineage the Glue jobs do not load the OpenLineage listener."
  }

  assert {
    condition     = aws_glue_job.etl["processed_to_curated"].default_arguments["--target_path"] == "s3://${module.lake["curated"].bucket_name}/"
    error_message = "The last ETL stage writes to the curated bucket."
  }

  assert {
    condition     = sort(keys(module.role)) == tolist(["etl", "pipeline"])
    error_message = "Only the ETL jobs and the pipeline have roles."
  }
}

run "orchestration_without_steps" {
  command = plan

  variables {
    enable_data_lake          = true
    data_lake_storage_class   = "standard"
    enable_data_catalog       = false
    enable_data_warehouse     = false
    warehouse_size            = "small"
    enable_etl_pipelines      = false
    etl_engine                = "native"
    enable_orchestration      = true
    enable_streaming          = true
    streaming_retention_hours = 24
    enable_bi_tools           = false
    enable_ml_platform        = false
    enable_encryption         = false
    enable_data_lineage       = false
    enable_access_control     = false
  }

  assert {
    condition     = length(aws_sfn_state_machine.pipeline) == 0 && !contains(keys(module.role), "pipeline")
    error_message = "No state machine is created while there is nothing to orchestrate."
  }

  assert {
    condition     = length(aws_kinesis_firehose_delivery_stream.lake) == 1 && aws_kinesis_stream.events[0].retention_period == 24
    error_message = "Streaming delivers to the lake on its own."
  }
}

run "catalog_without_orchestration" {
  command = plan

  variables {
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_catalog     = true
    enable_data_warehouse   = true
    warehouse_size          = "small"
    enable_etl_pipelines    = false
    etl_engine              = "native"
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = true
    enable_ml_platform      = false
    enable_encryption       = false
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = alltrue([for crawler in aws_glue_crawler.zone : crawler.schedule == var.crawler_schedule])
    error_message = "Without the pipeline the crawlers run on their schedule."
  }

  assert {
    condition     = aws_redshift_cluster.warehouse[0].number_of_nodes == 2
    error_message = "warehouse_size = small is a cluster of two nodes."
  }

  assert {
    condition     = length(aws_lakeformation_permissions.reader_tables) == 0 && sort(keys(aws_iam_role_policy.lake_read)) == tolist(["bi", "warehouse"])
    error_message = "Without Lake Formation access control the consumers read the lake through IAM policies."
  }

  assert {
    condition     = aws_athena_workgroup.consumer["bi"].configuration[0].result_configuration[0].encryption_configuration[0].encryption_option == "SSE_S3"
    error_message = "Without the customer managed key query results use S3 managed encryption."
  }

  assert {
    condition     = length(aws_glue_security_configuration.this) == 0 && length(aws_glue_data_catalog_encryption_settings.this) == 0 && length(aws_iam_role_policy_attachment.use_data_key) == 0
    error_message = "Without the customer managed key Glue has no encryption settings of its own."
  }

  assert {
    condition     = length(aws_sagemaker_domain.ml) == 0 && sort(keys(aws_athena_workgroup.consumer)) == tolist(["bi"])
    error_message = "Only the BI tools get a workgroup."
  }
}

run "lineage_and_access_control_without_etl" {
  command = plan

  variables {
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_catalog     = true
    enable_data_warehouse   = false
    warehouse_size          = "small"
    enable_etl_pipelines    = false
    etl_engine              = "native"
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = true
    enable_encryption       = true
    enable_data_lineage     = true
    enable_access_control   = true
  }

  assert {
    condition     = length(aws_datazone_domain.lineage) == 1 && length(aws_glue_job.etl) == 0
    error_message = "The lineage domain exists without ETL jobs."
  }

  assert {
    condition     = sort(keys(aws_lakeformation_permissions.reader_tables)) == tolist(["ml/curated", "ml/processed"])
    error_message = "The ML platform reads the processed and curated zones through Lake Formation."
  }

  assert {
    condition     = sort(keys(aws_lakeformation_permissions.writer_database)) == tolist(["crawler/curated", "crawler/processed", "crawler/raw"])
    error_message = "The crawlers may create tables in every zone."
  }

  assert {
    condition     = length(aws_lakeformation_permissions.etl_create_database) == 0
    error_message = "Permissions of the ETL role are not granted without ETL."
  }

  assert {
    condition     = aws_athena_workgroup.consumer["ml"].configuration[0].result_configuration[0].encryption_configuration[0].encryption_option == "SSE_KMS"
    error_message = "Query results are encrypted with the customer managed key."
  }

  assert {
    condition     = length(output.pipeline_steps) == 0 && length(aws_sagemaker_user_profile.ml) == 1
    error_message = "There is no pipeline, and the SageMaker domain has its user profile."
  }
}

# The portal form only offers 24 to 168 hours. Values edited by hand are moved
# into the range Kinesis accepts instead of failing.
run "streaming_retention_outside_the_kinesis_limits_below" {
  command = plan

  variables {
    enable_data_lake          = false
    data_lake_storage_class   = "standard"
    enable_data_catalog       = false
    enable_data_warehouse     = false
    warehouse_size            = "small"
    enable_etl_pipelines      = false
    etl_engine                = "native"
    enable_orchestration      = false
    enable_streaming          = true
    streaming_retention_hours = 6
    enable_bi_tools           = false
    enable_ml_platform        = false
    enable_encryption         = false
    enable_data_lineage       = false
    enable_access_control     = false
  }

  assert {
    condition     = aws_kinesis_stream.events[0].retention_period == 24
    error_message = "A retention below the Kinesis minimum becomes 24 hours."
  }
}

run "streaming_retention_outside_the_kinesis_limits_above" {
  command = plan

  variables {
    enable_data_lake          = false
    data_lake_storage_class   = "standard"
    enable_data_catalog       = false
    enable_data_warehouse     = false
    warehouse_size            = "small"
    enable_etl_pipelines      = false
    etl_engine                = "native"
    enable_orchestration      = false
    enable_streaming          = true
    streaming_retention_hours = 20000
    enable_bi_tools           = false
    enable_ml_platform        = false
    enable_encryption         = false
    enable_data_lineage       = false
    enable_access_control     = false
  }

  assert {
    condition     = aws_kinesis_stream.events[0].retention_period == 8760
    error_message = "A retention above the Kinesis maximum becomes 8760 hours."
  }
}

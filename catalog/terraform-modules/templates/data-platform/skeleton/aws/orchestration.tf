# -----------------------------------------------------------------------------
# Orchestration: a Step Functions state machine that runs the pipeline in
# order: the ETL jobs, then the crawlers, then the publication of the curated
# zone to the warehouse. A step exists only when its component is enabled, and
# the state machine only when there is at least one step.
# -----------------------------------------------------------------------------

locals {
  pipeline_has_steps = var.enable_etl_pipelines || local.crawls_lake || local.publishes_to_warehouse
  pipeline_enabled   = var.enable_orchestration && local.pipeline_has_steps
  pipeline_name      = "${local.name_prefix}-pipeline"

  states_integration = "arn:${local.partition}:states:::"

  # Each step is a group of states. "__NEXT__" stands for the first state of
  # the step that follows it.
  pipeline_etl_steps = [
    for key in local.etl_stage_order : {
      entry = local.etl_stages[key].state
      states = local.etl_native ? jsonencode({
        (local.etl_stages[key].state) = {
          Type       = "Task"
          Resource   = "${local.states_integration}glue:startJobRun.sync"
          Parameters = { JobName = local.etl_job_names[key] }
          ResultPath = null
          Next       = "__NEXT__"
        }
        }) : jsonencode({
        (local.etl_stages[key].state) = {
          Type     = "Task"
          Resource = "${local.states_integration}emr-serverless:startJobRun.sync"
          Parameters = {
            Name             = local.etl_job_names[key]
            ApplicationId    = one(aws_emrserverless_application.etl[*].id)
            ExecutionRoleArn = module.role["etl"].role_arn
            JobDriver = {
              SparkSubmit = {
                EntryPoint          = local.etl_script_uris[key]
                EntryPointArguments = flatten([for name, value in local.etl_arguments[key] : [name, value]])
              }
            }
          }
          ResultPath = null
          Next       = "__NEXT__"
        }
      })
    } if var.enable_etl_pipelines
  ]

  # A crawler that is still running from an earlier execution is left to finish.
  pipeline_crawler_steps = [
    for zone in local.zones : {
      entry = "Crawl${title(zone)}Zone"
      states = jsonencode({
        "Crawl${title(zone)}Zone" = {
          Type       = "Task"
          Resource   = "${local.states_integration}aws-sdk:glue:startCrawler"
          Parameters = { Name = aws_glue_crawler.zone[zone].name }
          ResultPath = null
          Catch = [{
            ErrorEquals = ["Glue.CrawlerRunningException"]
            ResultPath  = null
            Next        = "__NEXT__"
          }]
          Next = "__NEXT__"
        }
      })
    } if local.crawls_lake
  ]

  # The external schema makes every table of the curated zone queryable from
  # the warehouse. The statement runs through the Redshift Data API, which is
  # asynchronous, so the states poll until it has finished.
  pipeline_warehouse_steps = local.publishes_to_warehouse ? [{
    entry = "PublishToWarehouse"
    states = jsonencode({
      PublishToWarehouse = {
        Type     = "Task"
        Resource = "${local.states_integration}aws-sdk:redshiftdata:executeStatement"
        Parameters = {
          ClusterIdentifier = aws_redshift_cluster.warehouse[0].cluster_identifier
          Database          = var.warehouse_database_name
          SecretArn         = aws_redshift_cluster.warehouse[0].master_password_secret_arn
          Sql               = "CREATE EXTERNAL SCHEMA IF NOT EXISTS ${local.warehouse_lake_schema} FROM DATA CATALOG DATABASE '${local.catalog_databases["curated"]}' IAM_ROLE '${module.role["warehouse"].role_arn}'"
        }
        Next = "WaitForWarehouse"
      }
      WaitForWarehouse = {
        Type    = "Wait"
        Seconds = 5
        Next    = "CheckWarehouseStatement"
      }
      CheckWarehouseStatement = {
        Type       = "Task"
        Resource   = "${local.states_integration}aws-sdk:redshiftdata:describeStatement"
        Parameters = { "Id.$" = "$.Id" }
        Next       = "WarehouseStatementFinished"
      }
      WarehouseStatementFinished = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.Status"
            StringEquals = "FINISHED"
            Next         = "__NEXT__"
          },
          {
            Or = [
              { Variable = "$.Status", StringEquals = "FAILED" },
              { Variable = "$.Status", StringEquals = "ABORTED" },
            ]
            Next = "WarehousePublicationFailed"
          },
        ]
        Default = "WaitForWarehouse"
      }
      WarehousePublicationFailed = {
        Type  = "Fail"
        Error = "WarehousePublicationFailed"
        Cause = "The statement that publishes the curated zone to the warehouse did not finish."
      }
    })
  }] : []

  pipeline_steps = concat(local.pipeline_etl_steps, local.pipeline_crawler_steps, local.pipeline_warehouse_steps)

  pipeline_definition = jsonencode({
    Comment = "Data pipeline of the ${local.name_prefix} data platform"
    StartAt = try(local.pipeline_steps[0].entry, "PipelineSucceeded")
    States = merge(
      { PipelineSucceeded = { Type = "Succeed" } },
      [
        for index, step in local.pipeline_steps : jsondecode(replace(
          step.states,
          "__NEXT__",
          index + 1 < length(local.pipeline_steps) ? local.pipeline_steps[index + 1].entry : "PipelineSucceeded",
        ))
      ]...
    )
  })
}

data "aws_iam_policy_document" "pipeline" {
  count = local.pipeline_enabled ? 1 : 0

  dynamic "statement" {
    for_each = local.etl_native ? [1] : []

    content {
      sid     = "RunGlueJobs"
      actions = ["glue:StartJobRun", "glue:GetJobRun", "glue:GetJobRuns", "glue:BatchStopJobRun"]
      resources = [
        for name in values(local.etl_job_names) : "arn:${local.partition}:glue:${var.region}:${local.account_id}:job/${name}"
      ]
    }
  }

  dynamic "statement" {
    for_each = local.etl_spark ? [1] : []

    content {
      sid       = "StartSparkJobs"
      actions   = ["emr-serverless:StartJobRun"]
      resources = [aws_emrserverless_application.etl[0].arn]
    }
  }

  dynamic "statement" {
    for_each = local.etl_spark ? [1] : []

    content {
      sid       = "FollowSparkJobs"
      actions   = ["emr-serverless:GetJobRun", "emr-serverless:CancelJobRun"]
      resources = ["${aws_emrserverless_application.etl[0].arn}/jobruns/*"]
    }
  }

  dynamic "statement" {
    for_each = local.etl_spark ? [1] : []

    content {
      sid       = "PassJobRole"
      actions   = ["iam:PassRole"]
      resources = [module.role["etl"].role_arn]

      condition {
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["emr-serverless.amazonaws.com"]
      }
    }
  }

  # Step Functions tracks the Spark job runs through this managed EventBridge rule.
  dynamic "statement" {
    for_each = local.etl_spark ? [1] : []

    content {
      sid       = "TrackSparkJobs"
      actions   = ["events:PutTargets", "events:PutRule", "events:DescribeRule"]
      resources = ["arn:${local.partition}:events:${var.region}:${local.account_id}:rule/StepFunctionsGetEventsForEMRServerlessJobRule"]
    }
  }

  dynamic "statement" {
    for_each = local.crawls_lake ? [1] : []

    content {
      sid       = "StartCrawlers"
      actions   = ["glue:StartCrawler"]
      resources = values(aws_glue_crawler.zone)[*].arn
    }
  }

  dynamic "statement" {
    for_each = local.publishes_to_warehouse ? [1] : []

    content {
      sid       = "RunWarehouseStatement"
      actions   = ["redshift-data:ExecuteStatement"]
      resources = [local.warehouse_arn]
    }
  }

  dynamic "statement" {
    for_each = local.publishes_to_warehouse ? [1] : []

    content {
      sid       = "FollowWarehouseStatement"
      actions   = ["redshift-data:DescribeStatement"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = local.publishes_to_warehouse ? [1] : []

    content {
      sid       = "ReadWarehouseAdminSecret"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [aws_redshift_cluster.warehouse[0].master_password_secret_arn]
    }
  }

  statement {
    sid = "DeliverLogs"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid = "SendTraces"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  count = local.pipeline_enabled ? 1 : 0

  name   = "pipeline"
  role   = module.role["pipeline"].role_name
  policy = data.aws_iam_policy_document.pipeline[0].json
}

resource "aws_cloudwatch_log_group" "pipeline" {
  count = local.pipeline_enabled ? 1 : 0

  name              = "/aws/vendedlogs/states/${local.pipeline_name}"
  retention_in_days = local.is_production ? 365 : 30
  kms_key_id        = local.kms_key_arn
}

resource "aws_sfn_state_machine" "pipeline" {
  count = local.pipeline_enabled ? 1 : 0

  name       = local.pipeline_name
  role_arn   = module.role["pipeline"].role_arn
  type       = "STANDARD"
  definition = local.pipeline_definition

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.pipeline[0].arn}:*"
    level                  = "ERROR"
    include_execution_data = false
  }

  tracing_configuration {
    enabled = true
  }

  depends_on = [
    aws_iam_role_policy.pipeline,
    aws_glue_job.etl,
    aws_redshift_logging.warehouse,
  ]
}

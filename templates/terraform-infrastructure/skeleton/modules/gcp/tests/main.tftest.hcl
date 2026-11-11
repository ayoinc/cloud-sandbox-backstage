# Plan-only tests against mocked providers: no credentials, no resources.
# Run with: terraform init -backend=false && terraform test

mock_provider "google" {
  mock_data "google_project" {
    defaults = {
      number = "123456789012"
    }
  }

  mock_data "google_compute_zones" {
    defaults = {
      names = ["europe-west2-a", "europe-west2-b", "europe-west2-c"]
    }
  }

  mock_data "google_storage_project_service_account" {
    defaults = {
      email_address = "service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
      member        = "serviceAccount:service-123456789012@gs-project-accounts.iam.gserviceaccount.com"
    }
  }

  mock_data "google_storage_transfer_project_service_account" {
    defaults = {
      email  = "project-123456789012@storage-transfer-service.iam.gserviceaccount.com"
      member = "serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com"
    }
  }

  mock_data "google_logging_project_cmek_settings" {
    defaults = {
      service_account_id = "cmek-p123456789012@gcp-sa-logging.iam.gserviceaccount.com"
    }
  }
}

mock_provider "google-beta" {}

mock_provider "random" {}

mock_provider "time" {}

mock_provider "tls" {}

# Everything is switched off except the network.
variables {
  project_id                  = "test-project"
  name_prefix                 = "acme-dev"
  environment                 = "development"
  region                      = "europe-west2"
  tags                        = { Owner = "platform" }
  infrastructure_type         = "web-application"
  enable_networking           = true
  network_cidr                = "10.0.0.0/16"
  enable_security_group_rules = false
  enable_kubernetes           = false
  node_size                   = "small"
  enable_autoscaling          = true
  min_nodes                   = 1
  max_nodes                   = 3
  enable_database             = false
  database_type               = "postgresql"
  enable_storage              = false
  enable_cdn                  = false
  enable_waf                  = false
  enable_secrets_manager      = false
  enable_kms                  = false
  enable_backup               = false
  enable_monitoring           = false
  enable_managed_prometheus   = false
  enable_alerting             = false
  log_retention_days          = 30
  enable_disaster_recovery    = false
  enable_cost_optimization    = false
  require_deletion_protection = false
  require_flow_logs           = false
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

run "defaults_minimal" {
  command = plan

  assert {
    condition     = length(google_compute_network.this) == 1 && google_compute_network.this[0].auto_create_subnetworks == false
    error_message = "One custom-mode network must be created."
  }

  assert {
    condition     = google_compute_subnetwork.public[*].ip_cidr_range == ["10.0.0.0/20", "10.0.16.0/20"]
    error_message = "The two public subnets must be the first two /20 blocks."
  }

  assert {
    condition     = google_compute_subnetwork.private[*].ip_cidr_range == ["10.0.128.0/20", "10.0.144.0/20"]
    error_message = "The two private subnets must be blocks 8 and 9."
  }

  assert {
    condition     = alltrue([for subnet in google_compute_subnetwork.private : length(subnet.log_config) == 0])
    error_message = "Flow logs must be off unless require_flow_logs is true."
  }

  assert {
    condition     = length(google_compute_router_nat.this) == 1 && google_compute_router_nat.this[0].source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS"
    error_message = "Cloud NAT must serve the private subnets."
  }

  assert {
    condition     = keys(google_project_service.this) == ["compute.googleapis.com"]
    error_message = "Only the Compute Engine API is needed for the network."
  }

  assert {
    condition     = length(google_compute_firewall.internal) == 1 && google_compute_firewall.internal[0].source_ranges == toset(["10.0.0.0/16"])
    error_message = "Without tier rules, traffic is allowed from inside the network range only."
  }

  assert {
    condition = (
      length(google_container_cluster.this) == 0 && length(google_sql_database_instance.this) == 0 &&
      length(google_redis_instance.this) == 0 && length(google_storage_bucket.this) == 0 &&
      length(google_kms_crypto_key.this) == 0 && length(google_backup_dr_backup_vault.this) == 0 &&
      length(google_logging_project_bucket_config.this) == 0 && length(google_pubsub_topic.alerts) == 0 &&
      length(google_compute_security_policy.this) == 0 && length(google_artifact_registry_repository.containers) == 0 &&
      length(google_dns_managed_zone.private) == 0 && length(google_project_service_identity.this) == 0
    )
    error_message = "Nothing but the network may be created with every feature off."
  }

  assert {
    condition = (
      output.kubernetes_cluster_name == null && output.database_endpoint == null && output.database_name == null &&
      output.database_credentials_secret_id == null && nonsensitive(output.database_password == null) &&
      output.storage_bucket_name == null && length(output.data_lake_bucket_names) == 0 &&
      output.cdn_domain_name == null && output.waf_id == null && output.kms_key_id == null &&
      output.secrets_store_id == null && output.container_registry_url == null &&
      output.private_dns_zone_name == null && output.backup_vault_id == null &&
      output.log_destination_id == null && output.alert_target_id == null &&
      output.prometheus_endpoint == null && output.grafana_endpoint == null
    )
    error_message = "Outputs of components that are not created must be null or empty."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "The subnet outputs must list two subnets each."
  }
}

run "tier_firewall_rules" {
  command = plan

  variables {
    enable_security_group_rules = true
    allowed_ingress_cidrs       = ["203.0.113.0/24"]
    enable_kubernetes           = true
    enable_database             = true
  }

  assert {
    condition     = length(google_compute_firewall.internal) == 0
    error_message = "The flat internal rule must not exist next to tier rules."
  }

  assert {
    condition     = google_compute_firewall.web[0].source_ranges == toset(["130.211.0.0/22", "35.191.0.0/16", "203.0.113.0/24"])
    error_message = "The web tier must accept the allowed clients and Google load balancers only."
  }

  assert {
    condition     = flatten([for rule in google_compute_firewall.web[0].allow : rule.ports]) == ["443"]
    error_message = "The web tier must accept HTTPS only."
  }

  assert {
    condition     = google_compute_firewall.app[0].source_tags == toset(["acme-dev-web"]) && google_compute_firewall.app[0].target_tags == toset(["acme-dev-app"])
    error_message = "The app tier must accept traffic from the web tier only."
  }

  assert {
    condition     = google_compute_firewall.data[0].source_tags == toset(["acme-dev-app", "acme-dev-gke-node"])
    error_message = "The data tier must accept traffic from the app tier and the cluster nodes only."
  }

  assert {
    condition = (
      google_compute_firewall.managed_data_allow[0].destination_ranges == toset(["10.0.192.0/18"]) &&
      google_compute_firewall.managed_data_allow[0].target_tags == toset(["acme-dev-app", "acme-dev-gke-node"]) &&
      google_compute_firewall.managed_data_allow[0].priority < google_compute_firewall.managed_data_deny[0].priority
    )
    error_message = "Only the app tier and the cluster nodes may connect to the managed data stores."
  }

  assert {
    condition     = google_compute_firewall.managed_data_deny[0].direction == "EGRESS" && length(google_compute_firewall.managed_data_deny[0].deny) == 1
    error_message = "Every other instance must be denied access to the managed data stores."
  }

  assert {
    condition     = output.network_tags == { web = "acme-dev-web", app = "acme-dev-app", data = "acme-dev-data" }
    error_message = "The tier tags must be exposed."
  }
}

run "flow_logs_without_monitoring" {
  command = plan

  variables {
    require_flow_logs = true
  }

  assert {
    condition     = alltrue([for subnet in concat(google_compute_subnetwork.public, google_compute_subnetwork.private) : length(subnet.log_config) == 1])
    error_message = "Every subnet must record flow logs."
  }

  assert {
    condition     = length(google_logging_project_bucket_config.this) == 1 && google_logging_project_bucket_config.this[0].retention_days == 30
    error_message = "A log bucket with the requested retention must be created for the flow logs."
  }

  assert {
    condition     = google_logging_project_sink.this[0].filter == "log_id(\"compute.googleapis.com/vpc_flows\") OR log_id(\"networkmanagement.googleapis.com/vpc_flows\")"
    error_message = "Without monitoring the sink must route the flow logs only."
  }

  assert {
    condition     = length(google_monitoring_dashboard.this) == 0
    error_message = "No dashboard may be created without monitoring."
  }
}

run "existing_network" {
  command = plan

  variables {
    enable_networking           = false
    enable_security_group_rules = true
    enable_kubernetes           = true
    enable_database             = true
    require_flow_logs           = true
    infrastructure_type         = "networking-foundation"
    existing_network = {
      network_id         = "projects/test-project/global/networks/shared"
      public_subnet_ids  = ["projects/test-project/regions/europe-west2/subnetworks/public-1"]
      private_subnet_ids = ["projects/test-project/regions/europe-west2/subnetworks/private-1"]
    }
  }

  assert {
    condition = (
      length(google_compute_network.this) == 0 && length(google_compute_subnetwork.public) == 0 &&
      length(google_compute_subnetwork.private) == 0 && length(google_compute_router_nat.this) == 0
    )
    error_message = "No network resources may be created when an existing network is used."
  }

  assert {
    condition = (
      output.network_id == "projects/test-project/global/networks/shared" &&
      output.public_subnet_ids == tolist(["projects/test-project/regions/europe-west2/subnetworks/public-1"]) &&
      output.private_subnet_ids == tolist(["projects/test-project/regions/europe-west2/subnetworks/private-1"])
    )
    error_message = "The outputs must return the existing network."
  }

  assert {
    condition = (
      google_container_cluster.this[0].network == "projects/test-project/global/networks/shared" &&
      google_container_cluster.this[0].subnetwork == "projects/test-project/regions/europe-west2/subnetworks/private-1"
    )
    error_message = "The cluster must run in the first existing private subnet."
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].ip_configuration[0].private_network == "projects/test-project/global/networks/shared"
    error_message = "The database must be attached to the existing network."
  }

  assert {
    condition     = google_compute_global_address.private_services[0].prefix_length == 20 && google_compute_global_address.private_services[0].network == "projects/test-project/global/networks/shared"
    error_message = "A /20 range must be reserved in the existing network for private services access."
  }

  assert {
    condition     = google_network_management_vpc_flow_logs_config.existing[0].network == "projects/test-project/global/networks/shared"
    error_message = "Flow logs must be configured on the existing network."
  }

  assert {
    condition     = google_compute_firewall.web[0].network == "projects/test-project/global/networks/shared" && length(google_compute_firewall.internal) == 0
    error_message = "Tier rules must be created in the existing network."
  }

  assert {
    condition     = one(google_dns_managed_zone.private[0].private_visibility_config[0].networks[*].network_url) == "projects/test-project/global/networks/shared"
    error_message = "The private DNS zone must be attached to the existing network."
  }
}

run "existing_private_services_access" {
  command = plan

  variables {
    enable_networking              = false
    enable_database                = true
    create_private_services_access = false
    existing_network = {
      network_id         = "projects/test-project/global/networks/shared"
      public_subnet_ids  = []
      private_subnet_ids = []
    }
  }

  assert {
    condition     = length(google_compute_global_address.private_services) == 0 && length(google_service_networking_connection.private_services) == 0
    error_message = "No private services access may be created when the existing network already has one."
  }

  assert {
    condition     = length(google_sql_database_instance.this) == 1
    error_message = "The database must still be created."
  }
}

run "database_without_network_fails" {
  command = plan

  variables {
    enable_networking = false
    enable_database   = true
  }

  expect_failures = [google_compute_global_address.private_services]
}

run "kubernetes_without_network_fails" {
  command = plan

  variables {
    enable_networking = false
    enable_kubernetes = true
  }

  expect_failures = [google_container_cluster.this]
}

run "storage_needs_no_network" {
  command = plan

  variables {
    enable_networking           = false
    enable_security_group_rules = true
    enable_storage              = true
  }

  assert {
    condition     = output.network_id == null && length(output.public_subnet_ids) == 0 && length(output.private_subnet_ids) == 0
    error_message = "The network outputs must be empty without a network."
  }

  assert {
    condition     = length(google_compute_firewall.web) == 0 && length(google_storage_bucket.this) == 1
    error_message = "Components that need no network must work without one."
  }
}

# -----------------------------------------------------------------------------
# Kubernetes
# -----------------------------------------------------------------------------

run "kubernetes_autoscaling" {
  command = plan

  variables {
    enable_kubernetes = true
    node_size         = "medium"
    min_nodes         = 2
    max_nodes         = 6
  }

  assert {
    condition = (
      google_container_cluster.this[0].private_cluster_config[0].enable_private_nodes &&
      google_container_cluster.this[0].private_cluster_config[0].enable_private_endpoint
    )
    error_message = "Nodes must be private and the public API endpoint disabled when no client range is allowed."
  }

  assert {
    condition     = [for block in google_container_cluster.this[0].master_authorized_networks_config[0].cidr_blocks : block.cidr_block] == ["10.0.0.0/16"]
    error_message = "Only the network range may reach the Kubernetes API by default."
  }

  assert {
    condition     = google_container_cluster.this[0].workload_identity_config[0].workload_pool == "test-project.svc.id.goog"
    error_message = "Workload Identity must be enabled."
  }

  assert {
    condition     = google_container_cluster.this[0].enable_shielded_nodes && google_container_cluster.this[0].node_pool[0].node_config[0].shielded_instance_config[0].enable_secure_boot
    error_message = "Nodes must be shielded and use secure boot."
  }

  assert {
    condition     = google_container_cluster.this[0].node_pool[0].node_config[0].machine_type == "e2-custom-4-8192"
    error_message = "medium nodes must have 4 vCPU and 8 GB."
  }

  assert {
    condition = (
      google_container_cluster.this[0].node_pool[0].autoscaling[0].total_min_node_count == 2 &&
      google_container_cluster.this[0].node_pool[0].autoscaling[0].total_max_node_count == 6 &&
      google_container_cluster.this[0].node_pool[0].initial_node_count == 1
    )
    error_message = "The node pool must scale between min_nodes and max_nodes across the cluster."
  }

  assert {
    condition     = google_container_cluster.this[0].node_pool[0].node_config[0].spot == false
    error_message = "Spot nodes are used only with cost optimization outside production."
  }

  assert {
    condition     = google_container_cluster.this[0].node_pool[0].node_config[0].workload_metadata_config[0].mode == "GKE_METADATA" && google_container_cluster.this[0].node_pool[0].node_config[0].metadata["disable-legacy-endpoints"] == "true"
    error_message = "Pods must not reach the node metadata."
  }

  assert {
    condition     = google_container_cluster.this[0].monitoring_config[0].managed_prometheus[0].enabled == false && google_container_cluster.this[0].deletion_protection == false
    error_message = "Managed Prometheus and deletion protection follow their flags."
  }

  assert {
    condition     = google_project_iam_member.gke_nodes[0].role == "roles/container.defaultNodeServiceAccount"
    error_message = "The node service account must have the minimal node role."
  }

  assert {
    condition     = length(google_container_cluster.this[0].database_encryption) == 0 && length(google_gke_backup_backup_plan.this) == 0
    error_message = "Secrets encryption with a customer key and cluster backups follow their flags."
  }
}

run "kubernetes_fixed_size" {
  command = plan

  variables {
    enable_kubernetes  = true
    enable_autoscaling = false
    min_nodes          = 4
    max_nodes          = 8
  }

  assert {
    condition     = length(google_container_cluster.this[0].node_pool[0].autoscaling) == 0
    error_message = "The node pool must not autoscale when enable_autoscaling is false."
  }

  assert {
    condition     = google_container_cluster.this[0].node_pool[0].node_count == 2
    error_message = "Four nodes over three zones are rounded up to two per zone."
  }
}

run "kubernetes_public_api_clients" {
  command = plan

  variables {
    enable_kubernetes            = true
    kubernetes_version           = "1.35"
    kubernetes_api_allowed_cidrs = ["203.0.113.0/24"]
    enable_cost_optimization     = true
    enable_managed_prometheus    = true
  }

  assert {
    condition     = google_container_cluster.this[0].private_cluster_config[0].enable_private_endpoint == false
    error_message = "The public endpoint must be available to the allowed client ranges."
  }

  assert {
    condition     = toset([for block in google_container_cluster.this[0].master_authorized_networks_config[0].cidr_blocks : block.cidr_block]) == toset(["10.0.0.0/16", "203.0.113.0/24"])
    error_message = "The API must accept the network and the allowed client ranges only."
  }

  assert {
    condition     = google_container_cluster.this[0].min_master_version == "1.35"
    error_message = "kubernetes_version must set the control plane version."
  }

  assert {
    condition     = google_container_cluster.this[0].node_pool[0].node_config[0].spot && google_container_cluster.this[0].node_pool[0].autoscaling[0].location_policy == "ANY"
    error_message = "Cost optimization outside production must use Spot nodes."
  }

  assert {
    condition     = google_container_cluster.this[0].monitoring_config[0].managed_prometheus[0].enabled && google_container_cluster.this[0].cost_management_config[0].enabled
    error_message = "Managed Prometheus and cost allocation must be enabled on the cluster."
  }

  assert {
    condition     = output.prometheus_endpoint == "https://monitoring.googleapis.com/v1/projects/test-project/location/global/prometheus" && output.grafana_endpoint == null
    error_message = "The Prometheus endpoint must be returned; there is no managed Grafana."
  }

  assert {
    condition     = google_project_iam_member.prometheus_query[0].role == "roles/monitoring.viewer"
    error_message = "The query service account may only read metrics."
  }
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------

run "database_postgresql" {
  command = plan

  variables {
    enable_database = true
    database_type   = "postgresql"
  }

  assert {
    condition     = google_sql_database_instance.this[0].database_version == "POSTGRES_17" && length(google_redis_instance.this) == 0
    error_message = "postgresql must create a Cloud SQL for PostgreSQL instance."
  }

  assert {
    condition = (
      google_sql_database_instance.this[0].settings[0].ip_configuration[0].ipv4_enabled == false &&
      google_sql_database_instance.this[0].settings[0].ip_configuration[0].ssl_mode == "ENCRYPTED_ONLY"
    )
    error_message = "The database must be private and accept encrypted connections only."
  }

  assert {
    condition = (
      google_sql_database_instance.this[0].settings[0].backup_configuration[0].enabled &&
      google_sql_database_instance.this[0].settings[0].backup_configuration[0].point_in_time_recovery_enabled &&
      google_sql_database_instance.this[0].settings[0].backup_configuration[0].backup_retention_settings[0].retained_backups == 7
    )
    error_message = "Backups with point-in-time recovery must be on and 7 backups kept by default."
  }

  assert {
    condition = (
      google_sql_database_instance.this[0].settings[0].availability_type == "ZONAL" &&
      google_sql_database_instance.this[0].settings[0].tier == "db-custom-2-7680" &&
      google_sql_database_instance.this[0].deletion_protection == false
    )
    error_message = "Outside production the instance is zonal, mid-sized and unprotected unless required."
  }

  assert {
    condition     = contains([for flag in google_sql_database_instance.this[0].settings[0].database_flags : "${flag.name}=${flag.value}"], "log_connections=on")
    error_message = "Connection logging must be enabled."
  }

  assert {
    condition     = google_sql_database.this[0].name == "acme_dev" && google_sql_user.admin[0].name == "app_admin"
    error_message = "A database named after the prefix and an admin user must be created."
  }

  assert {
    condition     = google_compute_global_address.private_services[0].address == "10.0.192.0" && google_compute_global_address.private_services[0].prefix_length == 18
    error_message = "The last quarter of the network range must be reserved for private services access."
  }

  assert {
    condition     = output.database_name == "acme_dev" && output.database_credentials_secret_id == null && length(google_secret_manager_secret.database) == 0
    error_message = "Without a secret store the credentials are returned as outputs."
  }

  assert {
    condition     = keys(google_project_service.this) == ["compute.googleapis.com", "servicenetworking.googleapis.com", "sqladmin.googleapis.com"]
    error_message = "Only the APIs of the network and Cloud SQL may be enabled."
  }
}

run "database_mysql" {
  command = plan

  variables {
    enable_database          = true
    database_type            = "mysql"
    enable_cost_optimization = true
  }

  assert {
    condition     = google_sql_database_instance.this[0].database_version == "MYSQL_8_4"
    error_message = "mysql must create a Cloud SQL for MySQL instance."
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].backup_configuration[0].binary_log_enabled
    error_message = "MySQL needs binary logging for point-in-time recovery."
  }

  assert {
    condition     = contains([for flag in google_sql_database_instance.this[0].settings[0].database_flags : "${flag.name}=${flag.value}"], "local_infile=off")
    error_message = "Loading local files must be disabled."
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].tier == "db-custom-1-3840"
    error_message = "Cost optimization outside production must use the smallest tier."
  }

  assert {
    condition     = google_sql_user.admin[0].host == "%"
    error_message = "The MySQL user must be allowed to connect from the private network."
  }
}

run "database_redis" {
  command = plan

  variables {
    enable_database        = true
    database_type          = "redis"
    enable_secrets_manager = true
  }

  assert {
    condition     = length(google_redis_instance.this) == 1 && length(google_sql_database_instance.this) == 0 && length(random_password.database) == 0
    error_message = "redis must create a Memorystore instance and no Cloud SQL instance."
  }

  assert {
    condition = (
      google_redis_instance.this[0].auth_enabled &&
      google_redis_instance.this[0].transit_encryption_mode == "SERVER_AUTHENTICATION" &&
      google_redis_instance.this[0].connect_mode == "PRIVATE_SERVICE_ACCESS"
    )
    error_message = "Redis must be private, require AUTH and encrypt traffic."
  }

  assert {
    condition     = google_redis_instance.this[0].tier == "BASIC" && google_redis_instance.this[0].memory_size_gb == 2
    error_message = "Outside production Redis is a 2 GB basic instance."
  }

  assert {
    condition     = google_redis_instance.this[0].persistence_config[0].persistence_mode == "DISABLED"
    error_message = "Snapshots follow enable_backup."
  }

  assert {
    condition     = length(google_secret_manager_secret.database) == 1 && nonsensitive(output.database_password == null) && output.database_name == null
    error_message = "The AUTH string must be stored in Secret Manager and not returned."
  }

  assert {
    condition     = output.secrets_store_id == "projects/test-project"
    error_message = "The project path is the secret store."
  }
}

run "database_type_of_another_cloud_is_rejected" {
  command = plan

  variables {
    enable_database = true
    database_type   = "dynamodb"
  }

  expect_failures = [var.database_type]
}

run "database_type_is_ignored_without_database" {
  command = plan

  variables {
    database_type = "dynamodb"
  }

  assert {
    condition     = length(google_sql_database_instance.this) == 0 && length(google_redis_instance.this) == 0
    error_message = "No database may be created when enable_database is false."
  }
}

# -----------------------------------------------------------------------------
# Storage, CDN and WAF
# -----------------------------------------------------------------------------

run "storage_only" {
  command = plan

  variables {
    enable_storage = true
  }

  assert {
    condition     = keys(google_storage_bucket.this) == ["assets"]
    error_message = "One assets bucket must be created."
  }

  assert {
    condition = (
      google_storage_bucket.this["assets"].uniform_bucket_level_access &&
      google_storage_bucket.this["assets"].public_access_prevention == "enforced" &&
      google_storage_bucket.this["assets"].versioning[0].enabled
    )
    error_message = "The bucket must be private and versioned."
  }

  assert {
    condition     = length(google_storage_bucket.this["assets"].encryption) == 0 && length(google_storage_bucket.this["assets"].autoclass) == 0
    error_message = "Customer-managed encryption and Autoclass follow their flags."
  }

  assert {
    condition     = length(google_storage_bucket.replica) == 0 && length(google_storage_transfer_job.replication) == 0
    error_message = "Replication follows enable_disaster_recovery."
  }
}

run "cdn_with_waf" {
  command = plan

  variables {
    enable_storage    = true
    enable_cdn        = true
    enable_waf        = true
    enable_monitoring = true
  }

  assert {
    condition = (
      google_compute_backend_service.cdn[0].enable_cdn &&
      google_compute_backend_service.cdn[0].protocol == "HTTPS" &&
      google_compute_backend_service.cdn[0].load_balancing_scheme == "EXTERNAL_MANAGED"
    )
    error_message = "The CDN backend must reach the bucket over HTTPS."
  }

  assert {
    condition     = google_storage_bucket.this["assets"].public_access_prevention == "enforced" && google_storage_bucket_iam_member.cdn_origin[0].role == "roles/storage.objectViewer"
    error_message = "The bucket must stay private; only the CDN identity may read it."
  }

  assert {
    condition     = google_compute_backend_service.cdn[0].security_settings[0].aws_v4_authentication[0].origin_region == "europe-west2"
    error_message = "Requests to the bucket must be signed."
  }

  assert {
    condition     = length(google_compute_security_policy.this) == 1 && google_compute_security_policy.this[0].type == "CLOUD_ARMOR"
    error_message = "A Cloud Armor policy must be created."
  }

  assert {
    condition     = length([for rule in google_compute_security_policy.this[0].rule : rule if rule.action == "deny(403)"]) == 9
    error_message = "The policy must block with the nine preconfigured rule sets."
  }

  assert {
    condition     = google_compute_url_map.cdn_redirect[0].default_url_redirect[0].https_redirect && google_compute_global_forwarding_rule.cdn_https[0].port_range == "443"
    error_message = "HTTP must be redirected to HTTPS."
  }

  assert {
    condition     = google_compute_ssl_policy.cdn[0].min_tls_version == "TLS_1_2"
    error_message = "The CDN must refuse TLS versions older than 1.2."
  }

  assert {
    condition     = length(google_compute_ssl_certificate.cdn) == 1 && length(google_compute_managed_ssl_certificate.cdn) == 0
    error_message = "Without a domain the endpoint uses a self-signed certificate."
  }

  assert {
    condition     = google_compute_backend_service.cdn[0].log_config[0].enable
    error_message = "With monitoring the CDN must log its requests."
  }
}

run "cdn_without_waf_with_domain" {
  command = plan

  variables {
    enable_storage = true
    enable_cdn     = true
    cdn_domain     = "assets.example.com"
  }

  assert {
    condition     = length(google_compute_security_policy.this) == 0 && google_compute_backend_service.cdn[0].security_policy == null
    error_message = "No WAF policy may be created or attached when enable_waf is false."
  }

  assert {
    condition     = length(google_compute_managed_ssl_certificate.cdn) == 1 && length(tls_private_key.cdn) == 0 && length(google_compute_ssl_certificate.cdn) == 0
    error_message = "With a domain Google manages the certificate."
  }

  assert {
    condition     = google_compute_managed_ssl_certificate.cdn[0].managed[0].domains == tolist(["assets.example.com"]) && output.cdn_domain_name == "assets.example.com"
    error_message = "The certificate and the output must use the domain."
  }
}

run "waf_standalone" {
  command = plan

  variables {
    enable_waf = true
  }

  assert {
    condition     = length(google_compute_security_policy.this) == 1 && length(google_compute_backend_service.cdn) == 0
    error_message = "Without a CDN the WAF policy is created on its own."
  }
}

run "cdn_needs_storage" {
  command = plan

  variables {
    enable_cdn = true
  }

  expect_failures = [var.enable_cdn]
}

# -----------------------------------------------------------------------------
# Infrastructure types
# -----------------------------------------------------------------------------

run "type_web_application" {
  command = plan

  assert {
    condition = (
      length(google_artifact_registry_repository.containers) == 0 && length(google_storage_bucket.this) == 0 &&
      length(google_dns_managed_zone.private) == 0
    )
    error_message = "web-application adds nothing."
  }
}

run "type_data_platform" {
  command = plan

  variables {
    infrastructure_type = "data-platform"
  }

  assert {
    condition     = keys(google_storage_bucket.this) == ["curated", "raw"] && length(output.data_lake_bucket_names) == 2
    error_message = "data-platform adds the raw and curated buckets."
  }

  assert {
    condition     = length([for rule in google_storage_bucket.this["raw"].lifecycle_rule : rule if one(rule.action[*].type) == "SetStorageClass"]) == 2
    error_message = "The raw bucket must move objects to colder storage classes."
  }

  assert {
    condition     = length(google_artifact_registry_repository.containers) == 0 && output.storage_bucket_name == null
    error_message = "data-platform adds no registry and no assets bucket."
  }
}

run "type_ml_platform" {
  command = plan

  variables {
    infrastructure_type      = "ml-platform"
    enable_storage           = true
    enable_cost_optimization = true
  }

  assert {
    condition     = keys(google_storage_bucket.this) == ["assets", "curated", "raw"] && length(google_artifact_registry_repository.containers) == 1
    error_message = "ml-platform adds the data-lake buckets and a registry."
  }

  assert {
    condition     = length([for rule in google_storage_bucket.this["raw"].lifecycle_rule : rule if one(rule.action[*].type) == "SetStorageClass"]) == 3
    error_message = "Cost optimization adds an archive tier to the raw bucket."
  }

  assert {
    condition     = google_storage_bucket.this["assets"].autoclass[0].enabled && length(google_artifact_registry_repository.containers[0].cleanup_policies) == 2
    error_message = "Cost optimization turns on Autoclass and registry cleanup."
  }
}

run "type_container_platform" {
  command = plan

  variables {
    infrastructure_type = "container-platform"
    enable_kubernetes   = true
  }

  assert {
    condition     = google_artifact_registry_repository.containers[0].format == "DOCKER" && google_artifact_registry_repository.containers[0].repository_id == "acme-dev-containers"
    error_message = "container-platform adds a Docker registry."
  }

  assert {
    condition     = output.container_registry_url == "europe-west2-docker.pkg.dev/test-project/acme-dev-containers"
    error_message = "The registry URL must be returned."
  }

  assert {
    condition     = google_artifact_registry_repository_iam_member.gke_nodes[0].role == "roles/artifactregistry.reader"
    error_message = "The cluster nodes must be able to pull images."
  }
}

run "type_serverless_platform" {
  command = plan

  variables {
    infrastructure_type = "serverless-platform"
  }

  assert {
    condition     = length(google_artifact_registry_repository.containers) == 1 && length(google_storage_bucket.this) == 0
    error_message = "serverless-platform adds a registry only."
  }
}

run "type_networking_foundation" {
  command = plan

  variables {
    infrastructure_type = "networking-foundation"
  }

  assert {
    condition     = google_dns_managed_zone.private[0].visibility == "private" && google_dns_managed_zone.private[0].dns_name == "acme-dev.internal."
    error_message = "networking-foundation adds a private DNS zone."
  }

  assert {
    condition     = output.private_dns_zone_name == "acme-dev.internal"
    error_message = "The zone name must be returned without the trailing dot."
  }
}

# -----------------------------------------------------------------------------
# Security and operations
# -----------------------------------------------------------------------------

run "labels_from_tags" {
  command = plan

  variables {
    enable_storage = true
    tags = {
      "Cost Center" = "R&D/42"
      Description   = "It's the team's \"main\" service: handles 50% of #1 & more"
      "9lives"      = "Yes"
    }
  }

  assert {
    condition = google_storage_bucket.this["assets"].labels == tomap({
      "cost-center" = "r-d-42"
      description   = "it-s-the-team-s--main--service--handles-50--of--1---more"
      purpose       = "assets"
      "tag-9lives"  = "yes"
    })
    error_message = "Tags must be converted to valid labels."
  }
}

run "monitoring_and_alerting" {
  command = plan

  variables {
    enable_database   = true
    enable_storage    = true
    enable_monitoring = true
    enable_alerting   = true
    alert_email       = "alerts@example.com"
  }

  assert {
    condition     = google_logging_project_bucket_config.this[0].retention_days == 30 && google_logging_project_bucket_config.this[0].location == "europe-west2"
    error_message = "The log bucket must keep logs for log_retention_days."
  }

  assert {
    condition     = strcontains(google_logging_project_sink.this[0].filter, "cloudsql_database") && strcontains(google_logging_project_sink.this[0].filter, "gcs_bucket")
    error_message = "The sink must route the logs of the created components."
  }

  assert {
    condition     = length(google_monitoring_dashboard.this) == 1
    error_message = "A dashboard must be created."
  }

  assert {
    condition     = keys(google_monitoring_alert_policy.this) == ["database-cpu", "database-disk", "storage-errors"]
    error_message = "Alert policies must cover exactly the components that exist."
  }

  assert {
    condition     = length(google_pubsub_topic.alerts) == 1 && google_monitoring_notification_channel.pubsub[0].type == "pubsub"
    error_message = "Alerts must be published to a topic."
  }

  assert {
    condition     = google_monitoring_notification_channel.email[0].labels["email_address"] == "alerts@example.com"
    error_message = "alert_email must be subscribed."
  }

  assert {
    condition     = google_sql_database_instance.this[0].settings[0].insights_config[0].query_insights_enabled
    error_message = "Query insights must be on with monitoring."
  }
}

run "seven_year_log_retention" {
  command = plan

  variables {
    enable_monitoring  = true
    log_retention_days = 2557
  }

  assert {
    condition     = google_logging_project_bucket_config.this[0].retention_days == 2557
    error_message = "The log bucket must keep logs for the full 2557 days."
  }

  assert {
    condition     = length(google_logging_project_sink.this) == 1 && google_logging_project_sink.this[0].filter == "logName:\"cloudaudit.googleapis.com\" OR resource.type=(\"nat_gateway\" OR \"gce_subnetwork\")"
    error_message = "The audit logs and the logs of the created components must be routed to the log bucket."
  }
}

run "alerting_without_email" {
  command = plan

  variables {
    enable_alerting = true
  }

  assert {
    condition     = length(google_monitoring_notification_channel.pubsub) == 1 && length(google_monitoring_notification_channel.email) == 0
    error_message = "Without alert_email only the topic channel exists."
  }

  assert {
    condition     = length(google_monitoring_alert_policy.this) == 0 && length(google_logging_project_bucket_config.this) == 0
    error_message = "Without components there is nothing to alert on, and no log bucket without monitoring."
  }
}

run "disaster_recovery_needs_secondary_region" {
  command = plan

  variables {
    enable_disaster_recovery = true
  }

  expect_failures = [var.secondary_region]
}

run "everything_on_production" {
  command = plan

  variables {
    name_prefix                  = "acme-prod"
    environment                  = "production"
    secondary_region             = "europe-west1"
    infrastructure_type          = "ml-platform"
    allowed_ingress_cidrs        = ["203.0.113.0/24"]
    enable_security_group_rules  = true
    enable_kubernetes            = true
    kubernetes_api_allowed_cidrs = ["203.0.113.0/24"]
    node_size                    = "xlarge"
    min_nodes                    = 3
    max_nodes                    = 9
    enable_database              = true
    enable_storage               = true
    enable_cdn                   = true
    enable_waf                   = true
    enable_secrets_manager       = true
    enable_kms                   = true
    enable_backup                = true
    enable_monitoring            = true
    enable_managed_prometheus    = true
    enable_alerting              = true
    alert_email                  = "alerts@example.com"
    log_retention_days           = 365
    enable_disaster_recovery     = true
    enable_cost_optimization     = true
    require_deletion_protection  = true
    require_flow_logs            = true
  }

  assert {
    condition = (
      google_sql_database_instance.this[0].settings[0].availability_type == "REGIONAL" &&
      google_sql_database_instance.this[0].settings[0].tier == "db-custom-4-15360" &&
      google_sql_database_instance.this[0].deletion_protection &&
      google_sql_database_instance.this[0].settings[0].deletion_protection_enabled
    )
    error_message = "The production database must be regional, full-sized and protected against deletion."
  }

  assert {
    condition = (
      google_sql_database_instance.this[0].settings[0].backup_configuration[0].backup_retention_settings[0].retained_backups == 35 &&
      google_sql_database_instance.this[0].settings[0].backup_configuration[0].location == "europe-west1"
    )
    error_message = "With backups and disaster recovery 35 backups are kept in the secondary region."
  }

  assert {
    condition     = length(google_sql_database_instance.replica) == 1 && google_sql_database_instance.replica[0].region == "europe-west1"
    error_message = "Production disaster recovery adds a replica in the secondary region."
  }

  assert {
    condition     = keys(google_kms_crypto_key.this) == ["primary", "secondary"] && alltrue([for key in google_kms_crypto_key.this : key.rotation_period == "7776000s" && key.deletion_policy == "PREVENT"])
    error_message = "A rotated, protected key must exist in both regions."
  }

  assert {
    condition = keys(google_kms_crypto_key_iam_member.this) == [
      "primary-compute", "primary-gke", "primary-logging", "primary-registry", "primary-secrets", "primary-sql",
      "primary-sql-backup", "primary-storage", "secondary-gke-backup", "secondary-secrets", "secondary-sql",
      "secondary-storage",
    ]
    error_message = "Exactly the service agents of the created components may use the keys."
  }

  assert {
    condition = keys(google_project_service_identity.this) == [
      "artifactregistry.googleapis.com", "backupdr.googleapis.com", "gkebackup.googleapis.com",
      "secretmanager.googleapis.com", "sqladmin.googleapis.com",
    ]
    error_message = "The on-demand service agents of the encrypted services must be created."
  }

  assert {
    condition     = alltrue([for bucket in google_storage_bucket.this : length(bucket.encryption) == 1 && bucket.force_destroy == false])
    error_message = "Buckets must use the customer-managed key and survive a destroy while they hold data."
  }

  assert {
    condition     = keys(google_storage_bucket.replica) == ["assets", "curated", "raw"] && keys(google_storage_transfer_job.replication) == ["assets", "curated", "raw"]
    error_message = "Every bucket must be replicated to the secondary region."
  }

  assert {
    condition     = alltrue([for bucket in google_storage_bucket.replica : bucket.location == "europe-west1" && bucket.public_access_prevention == "enforced"])
    error_message = "Replica buckets must be private and in the secondary region."
  }

  assert {
    condition = (
      google_container_cluster.this[0].deletion_protection &&
      google_container_cluster.this[0].database_encryption[0].state == "ENCRYPTED" &&
      google_container_cluster.this[0].node_pool[0].node_config[0].spot == false &&
      google_container_cluster.this[0].node_pool[0].node_config[0].machine_type == "e2-custom-16-32768" &&
      one(google_container_cluster.this[0].addons_config[0].gke_backup_agent_config[*].enabled)
    )
    error_message = "The production cluster must be protected, encrypt secrets, back up and use on-demand nodes."
  }

  assert {
    condition = (
      google_backup_dr_backup_vault.this[0].backup_minimum_enforced_retention_duration == "604800s" &&
      google_backup_dr_backup_plan.database[0].resource_type == "sqladmin.googleapis.com/Instance" &&
      google_backup_dr_backup_plan.database[0].backup_rules[0].backup_retention_days == 35 &&
      length(google_backup_dr_backup_plan_association.database) == 1
    )
    error_message = "A vault with a 35-day plan must cover the database."
  }

  assert {
    condition     = google_gke_backup_backup_plan.this[0].location == "europe-west1" && google_gke_backup_backup_plan.this[0].retention_policy[0].backup_retain_days == 35
    error_message = "Cluster backups must be kept for 35 days in the secondary region."
  }

  assert {
    condition = (
      [for replica in google_secret_manager_secret.database[0].replication[0].user_managed[0].replicas : replica.location] == ["europe-west2", "europe-west1"] &&
      google_secret_manager_secret.database[0].deletion_protection &&
      nonsensitive(output.database_password == null)
    )
    error_message = "The credentials must be stored in Secret Manager in both regions and not returned."
  }

  assert {
    condition     = google_logging_project_bucket_config.this[0].retention_days == 365 && length(google_logging_project_bucket_config.this[0].cmek_settings) == 1
    error_message = "The log bucket must keep logs for a year and use the customer-managed key."
  }

  assert {
    condition = keys(google_monitoring_alert_policy.this) == [
      "cdn-errors", "cluster-node-cpu", "cluster-restarts", "database-cpu", "database-disk", "storage-errors", "waf-blocked",
    ]
    error_message = "Alert policies must cover the database, cluster, CDN, WAF and storage."
  }

  assert {
    condition     = google_artifact_registry_repository.containers[0].docker_config[0].immutable_tags
    error_message = "Image tags must be immutable in production."
  }

  assert {
    condition = toset(keys(google_project_service.this)) == toset([
      "artifactregistry.googleapis.com", "backupdr.googleapis.com", "cloudkms.googleapis.com",
      "cloudresourcemanager.googleapis.com", "compute.googleapis.com", "container.googleapis.com",
      "gkebackup.googleapis.com", "iam.googleapis.com", "logging.googleapis.com", "monitoring.googleapis.com",
      "pubsub.googleapis.com", "secretmanager.googleapis.com", "servicenetworking.googleapis.com",
      "sqladmin.googleapis.com", "storage.googleapis.com", "storagetransfer.googleapis.com",
    ])
    error_message = "Exactly the APIs of the enabled features must be switched on."
  }
}

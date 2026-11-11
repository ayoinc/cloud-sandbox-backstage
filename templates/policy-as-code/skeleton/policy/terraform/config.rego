# Settings of the policies. Change the values here; the rules read them.
package terraform.config

# Tags (AWS, Azure) or labels (Google Cloud) every taggable resource must carry.
required_tags := {"owner", "environment"}

# Resource types that a plan must not delete or replace. Removing one takes a
# deliberate step: an entry in `deletion_exemptions`, reviewed like any change.
protected_types := {
	"aws_db_instance",
	"aws_dynamodb_table",
	"aws_kms_key",
	"aws_rds_cluster",
	"aws_s3_bucket",
	"azurerm_key_vault",
	"azurerm_mssql_database",
	"azurerm_postgresql_flexible_server",
	"azurerm_storage_account",
	"google_kms_crypto_key",
	"google_sql_database_instance",
	"google_storage_bucket",
}

# Addresses that may be deleted although their type is protected.
deletion_exemptions := set()

# Registry namespaces providers may come from.
allowed_provider_namespaces := {"hashicorp", "opentofu", "integrations", "cloudflare", "datadog"}

# Ports that must not be reachable from the whole internet.
admin_ports := {22, 3389}

# Address ranges that mean "the whole internet".
public_ranges := {"0.0.0.0/0", "::/0", "*", "Internet"}

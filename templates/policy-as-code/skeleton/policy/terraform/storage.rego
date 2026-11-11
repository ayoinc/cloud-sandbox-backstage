# Object storage is private and reached over current TLS.
package terraform.storage

import data.terraform.lib.plan

deny contains msg if {
	some rc in plan.planned({"aws_s3_bucket_public_access_block"})
	some setting in ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]
	not rc.change.after[setting] == true
	msg := sprintf("%s: %s must be true", [rc.address, setting])
}

deny contains msg if {
	some rc in plan.planned({"aws_s3_bucket_acl", "aws_s3_bucket"})
	rc.change.after.acl in {"public-read", "public-read-write", "authenticated-read"}
	msg := sprintf("%s: the %q ACL makes the bucket public", [rc.address, rc.change.after.acl])
}

deny contains msg if {
	some rc in plan.planned({"azurerm_storage_account"})
	rc.change.after.allow_nested_items_to_be_public == true
	msg := sprintf("%s: allow_nested_items_to_be_public must be false", [rc.address])
}

deny contains msg if {
	some rc in plan.planned({"azurerm_storage_account"})
	not rc.change.after.min_tls_version in {"TLS1_2", "TLS1_3"}
	msg := sprintf("%s: min_tls_version must be TLS1_2 or later", [rc.address])
}

deny contains msg if {
	some rc in plan.planned({"azurerm_storage_container"})
	rc.change.after.container_access_type in {"blob", "container"}
	msg := sprintf("%s: container_access_type must be private", [rc.address])
}

deny contains msg if {
	some rc in plan.planned({"google_storage_bucket"})
	not rc.change.after.public_access_prevention == "enforced"
	msg := sprintf("%s: public_access_prevention must be enforced", [rc.address])
}

deny contains msg if {
	some rc in plan.planned({"google_storage_bucket"})
	not rc.change.after.uniform_bucket_level_access == true
	msg := sprintf("%s: uniform_bucket_level_access must be true", [rc.address])
}

deny contains msg if {
	some rc in plan.planned({"google_storage_bucket_iam_member", "google_storage_bucket_iam_binding"})
	some member in members(rc.change.after)
	member in {"allUsers", "allAuthenticatedUsers"}
	msg := sprintf("%s: %s must not be granted access to a bucket", [rc.address, member])
}

members(after) := {after.member} if {
	is_string(after.member)
} else := {member | some member in after.members}

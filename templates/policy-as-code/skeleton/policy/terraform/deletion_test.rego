package terraform.deletion_test

import data.terraform.deletion

change(address, type, actions) := {
	"address": address,
	"mode": "managed",
	"type": type,
	"change": {"actions": actions, "after": null},
}

test_deleting_a_protected_resource_is_denied if {
	result := deletion.deny with input as {"resource_changes": [change("aws_db_instance.main", "aws_db_instance", ["delete"])]}
	count(result) == 1
	some msg in result
	contains(msg, "would delete a protected aws_db_instance")
}

test_replacing_a_protected_resource_is_denied if {
	result := deletion.deny with input as {"resource_changes": [change("aws_kms_key.main", "aws_kms_key", ["delete", "create"])]}
	some msg in result
	contains(msg, "would replace a protected aws_kms_key")
}

test_create_before_destroy_replacement_is_denied if {
	count(deletion.deny) == 1 with input as {"resource_changes": [change("google_storage_bucket.logs", "google_storage_bucket", ["create", "delete"])]}
}

test_updating_a_protected_resource_passes if {
	count(deletion.deny) == 0 with input as {"resource_changes": [change("aws_db_instance.main", "aws_db_instance", ["update"])]}
}

test_exempted_address_passes if {
	count(deletion.deny) == 0 with input as {"resource_changes": [change("aws_db_instance.old", "aws_db_instance", ["delete"])]}
		with data.terraform.config.deletion_exemptions as {"aws_db_instance.old"}
}

test_deleting_anything_else_warns if {
	plan := {"resource_changes": [change("aws_iam_role.app", "aws_iam_role", ["delete"])]}
	count(deletion.deny) == 0 with input as plan
	deletion.warn == {"aws_iam_role.app: the plan would delete this resource"} with input as plan
}

test_data_sources_are_ignored if {
	count(deletion.warn) == 0 with input as {"resource_changes": [{
		"address": "data.aws_ami.base",
		"mode": "data",
		"type": "aws_ami",
		"change": {"actions": ["delete"], "after": null},
	}]}
}

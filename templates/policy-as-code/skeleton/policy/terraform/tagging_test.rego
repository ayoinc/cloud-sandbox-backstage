package terraform.tagging_test

import data.terraform.tagging

plan_with(resource) := {"resource_changes": [resource]}

bucket(after) := {
	"address": "aws_s3_bucket.logs",
	"mode": "managed",
	"type": "aws_s3_bucket",
	"change": {"actions": ["create"], "after": after},
}

test_tagged_resource_passes if {
	count(tagging.deny) == 0 with input as plan_with(bucket({"tags": {"owner": "platform", "environment": "dev"}}))
}

test_missing_tag_is_denied if {
	tagging.deny == {"aws_s3_bucket.logs: missing required tag \"environment\""} with input as plan_with(bucket({"tags": {"owner": "platform"}}))
}

test_null_tags_are_denied if {
	count(tagging.deny) == 2 with input as plan_with(bucket({"tags": null}))
}

test_empty_value_is_denied if {
	count(tagging.deny) == 1 with input as plan_with(bucket({"tags": {"owner": " ", "environment": "dev"}}))
}

test_provider_default_tags_count if {
	count(tagging.deny) == 0 with input as plan_with(bucket({
		"tags": null,
		"tags_all": {"owner": "platform", "environment": "dev"},
	}))
}

test_labels_are_checked if {
	count(tagging.deny) == 1 with input as plan_with({
		"address": "google_storage_bucket.logs",
		"mode": "managed",
		"type": "google_storage_bucket",
		"change": {"actions": ["update"], "after": {"labels": {"owner": "platform"}}},
	})
}

test_untaggable_resource_is_ignored if {
	count(tagging.deny) == 0 with input as plan_with({
		"address": "aws_s3_bucket_versioning.logs",
		"mode": "managed",
		"type": "aws_s3_bucket_versioning",
		"change": {"actions": ["create"], "after": {"bucket": "logs"}},
	})
}

test_deleted_resource_is_ignored if {
	count(tagging.deny) == 0 with input as plan_with({
		"address": "aws_s3_bucket.old",
		"mode": "managed",
		"type": "aws_s3_bucket",
		"change": {"actions": ["delete"], "after": null},
	})
}

test_required_tags_are_configurable if {
	tagging.deny == {"aws_s3_bucket.logs: missing required tag \"cost-centre\""} with input as plan_with(bucket({"tags": {"owner": "platform"}}))
		with data.terraform.config.required_tags as {"cost-centre"}
}

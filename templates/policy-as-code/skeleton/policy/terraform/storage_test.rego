package terraform.storage_test

import data.terraform.storage

resource(type, after) := {"resource_changes": [{
	"address": sprintf("%s.this", [type]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}]}

test_s3_public_access_block_must_block_everything if {
	storage.deny == {"aws_s3_bucket_public_access_block.this: restrict_public_buckets must be true"} with input as resource("aws_s3_bucket_public_access_block", {
		"block_public_acls": true,
		"block_public_policy": true,
		"ignore_public_acls": true,
		"restrict_public_buckets": false,
	})
}

test_s3_full_public_access_block_passes if {
	count(storage.deny) == 0 with input as resource("aws_s3_bucket_public_access_block", {
		"block_public_acls": true,
		"block_public_policy": true,
		"ignore_public_acls": true,
		"restrict_public_buckets": true,
	})
}

test_s3_public_acl_is_denied if {
	count(storage.deny) == 1 with input as resource("aws_s3_bucket_acl", {"acl": "public-read"})
}

test_s3_private_acl_passes if {
	count(storage.deny) == 0 with input as resource("aws_s3_bucket_acl", {"acl": "private"})
}

test_azure_public_blobs_and_old_tls_are_denied if {
	count(storage.deny) == 2 with input as resource("azurerm_storage_account", {
		"allow_nested_items_to_be_public": true,
		"min_tls_version": "TLS1_0",
	})
}

test_azure_private_account_passes if {
	count(storage.deny) == 0 with input as resource("azurerm_storage_account", {
		"allow_nested_items_to_be_public": false,
		"min_tls_version": "TLS1_2",
	})
}

test_azure_public_container_is_denied if {
	count(storage.deny) == 1 with input as resource("azurerm_storage_container", {"container_access_type": "blob"})
}

test_gcp_bucket_must_prevent_public_access if {
	count(storage.deny) == 2 with input as resource("google_storage_bucket", {
		"public_access_prevention": "inherited",
		"uniform_bucket_level_access": false,
	})
}

test_gcp_private_bucket_passes if {
	count(storage.deny) == 0 with input as resource("google_storage_bucket", {
		"public_access_prevention": "enforced",
		"uniform_bucket_level_access": true,
	})
}

test_gcp_all_users_binding_is_denied if {
	storage.deny == {"google_storage_bucket_iam_binding.this: allUsers must not be granted access to a bucket"} with input as resource("google_storage_bucket_iam_binding", {
		"role": "roles/storage.objectViewer",
		"members": ["allUsers", "group:data@sample.internal"],
	})
}

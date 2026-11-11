package terraform.providers_test

import data.terraform.providers

plan_with(provider_config) := {"configuration": {"provider_config": provider_config}}

test_pinned_approved_provider_passes if {
	count(providers.deny) == 0 with input as plan_with({"aws": {
		"name": "aws",
		"full_name": "registry.terraform.io/hashicorp/aws",
		"version_constraint": "~> 6.0",
	}})
}

test_opentofu_registry_passes if {
	count(providers.deny) == 0 with input as plan_with({"google": {
		"name": "google",
		"full_name": "registry.opentofu.org/hashicorp/google",
		"version_constraint": ">= 8.0",
	}})
}

test_unapproved_namespace_is_denied if {
	result := providers.deny with input as plan_with({"things": {
		"name": "things",
		"full_name": "registry.terraform.io/somebody/things",
		"version_constraint": "1.0.0",
	}})
	count(result) == 1
	some msg in result
	contains(msg, "comes from \"registry.terraform.io/somebody/things\"")
}

test_unpinned_provider_is_denied if {
	providers.deny == {"provider \"aws\" has no version constraint in required_providers"} with input as plan_with({"aws": {
		"name": "aws",
		"full_name": "registry.terraform.io/hashicorp/aws",
	}})
}

test_provider_of_a_child_module_needs_no_constraint if {
	count(providers.deny) == 0 with input as plan_with({"module.network:aws": {
		"name": "aws",
		"full_name": "registry.terraform.io/hashicorp/aws",
		"module_address": "module.network",
	}})
}

test_namespaces_are_configurable if {
	count(providers.deny) == 0 with input as plan_with({"things": {
		"name": "things",
		"full_name": "registry.terraform.io/somebody/things",
		"version_constraint": "1.0.0",
	}})
		with data.terraform.config.allowed_provider_namespaces as {"somebody"}
}

test_plan_without_configuration_passes if {
	count(providers.deny) == 0 with input as {"resource_changes": []}
}

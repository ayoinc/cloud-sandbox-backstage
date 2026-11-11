# Providers come from an approved source and are pinned.
package terraform.providers

import data.terraform.config

providers contains provider if {
	some provider in object.get(input, ["configuration", "provider_config"], {})
}

deny contains msg if {
	some provider in providers
	source := object.get(provider, "full_name", provider.name)
	not namespace(source) in config.allowed_provider_namespaces
	msg := sprintf(
		"provider %q comes from %q; allowed namespaces are %s",
		[provider.name, source, concat(", ", sort(config.allowed_provider_namespaces))],
	)
}

# Only the root module is asked for a constraint: child modules inherit it.
deny contains msg if {
	some provider in providers
	not provider.module_address
	trim_space(object.get(provider, "version_constraint", "")) == ""
	msg := sprintf("provider %q has no version constraint in required_providers", [provider.name])
}

# registry.terraform.io/hashicorp/aws -> hashicorp
namespace(source) := parts[count(parts) - 2] if {
	parts := split(source, "/")
	count(parts) >= 2
} else := "hashicorp"

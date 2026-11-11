# Administrative ports are not open to the whole internet.
package terraform.network

import data.terraform.config
import data.terraform.lib.plan

deny contains msg if {
	some rc in plan.created_or_updated
	some port in config.admin_ports
	exposes(rc, port)
	msg := sprintf("%s: port %d is reachable from the internet", [rc.address, port])
}

# AWS: rules written inline in a security group.
exposes(rc, port) if {
	rc.type == "aws_security_group"
	some rule in rc.change.after.ingress
	aws_rule_is_public(rule)
	aws_rule_covers(rule, port)
}

# AWS: standalone rules, old style.
exposes(rc, port) if {
	rc.type == "aws_security_group_rule"
	rc.change.after.type == "ingress"
	aws_rule_is_public(rc.change.after)
	aws_rule_covers(rc.change.after, port)
}

# AWS: standalone rules, one address range per rule.
exposes(rc, port) if {
	rc.type == "aws_vpc_security_group_ingress_rule"
	some field in ["cidr_ipv4", "cidr_ipv6"]
	rc.change.after[field] in config.public_ranges
	aws_rule_covers(
		{
			"protocol": rc.change.after.ip_protocol,
			"from_port": rc.change.after.from_port,
			"to_port": rc.change.after.to_port,
		},
		port,
	)
}

aws_rule_is_public(rule) if {
	some field in ["cidr_blocks", "ipv6_cidr_blocks"]
	some range in rule[field]
	range in config.public_ranges
}

aws_rule_covers(rule, _) if rule.protocol in {"-1", "all"}

aws_rule_covers(rule, port) if plan.port_in_range(port, rule.from_port, rule.to_port)

# Azure: network security rules.
exposes(rc, port) if {
	rc.type == "azurerm_network_security_rule"
	rule := rc.change.after
	lower(rule.direction) == "inbound"
	lower(rule.access) == "allow"
	azure_rule_is_public(rule)
	some spec in azure_port_specs(rule)
	plan.spec_covers_port(spec, port)
}

azure_rule_is_public(rule) if rule.source_address_prefix in config.public_ranges

azure_rule_is_public(rule) if {
	some prefix in rule.source_address_prefixes
	prefix in config.public_ranges
}

azure_port_specs(rule) := specs if {
	single := {rule.destination_port_range | is_string(rule.destination_port_range)}
	many := {spec | some spec in rule.destination_port_ranges}
	specs := single | many
}

# Google Cloud: firewall rules. A rule without a direction is an ingress rule;
# an allow block without ports allows every port.
exposes(rc, port) if {
	rc.type == "google_compute_firewall"
	rule := rc.change.after
	object.get(rule, "direction", "INGRESS") in {"INGRESS", null}
	not object.get(rule, "disabled", false) == true
	some range in rule.source_ranges
	range in config.public_ranges
	some allow in rule.allow
	gcp_allow_covers(allow, port)
}

gcp_allow_covers(allow, _) if count(object.get(allow, "ports", [])) == 0

gcp_allow_covers(allow, port) if {
	some spec in allow.ports
	plan.spec_covers_port(spec, port)
}

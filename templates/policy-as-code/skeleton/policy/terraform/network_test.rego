package terraform.network_test

import data.terraform.network

resource(type, after) := {"resource_changes": [{
	"address": sprintf("%s.this", [type]),
	"mode": "managed",
	"type": type,
	"change": {"actions": ["create"], "after": after},
}]}

test_aws_inline_ssh_from_anywhere_is_denied if {
	network.deny == {"aws_security_group.this: port 22 is reachable from the internet"} with input as resource("aws_security_group", {"ingress": [{
		"protocol": "tcp",
		"from_port": 22,
		"to_port": 22,
		"cidr_blocks": ["0.0.0.0/0"],
		"ipv6_cidr_blocks": [],
	}]})
}

test_aws_all_protocols_from_anywhere_is_denied if {
	count(network.deny) == 2 with input as resource("aws_security_group_rule", {
		"type": "ingress",
		"protocol": "-1",
		"from_port": 0,
		"to_port": 0,
		"cidr_blocks": ["0.0.0.0/0"],
	})
}

test_aws_https_from_anywhere_passes if {
	count(network.deny) == 0 with input as resource("aws_vpc_security_group_ingress_rule", {
		"ip_protocol": "tcp",
		"from_port": 443,
		"to_port": 443,
		"cidr_ipv4": "0.0.0.0/0",
	})
}

test_aws_port_range_over_rdp_is_denied if {
	network.deny == {"aws_vpc_security_group_ingress_rule.this: port 3389 is reachable from the internet"} with input as resource("aws_vpc_security_group_ingress_rule", {
		"ip_protocol": "tcp",
		"from_port": 3000,
		"to_port": 4000,
		"cidr_ipv6": "::/0",
	})
}

test_aws_ssh_from_a_private_range_passes if {
	count(network.deny) == 0 with input as resource("aws_security_group_rule", {
		"type": "ingress",
		"protocol": "tcp",
		"from_port": 22,
		"to_port": 22,
		"cidr_blocks": ["10.0.0.0/8"],
	})
}

test_aws_egress_is_ignored if {
	count(network.deny) == 0 with input as resource("aws_security_group_rule", {
		"type": "egress",
		"protocol": "-1",
		"from_port": 0,
		"to_port": 0,
		"cidr_blocks": ["0.0.0.0/0"],
	})
}

test_azure_ssh_from_internet_is_denied if {
	network.deny == {"azurerm_network_security_rule.this: port 22 is reachable from the internet"} with input as resource("azurerm_network_security_rule", {
		"direction": "Inbound",
		"access": "Allow",
		"source_address_prefix": "Internet",
		"destination_port_range": "22",
	})
}

test_azure_port_ranges_are_checked if {
	count(network.deny) == 1 with input as resource("azurerm_network_security_rule", {
		"direction": "Inbound",
		"access": "Allow",
		"source_address_prefix": "*",
		"destination_port_range": null,
		"destination_port_ranges": ["443", "3380-3390"],
	})
}

test_azure_deny_rule_passes if {
	count(network.deny) == 0 with input as resource("azurerm_network_security_rule", {
		"direction": "Inbound",
		"access": "Deny",
		"source_address_prefix": "*",
		"destination_port_range": "*",
	})
}

test_gcp_firewall_without_ports_is_denied if {
	count(network.deny) == 2 with input as resource("google_compute_firewall", {
		"direction": "INGRESS",
		"source_ranges": ["0.0.0.0/0"],
		"allow": [{"protocol": "tcp", "ports": []}],
	})
}

test_gcp_ssh_from_iap_passes if {
	count(network.deny) == 0 with input as resource("google_compute_firewall", {
		"direction": "INGRESS",
		"source_ranges": ["35.235.240.0/20"],
		"allow": [{"protocol": "tcp", "ports": ["22"]}],
	})
}

test_gcp_egress_is_ignored if {
	count(network.deny) == 0 with input as resource("google_compute_firewall", {
		"direction": "EGRESS",
		"source_ranges": ["0.0.0.0/0"],
		"allow": [{"protocol": "all", "ports": []}],
	})
}

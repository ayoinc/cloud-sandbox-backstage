# Helpers for reading a plan in the JSON format of `terraform show -json`.
package terraform.lib.plan

# Managed resources the plan touches.
resource_changes contains rc if {
	some rc in input.resource_changes
	rc.mode == "managed"
}

# Resources that exist after the plan is applied and are changed by it.
created_or_updated contains rc if {
	some rc in resource_changes
	some action in rc.change.actions
	action in {"create", "update"}
}

# Resources the plan deletes; a replacement deletes too.
deleted contains rc if {
	some rc in resource_changes
	"delete" in rc.change.actions
}

# Resources of the given types that exist after the plan is applied.
planned(types) := {rc |
	some rc in created_or_updated
	rc.type in types
}

# The tags or labels a resource will have, or undefined if it cannot be tagged.
# AWS reports provider default tags in tags_all and Google Cloud reports
# provider default labels in effective_labels.
tags(rc) := rc.change.after.tags_all if {
	is_object(rc.change.after.tags_all)
} else := object_or_empty(rc.change.after.tags) if {
	"tags" in object.keys(rc.change.after)
} else := rc.change.after.effective_labels if {
	is_object(rc.change.after.effective_labels)
} else := object_or_empty(rc.change.after.labels) if {
	"labels" in object.keys(rc.change.after)
}

object_or_empty(value) := value if {
	is_object(value)
} else := {}

# Whether a port lies in an inclusive range.
port_in_range(port, from, to) if {
	from <= port
	port <= to
}

# Whether a port specification such as "22", "20-25" or "*" covers a port.
spec_covers_port(spec, _) if spec == "*"

spec_covers_port(spec, port) if to_number(spec) == port

spec_covers_port(spec, port) if {
	bounds := split(spec, "-")
	count(bounds) == 2
	port_in_range(port, to_number(bounds[0]), to_number(bounds[1]))
}

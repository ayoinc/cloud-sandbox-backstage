# Stateful resources are not deleted or replaced by accident.
package terraform.deletion

import data.terraform.config
import data.terraform.lib.plan

deny contains msg if {
	some rc in plan.deleted
	rc.type in config.protected_types
	not rc.address in config.deletion_exemptions
	msg := sprintf(
		"%s: the plan would %s a protected %s; add the address to deletion_exemptions if this is intended",
		[rc.address, verb(rc), rc.type],
	)
}

# Deletions of anything else are worth a second look.
warn contains msg if {
	some rc in plan.deleted
	not rc.type in config.protected_types
	msg := sprintf("%s: the plan would %s this resource", [rc.address, verb(rc)])
}

verb(rc) := "replace" if {
	"create" in rc.change.actions
} else := "delete"

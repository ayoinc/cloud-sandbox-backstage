# Every taggable resource carries the required tags.
package terraform.tagging

import data.terraform.config
import data.terraform.lib.plan

deny contains msg if {
	some rc in plan.created_or_updated
	tags := plan.tags(rc)
	some required in config.required_tags
	not has_value(tags, required)
	msg := sprintf("%s: missing required tag %q", [rc.address, required])
}

has_value(tags, key) if {
	value := tags[key]
	is_string(value)
	trim_space(value) != ""
}

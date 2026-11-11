# Rules every workload of this repository has to meet. They are checked by
# scripts/check-policies.sh in the pipeline.
package main

import rego.v1

workload_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Rollout"}

is_workload if input.kind in workload_kinds

pod_spec := input.spec.template.spec if is_workload

containers contains container if {
	some container in pod_spec.containers
}

containers contains container if {
	some container in pod_spec.initContainers
}

deny contains msg if {
	is_workload
	not pod_spec.securityContext.runAsNonRoot
	msg := sprintf("%s %s: pods must set securityContext.runAsNonRoot", [input.kind, input.metadata.name])
}

deny contains msg if {
	some container in containers
	container.securityContext.privileged
	msg := sprintf("%s %s: container %s must not be privileged", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
	some container in containers
	object.get(container, ["securityContext", "allowPrivilegeEscalation"], true)
	msg := sprintf("%s %s: container %s must set allowPrivilegeEscalation to false", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
	some container in containers
	not container.securityContext.readOnlyRootFilesystem
	msg := sprintf("%s %s: container %s must use a read-only root filesystem", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
	some container in containers
	not "ALL" in object.get(container, ["securityContext", "capabilities", "drop"], [])
	msg := sprintf("%s %s: container %s must drop all capabilities", [input.kind, input.metadata.name, container.name])
}

deny contains msg if {
	some container in containers
	some resource in ["cpu", "memory"]
	not container.resources.limits[resource]
	msg := sprintf("%s %s: container %s must set a %s limit", [input.kind, input.metadata.name, container.name, resource])
}

deny contains msg if {
	some container in containers
	some resource in ["cpu", "memory"]
	not container.resources.requests[resource]
	msg := sprintf("%s %s: container %s must set a %s request", [input.kind, input.metadata.name, container.name, resource])
}

deny contains msg if {
	some container in pod_spec.containers
	some probe in ["livenessProbe", "readinessProbe"]
	not container[probe]
	msg := sprintf("%s %s: container %s must define a %s", [input.kind, input.metadata.name, container.name, probe])
}

deny contains msg if {
	is_workload
	pod_spec.hostNetwork
	msg := sprintf("%s %s: pods must not use the host network", [input.kind, input.metadata.name])
}

deny contains msg if {
	input.kind == "Service"
	input.spec.type == "LoadBalancer"
	msg := sprintf("Service %s: publish the service through the Ingress, not a LoadBalancer", [input.metadata.name])
}

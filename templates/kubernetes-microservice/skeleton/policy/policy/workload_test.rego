package main

import rego.v1

compliant := {
	"kind": "Deployment",
	"metadata": {"name": "example"},
	"spec": {"template": {"spec": {
		"securityContext": {"runAsNonRoot": true},
		"containers": [{
			"name": "app",
			"securityContext": {
				"allowPrivilegeEscalation": false,
				"readOnlyRootFilesystem": true,
				"capabilities": {"drop": ["ALL"]},
			},
			"resources": {
				"requests": {"cpu": "100m", "memory": "128Mi"},
				"limits": {"cpu": "500m", "memory": "512Mi"},
			},
			"livenessProbe": {"httpGet": {"path": "/health", "port": "http"}},
			"readinessProbe": {"httpGet": {"path": "/ready", "port": "http"}},
		}],
	}}},
}

test_compliant_deployment_is_allowed if {
	count(deny) == 0 with input as compliant
}

test_rollouts_are_checked_like_deployments if {
	rollout := json.patch(compliant, [
		{"op": "replace", "path": "/kind", "value": "Rollout"},
		{"op": "remove", "path": "/spec/template/spec/securityContext"},
	])
	"Rollout example: pods must set securityContext.runAsNonRoot" in deny with input as rollout
}

test_privilege_escalation_is_denied if {
	workload := json.patch(compliant, [{"op": "remove", "path": "/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation"}])
	"Deployment example: container app must set allowPrivilegeEscalation to false" in deny with input as workload
}

test_writable_root_filesystem_is_denied if {
	workload := json.patch(compliant, [{"op": "replace", "path": "/spec/template/spec/containers/0/securityContext/readOnlyRootFilesystem", "value": false}])
	"Deployment example: container app must use a read-only root filesystem" in deny with input as workload
}

test_missing_limits_are_denied if {
	workload := json.patch(compliant, [{"op": "remove", "path": "/spec/template/spec/containers/0/resources/limits/memory"}])
	"Deployment example: container app must set a memory limit" in deny with input as workload
}

test_missing_probes_are_denied if {
	workload := json.patch(compliant, [{"op": "remove", "path": "/spec/template/spec/containers/0/readinessProbe"}])
	"Deployment example: container app must define a readinessProbe" in deny with input as workload
}

test_load_balancer_services_are_denied if {
	service := {"kind": "Service", "metadata": {"name": "example"}, "spec": {"type": "LoadBalancer"}}
	"Service example: publish the service through the Ingress, not a LoadBalancer" in deny with input as service
}

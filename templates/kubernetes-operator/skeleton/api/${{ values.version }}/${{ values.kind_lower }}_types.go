package ${{ values.version }}

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

// Condition types reported in the status of a ${{ values.kind }}.
const (
	// ConditionAvailable is True when every desired replica is ready.
	ConditionAvailable = "Available"
	// ConditionProgressing is True while the workload is rolling out.
	ConditionProgressing = "Progressing"
	// ConditionDegraded is True when the workload could not be reconciled.
	ConditionDegraded = "Degraded"
)

// ${{ values.kind }}Spec defines the desired state of ${{ values.kind }}.
type ${{ values.kind }}Spec struct {
	// image is the container image the workload runs.
	// +kubebuilder:validation:MinLength=1
	// +required
	Image string `json:"image"`

	// replicas is the number of pods to run.
	// +kubebuilder:validation:Minimum=0
	// +kubebuilder:validation:Maximum=50
	// +kubebuilder:default=1
	// +optional
	Replicas *int32 `json:"replicas,omitempty"`

	// port is the TCP port the container listens on. When set, the port is
	// declared on the container and a ClusterIP Service is created for it.
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=65535
	// +optional
	Port *int32 `json:"port,omitempty"`

	// resources are the compute resources of the container.
	// +optional
	Resources corev1.ResourceRequirements `json:"resources,omitempty"`
}

// ${{ values.kind }}Status defines the observed state of ${{ values.kind }}.
type ${{ values.kind }}Status struct {
	// observedGeneration is the generation of the spec the status describes.
	// +optional
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`

	// readyReplicas is the number of pods that are ready.
	// +optional
	ReadyReplicas int32 `json:"readyReplicas,omitempty"`

	// conditions represent the current state of the ${{ values.kind }} resource.
	//
	// Condition types:
	// - "Available": every desired replica is ready
	// - "Progressing": the workload is being created or updated
	// - "Degraded": the workload could not be reconciled
	//
	// +listType=map
	// +listMapKey=type
	// +optional
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=${{ values.plural }},singular=${{ values.kind_lower }}
// +kubebuilder:printcolumn:name="Image",type=string,JSONPath=`.spec.image`
// +kubebuilder:printcolumn:name="Desired",type=integer,JSONPath=`.spec.replicas`
// +kubebuilder:printcolumn:name="Ready",type=integer,JSONPath=`.status.readyReplicas`
// +kubebuilder:printcolumn:name="Available",type=string,JSONPath=`.status.conditions[?(@.type=="Available")].status`
// +kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`

// ${{ values.kind }} is the Schema for the ${{ values.plural }} API.
type ${{ values.kind }} struct {
	metav1.TypeMeta `json:",inline"`

	// metadata is a standard object metadata
	// +optional
	metav1.ObjectMeta `json:"metadata,omitzero"`

	// spec defines the desired state of ${{ values.kind }}
	// +required
	Spec ${{ values.kind }}Spec `json:"spec"`

	// status defines the observed state of ${{ values.kind }}
	// +optional
	Status ${{ values.kind }}Status `json:"status,omitzero"`
}

// +kubebuilder:object:root=true

// ${{ values.kind }}List contains a list of ${{ values.kind }}.
type ${{ values.kind }}List struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitzero"`
	Items           []${{ values.kind }} `json:"items"`
}

func init() {
	SchemeBuilder.Register(func(s *runtime.Scheme) error {
		s.AddKnownTypes(SchemeGroupVersion, &${{ values.kind }}{}, &${{ values.kind }}List{})
		return nil
	})
}

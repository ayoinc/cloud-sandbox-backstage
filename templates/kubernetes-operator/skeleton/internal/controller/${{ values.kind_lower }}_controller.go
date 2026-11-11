package controller

import (
	"context"
	"fmt"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/client-go/tools/events"
	"k8s.io/utils/ptr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	logf "sigs.k8s.io/controller-runtime/pkg/log"

	${{ values.group }}${{ values.version }} "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/api/${{ values.version }}"
)

const (
	containerName = "workload"
	portName      = "main"
	managedBy     = "${{ values.name }}"
)

// ${{ values.kind }}Reconciler reconciles a ${{ values.kind }} object
type ${{ values.kind }}Reconciler struct {
	client.Client
	Scheme   *runtime.Scheme
	Recorder events.EventRecorder
}

// +kubebuilder:rbac:groups=${{ values.group }}.${{ values.domain }},resources=${{ values.plural }},verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=${{ values.group }}.${{ values.domain }},resources=${{ values.plural }}/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=${{ values.group }}.${{ values.domain }},resources=${{ values.plural }}/finalizers,verbs=update
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=events.k8s.io,resources=events,verbs=create;patch

// Reconcile moves the cluster towards the state a ${{ values.kind }} describes: a
// Deployment running spec.image with spec.replicas pods and, when spec.port is
// set, a ClusterIP Service in front of it. Both are owned by the ${{ values.kind }}, so
// deleting it removes them through garbage collection. The outcome is reported
// in the status conditions.
func (r *${{ values.kind }}Reconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := logf.FromContext(ctx)

	obj := &${{ values.group }}${{ values.version }}.${{ values.kind }}{}
	if err := r.Get(ctx, req.NamespacedName, obj); err != nil {
		// The object is gone; its Deployment and Service follow through their owner reference.
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
	if !obj.DeletionTimestamp.IsZero() {
		return ctrl.Result{}, nil
	}

	deployment, err := r.reconcileDeployment(ctx, obj)
	if err == nil {
		err = r.reconcileService(ctx, obj)
	}
	if err != nil {
		if apierrors.IsConflict(err) {
			// Another writer changed the object; the next attempt reads it again.
			return ctrl.Result{RequeueAfter: time.Second}, nil
		}
		log.Error(err, "Failed to reconcile the workload")
		r.event(obj, corev1.EventTypeWarning, "ReconcileFailed", err.Error())
		meta.SetStatusCondition(&obj.Status.Conditions, metav1.Condition{
			Type:               ${{ values.group }}${{ values.version }}.ConditionDegraded,
			Status:             metav1.ConditionTrue,
			Reason:             "ReconcileFailed",
			Message:            err.Error(),
			ObservedGeneration: obj.Generation,
		})
		if statusErr := r.Status().Update(ctx, obj); statusErr != nil && !apierrors.IsConflict(statusErr) {
			log.Error(statusErr, "Failed to record the failure in the status")
		}
		return ctrl.Result{}, err
	}

	r.setStatus(obj, deployment)
	if err := r.Status().Update(ctx, obj); err != nil {
		if apierrors.IsConflict(err) {
			return ctrl.Result{RequeueAfter: time.Second}, nil
		}
		return ctrl.Result{}, err
	}
	return ctrl.Result{}, nil
}

// reconcileDeployment creates the Deployment of obj or brings it in line with the spec.
func (r *${{ values.kind }}Reconciler) reconcileDeployment(
	ctx context.Context, obj *${{ values.group }}${{ values.version }}.${{ values.kind }},
) (*appsv1.Deployment, error) {
	deployment := &appsv1.Deployment{Name: obj.Name, Namespace: obj.Namespace}
	result, err := controllerutil.CreateOrUpdate(ctx, r.Client, deployment, func() error {
		labels := labelsFor(obj)
		deployment.Labels = labels
		deployment.Spec.Replicas = new(ptr.Deref(obj.Spec.Replicas, 1))
		// The selector of a Deployment cannot be changed once it exists.
		if deployment.CreationTimestamp.IsZero() {
			deployment.Spec.Selector = &metav1.LabelSelector{MatchLabels: selectorFor(obj)}
		}
		deployment.Spec.Template.Labels = labels

		pod := &deployment.Spec.Template.Spec
		pod.SecurityContext = &corev1.PodSecurityContext{
			RunAsNonRoot:   new(true),
			SeccompProfile: &corev1.SeccompProfile{Type: corev1.SeccompProfileTypeRuntimeDefault},
		}
		if len(pod.Containers) != 1 {
			pod.Containers = []corev1.Container{{}}
		}
		container := &pod.Containers[0]
		container.Name = containerName
		container.Image = obj.Spec.Image
		container.Resources = obj.Spec.Resources
		container.SecurityContext = &corev1.SecurityContext{
			AllowPrivilegeEscalation: new(false),
			ReadOnlyRootFilesystem:   new(true),
			Capabilities:             &corev1.Capabilities{Drop: []corev1.Capability{"ALL"}},
		}
		container.Ports = nil
		if obj.Spec.Port != nil {
			container.Ports = []corev1.ContainerPort{{
				Name:          portName,
				ContainerPort: *obj.Spec.Port,
				Protocol:      corev1.ProtocolTCP,
			}}
		}
		return controllerutil.SetControllerReference(obj, deployment, r.Scheme)
	})
	if err != nil {
		return nil, fmt.Errorf("deployment %s: %w", deployment.Name, err)
	}
	if result != controllerutil.OperationResultNone {
		r.event(obj, corev1.EventTypeNormal, "DeploymentReconciled", fmt.Sprintf("Deployment %s %s", deployment.Name, result))
	}
	return deployment, nil
}

// reconcileService creates or updates the Service of obj when spec.port is
// set, and removes the Service when it is not.
func (r *${{ values.kind }}Reconciler) reconcileService(ctx context.Context, obj *${{ values.group }}${{ values.version }}.${{ values.kind }}) error {
	service := &corev1.Service{Name: obj.Name, Namespace: obj.Namespace}
	if obj.Spec.Port == nil {
		if err := r.Get(ctx, client.ObjectKeyFromObject(service), service); err != nil {
			return client.IgnoreNotFound(err)
		}
		// Only a Service this controller created is removed.
		if !metav1.IsControlledBy(service, obj) {
			return nil
		}
		return client.IgnoreNotFound(r.Delete(ctx, service))
	}

	result, err := controllerutil.CreateOrUpdate(ctx, r.Client, service, func() error {
		service.Labels = labelsFor(obj)
		service.Spec.Type = corev1.ServiceTypeClusterIP
		service.Spec.Selector = selectorFor(obj)
		service.Spec.Ports = []corev1.ServicePort{{
			Name:       portName,
			Port:       *obj.Spec.Port,
			TargetPort: intstr.FromString(portName),
			Protocol:   corev1.ProtocolTCP,
		}}
		return controllerutil.SetControllerReference(obj, service, r.Scheme)
	})
	if err != nil {
		return fmt.Errorf("service %s: %w", service.Name, err)
	}
	if result != controllerutil.OperationResultNone {
		r.event(obj, corev1.EventTypeNormal, "ServiceReconciled", fmt.Sprintf("Service %s %s", service.Name, result))
	}
	return nil
}

// setStatus derives the status of obj from its Deployment.
func (r *${{ values.kind }}Reconciler) setStatus(obj *${{ values.group }}${{ values.version }}.${{ values.kind }}, deployment *appsv1.Deployment) {
	desired := ptr.Deref(obj.Spec.Replicas, 1)
	ready := deployment.Status.ReadyReplicas
	// The Deployment controller may not have seen the latest change yet.
	current := deployment.Status.ObservedGeneration >= deployment.Generation
	available := current && ready == desired && deployment.Status.UpdatedReplicas == desired

	obj.Status.ObservedGeneration = obj.Generation
	obj.Status.ReadyReplicas = ready

	availableCondition := metav1.Condition{
		Type:               ${{ values.group }}${{ values.version }}.ConditionAvailable,
		Status:             metav1.ConditionFalse,
		Reason:             "ReplicasNotReady",
		Message:            fmt.Sprintf("%d of %d replicas are ready", ready, desired),
		ObservedGeneration: obj.Generation,
	}
	progressingCondition := metav1.Condition{
		Type:               ${{ values.group }}${{ values.version }}.ConditionProgressing,
		Status:             metav1.ConditionTrue,
		Reason:             "RollingOut",
		Message:            "The Deployment is rolling out",
		ObservedGeneration: obj.Generation,
	}
	if available {
		availableCondition.Status = metav1.ConditionTrue
		availableCondition.Reason = "ReplicasReady"
		progressingCondition.Status = metav1.ConditionFalse
		progressingCondition.Reason = "RolloutComplete"
		progressingCondition.Message = "The Deployment matches the spec"
	}
	meta.SetStatusCondition(&obj.Status.Conditions, availableCondition)
	meta.SetStatusCondition(&obj.Status.Conditions, progressingCondition)
	meta.SetStatusCondition(&obj.Status.Conditions, metav1.Condition{
		Type:               ${{ values.group }}${{ values.version }}.ConditionDegraded,
		Status:             metav1.ConditionFalse,
		Reason:             "Reconciled",
		Message:            "The workload was reconciled",
		ObservedGeneration: obj.Generation,
	})
}

func (r *${{ values.kind }}Reconciler) event(obj *${{ values.group }}${{ values.version }}.${{ values.kind }}, eventType, reason, message string) {
	if r.Recorder != nil {
		r.Recorder.Eventf(obj, nil, eventType, reason, "Reconcile", "%s", message)
	}
}

// selectorFor returns the labels that select the pods of obj. They never change.
func selectorFor(obj *${{ values.group }}${{ values.version }}.${{ values.kind }}) map[string]string {
	return map[string]string{
		"app.kubernetes.io/name":     "${{ values.kind_lower }}",
		"app.kubernetes.io/instance": obj.Name,
	}
}

// labelsFor returns the labels set on everything created for obj.
func labelsFor(obj *${{ values.group }}${{ values.version }}.${{ values.kind }}) map[string]string {
	labels := selectorFor(obj)
	labels["app.kubernetes.io/managed-by"] = managedBy
	return labels
}

// SetupWithManager sets up the controller with the Manager.
func (r *${{ values.kind }}Reconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&${{ values.group }}${{ values.version }}.${{ values.kind }}{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Named("${{ values.kind_lower }}").
		Complete(r)
}

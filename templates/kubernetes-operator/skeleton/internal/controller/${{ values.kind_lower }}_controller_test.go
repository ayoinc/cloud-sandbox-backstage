package controller

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/utils/ptr"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	${{ values.group }}${{ values.version }} "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/api/${{ values.version }}"
)

var _ = Describe("${{ values.kind }} Controller", func() {
	const (
		resourceName      = "test-resource"
		resourceNamespace = "default"
		image             = "registry.k8s.io/pause:3.10"
	)
	key := types.NamespacedName{Name: resourceName, Namespace: resourceNamespace}

	reconcileOnce := func() {
		GinkgoHelper()
		reconciler := &${{ values.kind }}Reconciler{Client: k8sClient, Scheme: k8sClient.Scheme()}
		_, err := reconciler.Reconcile(ctx, reconcile.Request{NamespacedName: key})
		Expect(err).NotTo(HaveOccurred())
	}

	BeforeEach(func() {
		resource := &${{ values.group }}${{ values.version }}.${{ values.kind }}{
			Name:      resourceName,
			Namespace: resourceNamespace,
			Spec: ${{ values.group }}${{ values.version }}.${{ values.kind }}Spec{
				Image:    image,
				Replicas: ptr.To[int32](2),
				Port:     ptr.To[int32](8080),
			},
		}
		Expect(k8sClient.Create(ctx, resource)).To(Succeed())
	})

	AfterEach(func() {
		// envtest runs no garbage collector, so owned objects are removed here.
		resource := &${{ values.group }}${{ values.version }}.${{ values.kind }}{}
		Expect(k8sClient.Get(ctx, key, resource)).To(Succeed())
		Expect(k8sClient.Delete(ctx, resource)).To(Succeed())
		objectMeta := metav1.ObjectMeta{Name: resourceName, Namespace: resourceNamespace}
		Expect(k8sClient.Delete(ctx, &appsv1.Deployment{ObjectMeta: objectMeta})).
			To(Or(Succeed(), WithTransform(apierrors.IsNotFound, BeTrue())))
		Expect(k8sClient.Delete(ctx, &corev1.Service{ObjectMeta: objectMeta})).
			To(Or(Succeed(), WithTransform(apierrors.IsNotFound, BeTrue())))
	})

	It("creates a hardened Deployment owned by the resource", func() {
		reconcileOnce()

		deployment := &appsv1.Deployment{}
		Expect(k8sClient.Get(ctx, key, deployment)).To(Succeed())
		Expect(deployment.Spec.Replicas).To(HaveValue(Equal(int32(2))))
		Expect(metav1.GetControllerOf(deployment)).To(HaveField("Kind", "${{ values.kind }}"))

		containers := deployment.Spec.Template.Spec.Containers
		Expect(containers).To(HaveLen(1))
		Expect(containers[0].Image).To(Equal(image))
		Expect(containers[0].Ports).To(ConsistOf(HaveField("ContainerPort", int32(8080))))
		Expect(containers[0].SecurityContext.AllowPrivilegeEscalation).To(HaveValue(BeFalse()))
		Expect(containers[0].SecurityContext.ReadOnlyRootFilesystem).To(HaveValue(BeTrue()))
		Expect(deployment.Spec.Template.Spec.SecurityContext.RunAsNonRoot).To(HaveValue(BeTrue()))
	})

	It("creates a Service for the port and removes it when the port is unset", func() {
		reconcileOnce()

		service := &corev1.Service{}
		Expect(k8sClient.Get(ctx, key, service)).To(Succeed())
		Expect(service.Spec.Ports).To(ConsistOf(HaveField("Port", int32(8080))))
		Expect(service.Spec.Selector).To(HaveKeyWithValue("app.kubernetes.io/instance", resourceName))

		resource := &${{ values.group }}${{ values.version }}.${{ values.kind }}{}
		Expect(k8sClient.Get(ctx, key, resource)).To(Succeed())
		resource.Spec.Port = nil
		Expect(k8sClient.Update(ctx, resource)).To(Succeed())
		reconcileOnce()

		err := k8sClient.Get(ctx, key, service)
		Expect(apierrors.IsNotFound(err)).To(BeTrue(), "the Service should be deleted")
	})

	It("applies spec changes to the Deployment", func() {
		reconcileOnce()

		resource := &${{ values.group }}${{ values.version }}.${{ values.kind }}{}
		Expect(k8sClient.Get(ctx, key, resource)).To(Succeed())
		resource.Spec.Replicas = ptr.To[int32](3)
		Expect(k8sClient.Update(ctx, resource)).To(Succeed())
		reconcileOnce()

		deployment := &appsv1.Deployment{}
		Expect(k8sClient.Get(ctx, key, deployment)).To(Succeed())
		Expect(deployment.Spec.Replicas).To(HaveValue(Equal(int32(3))))
	})

	It("reports progress until the replicas are ready, then availability", func() {
		reconcileOnce()

		resource := &${{ values.group }}${{ values.version }}.${{ values.kind }}{}
		Expect(k8sClient.Get(ctx, key, resource)).To(Succeed())
		Expect(resource.Status.ObservedGeneration).To(Equal(resource.Generation))
		Expect(meta.IsStatusConditionFalse(resource.Status.Conditions, ${{ values.group }}${{ values.version }}.ConditionAvailable)).To(BeTrue())
		Expect(meta.IsStatusConditionTrue(resource.Status.Conditions, ${{ values.group }}${{ values.version }}.ConditionProgressing)).To(BeTrue())

		// envtest runs no Deployment controller: its status is written by hand.
		deployment := &appsv1.Deployment{}
		Expect(k8sClient.Get(ctx, key, deployment)).To(Succeed())
		deployment.Status.ObservedGeneration = deployment.Generation
		deployment.Status.Replicas = 2
		deployment.Status.UpdatedReplicas = 2
		deployment.Status.ReadyReplicas = 2
		deployment.Status.AvailableReplicas = 2
		Expect(k8sClient.Status().Update(ctx, deployment)).To(Succeed())
		reconcileOnce()

		Expect(k8sClient.Get(ctx, key, resource)).To(Succeed())
		Expect(resource.Status.ReadyReplicas).To(Equal(int32(2)))
		Expect(meta.IsStatusConditionTrue(resource.Status.Conditions, ${{ values.group }}${{ values.version }}.ConditionAvailable)).To(BeTrue())
		Expect(meta.IsStatusConditionFalse(resource.Status.Conditions, ${{ values.group }}${{ values.version }}.ConditionProgressing)).To(BeTrue())
		Expect(meta.IsStatusConditionFalse(resource.Status.Conditions, ${{ values.group }}${{ values.version }}.ConditionDegraded)).To(BeTrue())
	})

	It("rejects a resource without an image", func() {
		invalid := &${{ values.group }}${{ values.version }}.${{ values.kind }}{
			Name:      "invalid",
			Namespace: resourceNamespace,
		}
		err := k8sClient.Create(ctx, invalid)
		Expect(apierrors.IsInvalid(err)).To(BeTrue(), "expected a validation error, got %v", err)
	})

	It("does nothing for a resource that no longer exists", func() {
		reconciler := &${{ values.kind }}Reconciler{Client: k8sClient, Scheme: k8sClient.Scheme()}
		_, err := reconciler.Reconcile(ctx, reconcile.Request{
			Name:      "missing",
			Namespace: resourceNamespace,
		})
		Expect(err).NotTo(HaveOccurred())
	})
})
